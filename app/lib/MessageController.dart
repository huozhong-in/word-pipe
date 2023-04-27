import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dart_openai/openai.dart';
import 'package:wordpipe/MessageModel.dart';
import 'package:wordpipe/sse_client.dart';
import 'package:wordpipe/config.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/prompts/template_vocab.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:developer';

enum ButtonState { paused, playing, loading }

class MessageController extends GetxController{
  final Controller c = Get.find();

  final messages = <MessageModel>[].obs;
  bool messsage_view_first_build = true;
  int lastSegmentBeginId = 0;

  final ttsJobs = Map<String, String>().obs;
  late AudioPlayer ttsPlayer;
  final whichIsPlaying = "".obs;
  Rx<ButtonState> buttonNotifier = ButtonState.paused.obs;

  
  late final SSEClient sseClient;
  bool sse_connected = false;
  

  // RxBool _isLoading = false.obs;
  // bool get isLoading => _isLoading.value;

  // find  MessageModel by key
  MessageModel findMessageByKey(Key key) {
    return messages.firstWhere((message) => message.key == key);
  }

  // update MessageModel by key
  void updateMessageByKey(Key key, MessageModel message) {
    final index = messages.indexWhere((message) => message.key == key);
    messages[index] = message;
  }

  //update MessageModel' dataList item by key
  void updateMessageDataListByKey(Key key, int index, String value) {
    final message = messages.firstWhere((message) => message.key == key);
    message.dataList[index] = value;
  }
  
  final scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();

    scrollController.addListener(_scrollListener);
    // 文字转语音播放器的控制，根据服务端返回数据播放
    ttsPlayer = AudioPlayer();
    ttsJobs.listen((Map<String, String> jobs) {
      if (jobs.isNotEmpty) {
        // jobs.forEach((key, value) { print('$key: $value'); });
        if (jobs[whichIsPlaying.value] == null) {
          whichIsPlaying.value = '';
          return;
        }else{
          final mp3Url = jobs[whichIsPlaying.value] as String;
          ttsPlayer.setUrl(mp3Url).then((_) {
            ttsPlayer.play();
            ttsPlayer.playerStateStream.listen((playerState) {
              final isPlaying = playerState.playing;
              final processingState = playerState.processingState;
              if (processingState == ProcessingState.loading ||
                  processingState == ProcessingState.buffering) {
                buttonNotifier.value = ButtonState.loading;
              } else if (!isPlaying) {
                buttonNotifier.value = ButtonState.paused;
              } else if (processingState != ProcessingState.completed) {
                buttonNotifier.value = ButtonState.playing;
              } else {
                ttsPlayer.seek(Duration.zero);
                ttsPlayer.pause();
                whichIsPlaying.value = '';
              }
            });
          });
        }
      }
    });
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    sseClient.close();
    ttsPlayer.dispose();
    super.onClose();
  }

  Future<void> _scrollListener() async {
    // 监听滚动条是否滚动到顶部，从而请求数据库加载更旧的消息
    if (scrollController.offset == scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange) {
        // _isLoading.value = true;
        String curr_user = "";
        Map<String, dynamic> sessionData = await c.getSessionData();
        if (sessionData.containsKey('error') == false)
          curr_user = sessionData['username'] as String;
        
        if (curr_user != ""){
          chatHistory(curr_user, lastSegmentBeginId);
        }
    }
  }


  Future<int> chatHistory(String username, int last_id) async {
    ChatRecord chatRecord = ChatRecord();
    messsage_view_first_build = false;
    // 如果已经是数据库最旧的消息了，就不再请求数据库
    if (lastSegmentBeginId == -1)
      return -1;
    lastSegmentBeginId = await chatRecord.chatHistory(username, last_id);
    // print(lastSegmentBeginId);
    return lastSegmentBeginId;
  }

  Key addMessage(MessageModel message) {
    // 插消息到ListView最底部
    messages.insert(0, message);
    return message.key;
  }

  Future<void> getChatCompletion(String model, String prompt, int requestType) async {
    String curr_user = "";
    String access_token = "";
    String apiKey = "";
    String baseUrl = "";
    Map<String, dynamic> sessionData = await c.getSessionData();
    if (sessionData.containsKey('error') == false){
      curr_user = sessionData['username'] as String;
      access_token = sessionData['access_token'] as String;
      apiKey = sessionData['apiKey'] as String;
      baseUrl = sessionData['baseUrl'] as String;
    }else{
      return;
    }
    if (curr_user == ""){
      return;
    }
    if (access_token == ""){
      return;
    }
    if (apiKey == ""){
      return;
    }
    if (baseUrl == ""){
      return;
    }

    Key needUpdate = addMessage(MessageModel(
      dataList: RxList(['...']),
      type: requestType,
      username: "Jasmine",
      uuid: "b811abd7-c0bb-4301-9664-574d0d8b11f8",
      createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      key: UniqueKey(),
    ));
    
    OpenAI.apiKey = apiKey;
    OpenAI.baseUrl = baseUrl;
    List<OpenAIChatCompletionChoiceMessageModel> msg;
    double temperature = 0;
    prompt = prompt.trim();
    if (requestType == WordPipeMessageType.reply_for_query_word){
      msg = prompt_template_word(prompt);
      temperature = 0.2;
    }else if(requestType == WordPipeMessageType.reply_for_query_word_example_sentence){
      msg = prompt_template_word_example_sentence(prompt);
      temperature = 0.8;
    }else if(requestType == WordPipeMessageType.reply_for_translate_sentence){
      msg = prompt_template_translate_sentence(prompt);
      temperature = 0.5;
    }else if(requestType == WordPipeMessageType.reply_for_answer_question){
      msg = prompt_template_answer_question(prompt);
      temperature = 0.5;
    }else if(requestType == WordPipeMessageType.reply_for_translate_sentence_zh_en){
      msg = prompt_template_translate_sentence_zh_en(prompt);
      temperature = 0.5;
    }else{
      return;
    }
    Stream<OpenAIStreamChatCompletionModel> chatStream = OpenAI.instance.chat.createStream(
      model: model,
      messages: msg,
      user: curr_user,
      temperature: temperature,
    );

    List<String> collected_messages = [];
    String lastPackage = "";
    String answer = "";
    chatStream.listen((chatStreamEvent) {
      // print(chatStreamEvent);
      OpenAIStreamChatCompletionChoiceModel choice = chatStreamEvent.choices[0];
      final content = choice.delta.content;
      if(content != null){
        print(content);
        final message = findMessageByKey(needUpdate);
        if (message.dataList[0] == '...'){
          message.dataList.removeAt(0);
        }

        // 截留最后的答案，给“单词生成例句”功能使用
        if (lastPackage == '>>>'){
          answer = content.trim();
        }else{
          collected_messages.add(content);
          message.dataList.add(content);
          lastPackage = content;
        }
      }
      if (choice.finishReason != null && choice.finishReason == 'stop'){
          // 通过以下方法重整流式消息为按行分割的字符串列表
          String joined_messages = collected_messages.join('');
          List<String> split_messages = joined_messages.split('\n');
          split_messages = split_messages.map((e) => e + '\n').toList();
          
          // 重新画ListView的指定item，解决屏幕会闪一下的问题
          final message = findMessageByKey(needUpdate);
          message.dataList.insert(0, "...");
          message.dataList.removeRange(1, message.dataList.length);
          message.dataList.addAll(split_messages);
          message.dataList.removeAt(0);
          
          // 对于流式消息，通过往消息的最后位置插入一个关键字'[W0RDP1PE]$answer'的方式，把正确答案往后传递
          if (requestType == WordPipeMessageType.reply_for_query_word_example_sentence){
            message.dataList.add('[W0RDP1PE]$answer');
          }
        }
    });
  }

  void handleSSE(String channel) async {
    try {
      sseClient = SSEClient.getInstance(Uri.parse(SSE_SERVER_HOST + SSE_SERVER_PATH), SSE_MSG_TYPE, channel);
      if (sse_connected == false){
        sseClient.messages.listen((message) {
          log('from SSE Server: $message');
          try {
            Map<String, dynamic> json = Map<String, dynamic>.from(jsonDecode(message));
            int type = json['type'];
            if (type == WordPipeMessageType.tts_audio){
              // print(HTTP_SERVER_HOST + json['mp3_url']);
              ttsJobs[json['key']] = HTTP_SERVER_HOST + json['mp3_url'];
            }else{
              messages.insert(0, MessageModel.fromJson(json));
            }
            sse_connected = true;
          } catch (e) {
            log('sse message error: $e');
            // sse_connected = false;
          }
        });  
      }
    } catch (e) {
      log('handleSSE error: $e');
      sse_connected = false;
    }
  }

  // 关闭 SSE 连接，以便可以重新订阅其他频道
  void closeSSE(){
    try{
      sseClient.close();
    } catch (e) {
      log('closeSSE error: $e');
    }
  }

  void addToTTSJobs(String key, String text){
    // 请求服务器端生成TTS语音
    if (ttsJobs[key] == null){
      final ttsAudio = TTSAudio();
      ttsAudio.query_for_tts(key, text).then((value) {
        if (value == true){
          // print('ttsJobs send to server: $key');
        }
      });
    }else{
      // 重新加一次，以便激活ttsJobs.listen()，即可重新播放
      String mp3_url = ttsJobs[key] as String;
      // print(mp3_url + " exists");
      ttsJobs[key] = mp3_url;
    }
  }

  // Future<String> convertspeechToText (String filepath) async {
  // const apiKey = apisecretkey:
  // var url = Uri.https("'api.openai.com”, “v1/audio/transcriptions"):
  // var request = http.MultipartRequest(’PoST', url):
  // request.headers.addAl1(( ("Authorizat ion": "Bearer $apikey"}));
  // request. fields ["model"] = 'whisper-1';
  // request. fields ["language"] ="en";
  // request . fites.add(await http.MultipartFile. fromPath("file' , filepath));
  // var response = await request. send();
  // var newresponse = await http.Response. fromstream (response);
  // final responseData = json.decode (newresponse.body)：
  // print ( responseData);
  // return responseData['text'];}
}

class TTSAudio extends GetConnect {
  final Controller c = Get.find();
  final settingsController = Get.find<SettingsController>();
  
  @override
  void onInit() {
    
  }

  Future<bool> query_for_tts(String key, String text) async {
    bool ret = false;
    Uri url = Uri.parse('$HTTP_SERVER_HOST/tts');
    Map data = {};
    data['key'] = key;
    data['text'] = text;
    // 如果是纯英文字符串，则用外国人语音，否则用中国人语音
    if (isEnglishAndSymbols(text)){
      data['voice'] = settingsController.aiAssistantTtsVoice.value;
    }else{
      data['voice'] = settingsController.aiAssistantTtsVoiceZhEn.value;
    }
    data['rate'] = settingsController.aiAssistantTtsRate.value;
    String curr_user = "";
    String  access_token = "";
    Map<String, dynamic> sessionData = await c.getSessionData();
    if (sessionData.containsKey('error') == false){
        curr_user = sessionData['username'] as String;
        access_token = sessionData['access_token'] as String;
    }else
        return ret;
    
    Map<String,String> hs = {};
    hs['X-access-token'] = access_token;
    data['username'] = curr_user;
    final response = await post(url.toString(), data, headers: hs, contentType: 'application/json');
    if (response.statusCode == 200) {
      ret = true;
    }
    return ret;
  }

  bool isEnglishAndSymbols(String text) {
  for (int i = 0; i < text.length; i++) {
    int codeUnit = text.codeUnitAt(i);
    if (!((codeUnit >= 32 && codeUnit <= 126) || (codeUnit >= 9 && codeUnit <= 13) || codeUnit == 133)) {
      return false;
    }
  }
  return true;
}
}
class ChatRecord extends GetConnect {
  final Controller c = Get.find();
  
  @override
  void onInit() {
    
  }

  Future<int> chatHistory(String username, int last_id) async {
    int ret = -1;
    Uri url = Uri.parse('$HTTP_SERVER_HOST/user/chat-history');
    Map data = {};
    data['username'] = username;
    data['last_id'] = last_id;
    String  access_token = "";
    Map<String, dynamic> sessionData = await c.getSessionData();
    if (sessionData.containsKey('error') == false)
        access_token = sessionData['access_token'] as String;
    
    Map<String,String> hs = {};
    hs['X-access-token'] = access_token;
    final response = await post(url.toString(), data, headers: hs, contentType: 'application/json');
    if (response.statusCode == 200) {
      
      List<dynamic>json = List<dynamic>.from(response.body);
      MessageController messageController = Get.find();
      // messageController._isLoading.value = false;
      json.forEach((element ) {
        Map<String, dynamic> e = element as Map<String, dynamic>;
        ret = e['pk_chat_record'] as int;
        String msgFrom = e['msgFrom'].toString();
        // String msgTo = e['msgTo'].toString();
        String msgFromUUID = e['msgFromUUID'].toString();
        // String msgToUUID = e['msgToUUID'].toString();
        int msgCreateTime = e['msgCreateTime'] as int;
        String msgContent = e['msgContent'].toString();
        // int msgType = e['msgType'].toInt();
        // print("msgFrom:" + msgFrom);
        // print("msgCreatTime:" + msgCreateTime.toString());
        // print("msgContent:" + msgContent);
        // print("msgType:" + msgType.toString());
        messageController.messages.add(
          MessageModel(
            username: msgFrom, 
            uuid: msgFromUUID,
            createTime: msgCreateTime, 
            dataList: RxList([msgContent]), 
            type: WordPipeMessageType.chathistory, 
            key: UniqueKey()
            )
          );
      });

    }
    return ret;
  }
}



// ignore: must_be_immutable
class QuestionButtons extends StatelessWidget {
  final settingsController = Get.find<SettingsController>();
  
  final String answer;
  RxString iconA = 'help_outline'.obs;
  RxString iconB = 'help_outline'.obs;
  RxString iconC = 'help_outline'.obs;
  RxString iconD = 'help_outline'.obs;
  
  QuestionButtons({required this.answer});

  @override
  Widget build(BuildContext context) {
    return Row(

      children: [
        Container(
          margin: EdgeInsetsDirectional.symmetric(horizontal: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              if(answer == 'A') {
                iconA.value = 'check'; 
              } else {
                iconA.value = 'close';
              }
            },
            icon: Obx(() => Icon(
              iconA.value == 'help_outline' ? Icons.help_outline :
              iconA.value == 'check' ? Icons.check : 
              Icons.close,
              color: Colors.blue[900],
            )),
            label: Text('A', style: TextStyle(fontSize: settingsController.fontSizeConfig.value, color: Colors.blue[900]),)   
          ),
        ),
        Container(
          margin: EdgeInsetsDirectional.symmetric(horizontal: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              if(answer == 'B') {
                iconB.value = 'check'; 
              } else {
                iconB.value = 'close';
              }
            },
            icon: Obx(() => Icon(
              iconB.value == 'help_outline' ? Icons.help_outline :
              iconB.value == 'check' ? Icons.check : 
              Icons.close,
              color: Colors.blue[900],
            )),
            label: Text('B', style: TextStyle(fontSize: settingsController.fontSizeConfig.value, color: Colors.blue[900]),)   
          ),
        ),
        Container(
          margin: EdgeInsetsDirectional.symmetric(horizontal: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              if(answer == 'C') {
                iconC.value = 'check'; 
              } else {
                iconC.value = 'close';
              }
            },
            icon: Obx(() => Icon(
              iconC.value == 'help_outline' ? Icons.help_outline :
              iconC.value == 'check' ? Icons.check : 
              Icons.close,
              color: Colors.blue[900],
            )),
            label: Text('C', style: TextStyle(fontSize: settingsController.fontSizeConfig.value, color: Colors.blue[900]),)   
          ),
        ),
        Container(
          margin: EdgeInsetsDirectional.symmetric(horizontal: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              if(answer == 'D') {
                iconD.value = 'check'; 
              } else {
                iconD.value = 'close';
              }
            },
            icon: Obx(() => Icon(
              iconD.value == 'help_outline' ? Icons.help_outline :
              iconD.value == 'check' ? Icons.check : 
              Icons.close,
              color: Colors.blue[900],
            )),
            label: Text('D', style: TextStyle(fontSize: settingsController.fontSizeConfig.value, color: Colors.blue[900]),)   
          ),
        )
      ],
    );
  }
}
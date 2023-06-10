import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:wordpipe/MessageModel.dart';
import 'package:wordpipe/responsive/responsive_layout.dart';
import 'package:wordpipe/sse_client.dart';
import 'package:wordpipe/config.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/prompts/template_vocab.dart';
import 'package:wordpipe/prompts/template_freechat.dart';
import 'package:wordpipe/custom_widgets.dart';
import 'package:flutter_desktop_audio_recorder/flutter_desktop_audio_recorder.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:developer';

enum ButtonState { paused, playing, loading }

class MessageController extends GetxController{
  final Controller c = Get.find();

  final messages = <MessageModel>[].obs;
  bool messsage_view_first_build = true;
  FocusNode commentFocus = FocusNode();
  int lastSegmentBeginId = 0;
  RxInt conversation_id = 0.obs;
  RxList<Widget> radioListTiles = RxList<Widget>();
  Map<int, String> conversationNameMap = {};
  RxString selectedConversationName = ''.obs;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final ttsJobs = Map<String, String>().obs;
  late AudioPlayer voicePlayer;
  final whichIsPlaying = "".obs;
  Rx<ButtonState> buttonNotifier = ButtonState.paused.obs;

  
  late SSEClient sseClient;
  bool sse_connected = false;
  

  // RxBool _isLoading = false.obs;
  // bool get isLoading => _isLoading.value;

  // find  MessageModel by key
  MessageModel findMessageByKey(String key) {
    // type为 WordPipeMessageType.reserved 表示没有找到
    // print("findMessageByKey(): " + key);
    return messages.firstWhere((message) => message.key.toString() == key, orElse: () => MessageModel(
      username: '',
      uuid: '',
      dataList: RxList([]),
      type: WordPipeMessageType.reserved,
      createTime: 0,
      key: UniqueKey(),
      isSent: true,
    ));
  }
  
  final scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();

    scrollController.addListener(_scrollListener);

    // 文字转语音播放器的控制，根据服务端返回数据播放
    voicePlayer = AudioPlayer();
    ttsJobs.listen((Map<String, String> jobs) {
      if (jobs.isNotEmpty) {
        // jobs.forEach((key, value) { print('$key: $value'); });
        if (jobs[whichIsPlaying.value] == null) {
          whichIsPlaying.value = '';
          return;
        }else{
          final mp3Url = jobs[whichIsPlaying.value] as String;
          voicePlayer.setUrl(mp3Url).then((_) {
            voicePlayer.play();
            _setPlayerListener();
          });
        }
      }
    });
  }

  void playVoice(String keyString, String filePath, bool purgePlayed) async {
    if (voicePlayer.playerState.playing){
      await voicePlayer.pause();
    }
    whichIsPlaying.value = keyString;                            
    // print("playVoice(): $filePath");
    // 判断filePath是本地路径还是url
    if (filePath.startsWith('http')) {
      voicePlayer.setUrl(filePath).then((duration) {
        // print(duration);
        voicePlayer.play().then((_) {
          // print("playVoice(): 播放结束");
        });
        _setPlayerListener(purgePlayed: purgePlayed);
      });
    } else {
      voicePlayer.setFilePath(filePath).then((duration) {
        // print(duration);
        voicePlayer.play().then((_) {
          // print("playVoice(): 播放结束");
        });
        _setPlayerListener(purgePlayed: purgePlayed);
      });
    }
  }

  void _setPlayerListener({bool purgePlayed=true}){
    voicePlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
        buttonNotifier.value = ButtonState.loading;
      } else if (!isPlaying) {
        buttonNotifier.value = ButtonState.paused;
      } else if (processingState != ProcessingState.completed) {
        buttonNotifier.value = ButtonState.playing;
      } else {
        voicePlayer.seek(Duration.zero);
        voicePlayer.pause();
        if(purgePlayed){
          // print("set whichIsPlaying.value = ''");
          whichIsPlaying.value = '';
        }
      }
    });
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    try{      
      sseClient.close();
    } catch (e) {
      print("onClose():" + e.toString());
    }
    voicePlayer.dispose();
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
          await chatHistory(curr_user, lastSegmentBeginId);
        }
    }
  }


  Future<int> chatHistory(String username, int last_id) async {
    ChatRecord chatRecord = ChatRecord();
    // 通过这个标志位实现只有第一次打开页面时才有欢迎词
    messsage_view_first_build = false;
    // 如果已经是数据库最旧的消息了，就不再请求数据库
    if (lastSegmentBeginId == -1){
      return -1;
    }
    // 如果是点击了free-chat按钮或者新话题按钮，则创建新会话，不需要加载历史记录
    final SettingsController settingsController = Get.find();
    if (settingsController.freeChatMode.value == true && conversation_id.value == 0)
      conversation_id.value = -1;
    if (conversation_id.value <= -1) // 当是-2时也会返回（+新话题按钮处设置的）
      return -1;
    lastSegmentBeginId = await chatRecord.chatHistory(username, last_id, conversation_id.value);
    if(lastSegmentBeginId == -2){
      await c.signout();
      Get.offAll(() => ResponsiveLayout());
    }
    // update();
    return lastSegmentBeginId;
  }

  Future<int> conversation_CUD(String username, String actionType, int conversation_id, {String conversation_name=''}) async {
    ChatRecord chatRecord = ChatRecord();
    int result = 0;
    if (conversation_name == ''){
      result = await chatRecord.conversation_CUD(username, actionType, conversation_id);
    }else{
      result = await chatRecord.conversation_CUD(username, actionType, conversation_id, conversation_name: conversation_name);
    }
    if(result == 0){
      await c.signout();
      Get.offAll(() => ResponsiveLayout());
    }
    return result;
  }

  Future<List<dynamic>> conversation_R(String username) async {
    ChatRecord chatRecord = ChatRecord();
    List<dynamic> result = await chatRecord.conversation_R(username);
    return result;
  }

  String addMessage(MessageModel message) {
    // 插消息到ListView最底部
    messages.insert(0, message);
    return message.key.toString();
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

    String needUpdate = addMessage(MessageModel(
      dataList: RxList(['...']),
      type: requestType,
      username: "Jasmine",
      uuid: "b811abd7-c0bb-4301-9664-574d0d8b11f8",
      createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      key: UniqueKey(),
      isSent: false,
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
        // print(content);
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

  void freeChat(String model, int c_id, String prompt) async {
    
    String curr_user = "";
    String access_token = "";
    String apiKey = "";
    String baseUrl = "";
    int premium = 0;
    Map<String, dynamic> sessionData = await c.getSessionData();
    if (sessionData.containsKey('error') == false){
      curr_user = sessionData['username'] as String;
      access_token = sessionData['access_token'] as String;
      apiKey = sessionData['apiKey'] as String;
      baseUrl = sessionData['baseUrl'] as String;
      premium = sessionData['premium'] as int;
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

    String needUpdate = addMessage(MessageModel(
      dataList: RxList(['...']),
      type: WordPipeMessageType.raw_text,
      username: "Jasmine",
      uuid: "b811abd7-c0bb-4301-9664-574d0d8b11f8",
      createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      key: UniqueKey(),
      isSent: false,
    ));
    
    // 使用用户自己的OpenAI API key
    final SettingsController settingsController = Get.find();
    if (premium == 0 && settingsController.openAiApiKey.value != ""){
        apiKey = settingsController.openAiApiKey.value;
    }
    OpenAI.apiKey = apiKey;
    OpenAI.baseUrl = baseUrl;
    List<OpenAIChatCompletionChoiceMessageModel> msg;
    double temperature = 0;
    msg = prompt_template_freechat(prompt.trim());
    temperature = 0.2;
    // 拼接发回给服务端，以便保存AI的回复到聊天记录表
    Stream<OpenAIStreamChatCompletionModel> chatStream = OpenAI.instance.chat.createStream(
      model: model,
      messages: msg,
      user: c_id.toString() + "[FREECHAT]" + curr_user,
      temperature: temperature,
    );
    // TODO 如果返回错误说明用户提供的key无效，需要提示用户
    chatStream.listen((chatStreamEvent) {
      // print(chatStreamEvent);
      OpenAIStreamChatCompletionChoiceModel choice = chatStreamEvent.choices[0];
      final content = choice.delta.content;
      if(content != null){
        // print(content);
        final message = findMessageByKey(needUpdate);
        if (message.dataList[0] == '...'){
          message.dataList.removeAt(0);
        }
        message.dataList.add(content);
      }
      if (choice.finishReason != null && choice.finishReason == 'stop'){
        // 自动给新话题命名
        if (messages.length == 3 || messages.length == 2){
          name_a_conversation(curr_user, c_id, messages[1].dataList.join(''), messages[0].dataList.join(''), apiKey);
        }
      }
    });
  }
  Future<Map<String, dynamic>> chat(String username, String message, int conversation_id) async{
    String myuuid = await c.getUUID();
    String needUpdate = addMessage(MessageModel(
      dataList: RxList([message]),
      type: WordPipeMessageType.raw_text,
      username: username,
      uuid: myuuid,
      createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      key: UniqueKey(),
      isSent: false,
    ));
    return await c.chat(username, message, conversation_id, needUpdate);
  }
  Future<Map<String, dynamic>> voiceChat(String username, String message, String fileName, int conversation_id) async{
    String myuuid = await c.getUUID();
    String needUpdate = addMessage(MessageModel(
      dataList: RxList([message, fileName]),
      type: WordPipeMessageType.audio,
      username: username,
      uuid: myuuid,
      createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      key: UniqueKey(),
      isSent: false,
    ));
    Map<String, dynamic> result = await c.voiceChat(username, message, fileName, needUpdate, conversation_id);
    if (result['errcode'] as int == 0){
      // 语音消息发送成功，更新消息状态，去掉loading效果
      final message = findMessageByKey(needUpdate);
      message.isSent.value = true;
      // 将语音文件的url保存到消息中
      message.dataList.add(result['relative_url'] as String);
    }
    return result;
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
              String message_key = json['message_key'];
              // print("message_key: $message_key");
              if (message_key != ""){
                final message = findMessageByKey(message_key);
                if (message.type == WordPipeMessageType.reserved){
                  // 如果在消息列表中没有找到，则新增
                  addMessage(MessageModel.fromJson(json));
                }else{
                  // 如果在消息列表中找到了，则更新
                  // if (message.dataList[0] == '...'){
                    message.dataList.removeAt(0);
                  // }
                  String content = List<String>.from(json['dataList']).join('');
                  message.dataList.add(content);
                }
              }else{
                addMessage(MessageModel.fromJson(json));
              }
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

  Future<bool> deleteConversation(int c_id ) async {
    String _username = await c.getUserName();
    int new_id = await conversation_CUD(_username, 'delete', c_id);
    if (new_id == c_id){
      conversationNameMap.remove(c_id);
      // 删除成功后，重新生成整个 radioListTiles 列表
      _rebuildRadioListTiles();
      selectedConversationName.value = '';
      messages.clear();
      conversation_id.value = -1;
      return true;
    }
    return false;
  }

  Future<bool> updateConversationName(int conversation_id, String new_name) async {
    String _username = await c.getUserName();
    int c_id = await conversation_CUD(_username, 'update', conversation_id, conversation_name: new_name);
    if (c_id == conversation_id){
      conversationNameMap[conversation_id] = new_name;
      // 更新成功后，重新生成整个 radioListTiles 列表
      _rebuildRadioListTiles();
      selectedConversationName.value = new_name;
      return true;
    }
    return false;
  }

  void _rebuildRadioListTiles() {
    // 将 conversationNameMap 按照 pk_conversation 排序
    var sortedEntries = conversationNameMap.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    // 使用 map 函数生成控件
    var rlt = sortedEntries.map((entry) {
      int pkConversation = entry.key;
      String conversationName = entry.value;
      return customRadioListTile({
        'pk_conversation': pkConversation,
        'conversation_name': conversationName,
      });
    }).toList();
    // 调用 assignAll 方法将生成的控件赋值给 radioListTiles
    radioListTiles.assignAll(rlt);
  }

  Future<void> name_a_conversation(String username, int conversation_id, String Q, String A, String apiKey) async {
    ChatRecord chatRecord = ChatRecord();
    Map<String, dynamic> named = await chatRecord.name_a_conversation(username, conversation_id, Q, A, apiKey);
    if (named.isNotEmpty && named['conversation_name'] != null){
      String c_name = named['conversation_name'] as String;
      if (c_name != ""){
        MessageController messageController = Get.find();
        // “新话题”同步的列表变量中，以便将来重建radioListTiles使用
        messageController.conversationNameMap[conversation_id] = c_name;
        messageController.selectedConversationName.value = c_name;
        _rebuildRadioListTiles();
      }
    }
  }

  Future<String> convertSpeechToText (String filepath) async {
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
    // return responseData['text'];
    // 使用用户自己的OpenAI API key
    String curr_user = "";
    String access_token = "";
    String apiKey = "";
    String baseUrl = "";
    int premium = 0;
    Map<String, dynamic> sessionData = await c.getSessionData();
    if (sessionData.containsKey('error') == false){
      curr_user = sessionData['username'] as String;
      access_token = sessionData['access_token'] as String;
      apiKey = sessionData['apiKey'] as String;
      baseUrl = sessionData['baseUrl'] as String;
      premium = sessionData['premium'] as int;
    }else{
      return "";
    }
    if (curr_user == ""){
      return "";
    }
    if (access_token == ""){
      return "";
    }
    if (apiKey == ""){
      return "";
    }
    if (baseUrl == ""){
      return "";
    }
    final SettingsController settingsController = Get.find();
    if (premium == 0 && settingsController.openAiApiKey.value != ""){
      apiKey = settingsController.openAiApiKey.value;
    }
    OpenAI.apiKey = apiKey;
    OpenAI.baseUrl = baseUrl;
    Future<OpenAIAudioModel> transcription = OpenAI.instance.audio.createTranscription(
      file: File(filepath),
      model: "whisper-1",
      responseFormat: OpenAIAudioResponseFormat.json,
      // language: 'zh',
    );
    String stt_string = await transcription.then((jsonData) => jsonData.text);
    return stt_string;
  }




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

  @override
  void onClose() {
    
  }

  Future<int> chatHistory(String username, int last_id, int conversation_id) async {
    int ret = -1;
    Uri url = Uri.parse('$HTTP_SERVER_HOST/user/ch');
    Map data = {};
    data['username'] = username;
    data['last_id'] = last_id;
    data['conversation_id'] = conversation_id;
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
        // print("msgFrom:" + msgFrom);
        // String msgTo = e['msgTo'].toString();
        // print("msgTo:" + msgTo);
        String msgFromUUID = e['msgFromUUID'].toString();
        // String msgToUUID = e['msgToUUID'].toString();
        int msgCreateTime = e['msgCreateTime'] as int;
        // print("msgCreatTime:" + msgCreateTime.toString());
        String msgContent = e['msgContent'].toString();
        // print("msgContent:" + msgContent);
        int msgType = e['msgType'] as int;
        // print("msgType:" + msgType.toString());
        // int conversation_id = e['conversation_id'] as int;
        // print("db conversation_id:" + conversation_id.toString());
        final List<dynamic> dataList = [];
        switch (msgType){
          case WordPipeMessageType.audio:
            dataList.add(msgContent);
            dataList.add(e['pk_chat_record']);
            String audio_suffix = FlutterDesktopAudioRecorder().macosFileExtension;
            // intermediate_path是从msgCreateTime(timestamp格式)中提取的年月日, 例如20210101
            int msgCreateTime =  DateTime.now().millisecondsSinceEpoch;
            String intermediate_path = DateTime.fromMillisecondsSinceEpoch(msgCreateTime)
                .toString()
                .substring(0, 10)
                .replaceAll('-', '');
            String relative_url = '/$VOICE_FILE_DIR/$intermediate_path/${e['pk_chat_record']}.$audio_suffix';
            dataList.add(relative_url);
            break;
          default:
            dataList.add(msgContent);
            break;
        }
        messageController.messages.add(
          MessageModel(
            username: msgFrom, 
            uuid: msgFromUUID,
            createTime: msgCreateTime, 
            dataList: RxList(dataList), 
            type: msgType, 
            key: ValueKey(e['pk_chat_record']),
            isSent: true,
            )
          );
      });

    }else{
      ret = -2; // 表示http code 500，access_token无效
    }
    return ret;
  }

  Future<int> conversation_CUD(String username, String actionType, int conversation_id, {String conversation_name=''}) async {
    int ret = 0;
    Uri url = Uri.parse('$HTTP_SERVER_HOST/user/cs');
    
    Map data = {};
    data['username'] = username;
    data['conversation_id'] = conversation_id;
    String  access_token = "";
    Map<String, dynamic> sessionData = await c.getSessionData();
    if (sessionData.containsKey('error') == false)
        access_token = sessionData['access_token'] as String;
    Map<String,String> hs = {};
    hs['X-access-token'] = access_token;

    if (actionType == 'create'){
      final response = await post(url.toString(), data, headers: hs, contentType: 'application/json');
      if (response.statusCode == 200) {
        Map<String, dynamic> json = Map<String, dynamic>.from(response.body);
        ret = json['pk_conversation'] as int;
      }
    }else if (actionType == 'delete'){
      if (conversation_id > 0){
        url = url.replace(
          queryParameters: {
            'username': username,
            'conversation_id': conversation_id.toString()
          }
        );
        final response = await delete(url.toString() , headers: hs, contentType: 'application/json');
        if (response.statusCode == 200) {
          Map<String, dynamic> json = Map<String, dynamic>.from(response.body);
          ret = json['pk_conversation'] as int;
        }
      }
    }else if (actionType == 'update'){
      if (conversation_id > 0){
        data['conversation_name'] = conversation_name;
        final response = await put(url.toString(), data, headers: hs, contentType: 'application/json');
        if (response.statusCode == 200) {
          Map<String, dynamic> json = Map<String, dynamic>.from(response.body);
          ret = json['pk_conversation'] as int;
        }
      }
    }
    return ret;
  }

  Future<List<dynamic>> conversation_R(String username) async {
    // if (await CacheHelper.hasData("cs" + username)) {
    //   if( await CacheHelper.getData("cs" + username) != null)
    //     return await CacheHelper.getData("cs" + username) as List<dynamic>;
    // }
    List<dynamic> ret = [];
    Uri url = Uri.parse('$HTTP_SERVER_HOST/user/cs');

    String  access_token = "";
    Map<String, dynamic> sessionData = await c.getSessionData();
    if (sessionData.containsKey('error') == false)
        access_token = sessionData['access_token'] as String;
    
    Map<String,String> hs = {};
    hs['X-access-token'] = access_token;

    final newUrl = url.replace(
      queryParameters: <String, String>{
        'username': username,
      },
    );
    final response = await get(newUrl.toString(), headers: hs, contentType: 'application/json');
    if (response.statusCode == 200) {
      ret = List<dynamic>.from(response.body);
      // await CacheHelper.setData("cs" + username, ret);
    }
    return ret;
  }

  Future<Map<String, dynamic>> name_a_conversation(String username, int conversation_id, String Q, String A, String apiKey) async {
    Uri url = Uri.parse('$HTTP_SERVER_HOST/nc');
    
    Map data = {};
    data['username'] = username;
    data['conversation_id'] = conversation_id;
    data['q'] = Q;
    data['a'] = A;
    data['api_key'] = apiKey;
    String  access_token = "";
    Map<String, dynamic> sessionData = await c.getSessionData();
    if (sessionData.containsKey('error') == false)
        access_token = sessionData['access_token'] as String;
    Map<String,String> hs = {};
    hs['X-access-token'] = access_token;

    final response = await post(url.toString(), data, headers: hs, contentType: 'application/json');
    if (response.statusCode == 200) {
      Map<String, dynamic> json = Map<String, dynamic>.from(response.body);
      return json;
    }else{
      return {};
    }
  }
}



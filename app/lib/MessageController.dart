import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wordpipe/MessageModel.dart';
import 'package:wordpipe/sse_client.dart';
import 'package:wordpipe/config.dart';
import 'package:dart_openai/openai.dart';
import 'package:wordpipe/controller.dart';
import 'dart:developer';

class MessageController extends GetxController{
  final Controller c = Get.find();

  final messages = <MessageModel>[].obs;
  
  late final SSEClient sseClient;
  bool sse_connected = false;
  
  bool messsage_view_first_build = true;
  int lastSegmentBeginId = 0;

  RxBool _isLoading = false.obs;
  // set setLoading(bool value) => _isLoading.value = value;
  bool get isLoading => _isLoading.value;

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
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    sseClient.close();
    super.onClose();
  }

  Future<void> _scrollListener() async {
    if (scrollController.offset == scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange) {
        _isLoading.value = true;
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
    if (lastSegmentBeginId == -1)
      return -1;
    lastSegmentBeginId = await chatRecord.chatHistory(username, last_id);
    // print(lastSegmentBeginId);
    return lastSegmentBeginId;
  }

  Key addMessage(MessageModel message) {
    messages.insert(0, message);
    return message.key;
  }

  // void updateMessage(MessageModel message, List<dynamic> newDataList) {
  //   if (message.dataList[0] == '...'){
  //     message.dataList.removeAt(0);
  //   }
  //   message.dataList.value = List<String>.from(newDataList);
  //   update();
  // }

  Future<void> getChatCompletion(String model, String prompt) async {
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
      type: WordPipeMessageType.stream,
      username: "Jarvis",
      uuid: "b811abd7-c0bb-4301-9664-574d0d8b11f8",
      createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      key: UniqueKey(),
    ));
    
    OpenAI.apiKey = apiKey;
    OpenAI.baseUrl = baseUrl;
    Stream<OpenAIStreamChatCompletionModel> chatStream = OpenAI.instance.chat.createStream(
      model: "gpt-3.5-turbo",
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: prompt,
          role: OpenAIChatMessageRole.user,
        )
      ],
      user: curr_user,
    );

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
        update();
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
            messages.insert(0, MessageModel.fromJson(json));
            sse_connected = true;
          } catch (e) {
            log('sse message error: $e');
            // sse_connected = false;
          }
        });  
      }
      // 订阅消息流
      
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
      MessageController messageController = Get.find<MessageController>();
      messageController._isLoading.value = false;
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

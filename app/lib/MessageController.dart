import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/MessageModel.dart';
import 'package:app/sse_client.dart';
import 'package:app/cache_helper.dart';
import 'package:app/config.dart';
import 'package:dart_openai/openai.dart';
import 'dart:developer';

class MessageController extends GetxController {
  final messages = <MessageModel>[].obs;
  late String username = "";
  SSEClient? sseClient;
  ChatRecord chatRecord = ChatRecord();

  @override
  void onInit() {
    super.onInit();
    
  }

  int addMessage(MessageModel message) {
    messages.add(message);
    return messages.length - 1;
  }

  void updateMessage(int index, List<dynamic> newDataList) {
    final message = messages[index];
    if (message.dataList[0] == '...'){
      message.dataList.removeAt(0);
    }
    message.dataList.value = List<String>.from(newDataList);
    update();
  }



  Future<void> getChatCompletion(String model, String prompt) async {
    String curr_user = "";
    if (await CacheHelper.hasData('username')){
      if(await CacheHelper.getData('username') != null){
        curr_user = await CacheHelper.getData('username');
      }
    }
    if (curr_user == ""){
      return;
    }

    String access_token = "";
    if (await CacheHelper.hasData('access_token')){
      if(await CacheHelper.getData('access_token') != null){
        access_token = await CacheHelper.getData('access_token');
      }
    }
    if (access_token == ""){
      return;
    }
    
    String apiKey = "";
    if (await CacheHelper.hasData('apiKey')){
      if(await CacheHelper.getData('apiKey') != null){
        apiKey = await CacheHelper.getData('apiKey');
      }
    }
    if (apiKey == ""){
      return;
    }

    String baseUrl = "";
    if (await CacheHelper.hasData('baseUrl')){
      if(await CacheHelper.getData('baseUrl') != null){
        baseUrl = await CacheHelper.getData('baseUrl');
      }
    }
    if (baseUrl == ""){
      return;
    }

    int needUpdate = addMessage(MessageModel(
      dataList: RxList(['...']),
      type: WordPipeMessageType.stream,
      username: "Jarvis",
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
        print(content);
        final message = messages[needUpdate];
        message.dataList.add(content);
        updateMessage(needUpdate, message.dataList);
      }
    });
  }

  void setUsername(String username) {
    this.username = username;
  }
  String getUsername() {
    return this.username;
  }

  void handleSSE(String channel) async {
    try {
      Uri url = Uri.parse(SSE_SERVER_HOST + SSE_SERVER_PATH);
      String eventType = SSE_MSG_TYPE;
      sseClient = SSEClient(url, eventType, channel);

      // 订阅消息流
      sseClient?.messages.listen((message) {
        log('from SSE Server: $message');
        try {
          Map<String, dynamic> json = Map<String, dynamic>.from(jsonDecode(message));
          messages.add(MessageModel.fromJson(json));
        } catch (e) {
          log('sse message error: $e');
        }
      });
    } catch (e) {
      log('handleSSE error: $e');
    }
  }

  // 关闭 SSE 连接，以便可以重新订阅其他频道
  void closeSSE(){
    if (sseClient != null) {
      sseClient?.close();
    }
  }

  
  
}

class ChatRecord extends GetConnect {
  @override
  void onInit() {
    
  }

  Future<void> fetchMessages(String username, int last_id) async {
    // 从 API 获取数据并解析 JSON，此处仅为示例
    // List<Map<String, dynamic>> jsonResponse = [
    //   {"username": "user1", "text": "Text 1", "type": "text"},
    //   {"username": "user2", "text": "Text 2", "type": "link"},
    //   {"username": "user3", "text": "Text 3", "type": "reserved"},
    // ];
    
    Uri url = Uri.parse('$HTTP_SERVER_HOST/api/user/chat-records');
    Map data = {};
    data['username'] = username;
    data['last_id'] = last_id;
    String  access_token = "";
    if (await CacheHelper.hasData('access_token')){
      if(await CacheHelper.getData('access_token') != null){
        access_token = await CacheHelper.getData('access_token');
      }
    }
    Map<String,String> hs = {};
    if (access_token != ""){
      hs['X-access-token'] = access_token;
    }
    final response = await post(url.toString(), data, headers: hs, contentType: 'application/json');
    if (response.statusCode == 200) {
      List<MessageModel> newMessages = response.body.map((json) => MessageModel.fromJson(json)).toList();
      MessageController messageController = Get.find<MessageController>();
      messageController.messages.addAll(newMessages);
    }
  }
}

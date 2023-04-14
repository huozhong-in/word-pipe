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

class MessageController extends GetxController{
  final messages = <MessageModel>[].obs;
  
  late final SSEClient sseClient;
  bool sse_connected = false;
  
  bool messsage_view_first_build = true;
  int lastSegmentBeginId = -1;

  RxBool _isLoading = false.obs;
  // set setLoading(bool value) => _isLoading.value = value;
  bool get isLoading => _isLoading.value;

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
        if (await CacheHelper.hasData('username')){
          if(await CacheHelper.getData('username') != null){
            curr_user = await CacheHelper.getData('username');
          }
        }
        if (curr_user != ""){
          chatHistory(curr_user, lastSegmentBeginId);
        }
    }
  }

  Future<int> chatHistory(String username, int last_id) async {
    ChatRecord chatRecord = ChatRecord();
    messsage_view_first_build = false;
    lastSegmentBeginId = await chatRecord.chatHistory(username, last_id);
    // print(lastSegmentBeginId);
    return lastSegmentBeginId;
  }

  int addMessage(MessageModel message) {
    messages.insert(0, message);
    return 0;
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
      uuid: "Jarvis",
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
        final message = messages[needUpdate];
        message.dataList.add(content);
        updateMessage(needUpdate, message.dataList);
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
    sseClient.close();
  }


}

class ChatRecord extends GetConnect {
  @override
  void onInit() {
    
  }

  Future<int> chatHistory(String username, int last_id) async {
    // 从 API 获取数据并解析 JSON，此处仅为示例
    // List<Map<String, dynamic>> jsonResponse = [
    //   {"username": "user1", "text": "Text 1", "type": "text"},
    //   {"username": "user2", "text": "Text 2", "type": "link"},
    //   {"username": "user3", "text": "Text 3", "type": "reserved"},
    // ];
    int ret = -1;
    Uri url = Uri.parse('$HTTP_SERVER_HOST/user/chat-history');
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

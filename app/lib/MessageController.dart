import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/MessageModel.dart';
import 'package:app/sse_client.dart';
import 'package:http/http.dart' as http;
import 'package:app/cache_helper.dart';
import 'package:app/config.dart';
import 'dart:developer';

class MessageController extends GetxController {
  final messages = <MessageModel>[].obs;
  late String username = DEFAULT_AYONYMOUS_USER_ID;
  late SSEClient sseClient;

  int addMessage(MessageModel message) {
    messages.add(message);
    return messages.length - 1;
  }

  void setUsername(String username) {
    this.username = username;
  }
  String getUsername() {
    return this.username;
  }

  void handleSSE(String channel) async{
    Uri url = Uri.parse(SSE_SERVER_HOST+SSE_SERVER_PATH);
    String eventType = SSE_MSG_TYPE;
    sseClient = SSEClient(url, eventType, channel);
    // 订阅消息流
    sseClient.messages.listen((message) {
      log('from SSE Server: $message');
      try{
        Map<String, dynamic> json = Map<String, dynamic>.from(jsonDecode(message));
        messages.add(MessageModel.fromJson(json));
      }catch(e){
        log('sse message format error: $e');
      }
      
    });
  }

  // 关闭 SSE 连接，以便可以重新订阅其他频道
  void closeSSE(){
    sseClient.close();
  }

  Future<void> fetchMessages() async {
    // 从 API 获取数据并解析 JSON，此处仅为示例
    List<Map<String, dynamic>> jsonResponse = [
      {"username": "user1", "text": "Text 1", "type": "text"},
      {"username": "user2", "text": "Text 2", "type": "link"},
      {"username": "user3", "text": "Text 3", "type": "reserved"},
    ];
    List<MessageModel> newMessages =
        jsonResponse.map((json) => MessageModel.fromJson(json)).toList();
    messages.addAll(newMessages);
  }

  void updateMessage(int index, MessageModel newMessage, {Key? key}) {
    messages[index] = newMessage.copyWith(key: key ?? messages[index].key);
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

    int needUpdate = addMessage(MessageModel(dataList: [''], type: WordPipeMessageType.stream, username: "Jarvis", key: UniqueKey()));

    Uri url = Uri.parse('$HTTP_SERVER_HOST/openai/v1/chat/completions');
    Map<String, dynamic> data = {
      'user': curr_user,
      'model': model,
      'messages': [{'role': 'user', 'content': prompt}]
    };

    Map<String, String> headers = {
      'X-access-token': access_token,
      'Content-Type': 'application/json',
    };

    final request = http.Request('POST', url);
    request.body = json.encode(data);
    request.headers.addAll(headers);

    final streamedResponse = await request.send();
    String all_content = "";
    final transformer = StreamTransformer<String, Map<String, dynamic>>.fromHandlers(
      handleData: (chunk, sink) {
        final trimmedChunk = chunk.trim();
        if (trimmedChunk.isNotEmpty) {
          final lineSplitter = LineSplitter();
          final lines = lineSplitter.convert(trimmedChunk);
          for (final line in lines) {
            final jsonMap = jsonDecode(line) as Map<String, dynamic>;
            sink.add(jsonMap);

            if (jsonMap['choices'][0]['delta'] != {}){
              final delta = jsonMap['choices'][0]['delta'] as Map<String, dynamic>;
              if(delta['content']!=null){
                all_content += delta['content'] as String;
                print(all_content);
                // 将上述临时占位的消息用流式数据替换
                updateMessage(needUpdate, 
                  MessageModel(
                    dataList: [all_content], 
                    type: WordPipeMessageType.stream, 
                    username: "Jarvis",
                    key: UniqueKey()
                  ),
                );
              }
            }

          }
        }
      },
    );

    final stream = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(transformer);
    await for (final map in stream) {
      
    }
  }
}

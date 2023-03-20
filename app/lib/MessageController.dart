import 'dart:convert';
import 'package:get/get.dart';
import 'package:app/MessageModel.dart';
import 'package:app/sse_client.dart';
import 'dart:developer';
import 'package:app/config.dart';

class MessageController extends GetxController {
  final messages = <MessageModel>[].obs;
  late String userId = DEFAULT_AYONYMOUS_USER_ID;

  void addMessage(MessageModel message) {
    messages.add(message);
  }

  void setUserId(String userId) {
    this.userId = userId;
  }
  String getUserId() {
    return this.userId;
  }

  void handleSSE() async{
    Uri url = Uri.parse(SSE_SERVER_HOST+SSE_SERVER_PATH);
    String eventType = SSE_MSG_TYPE;
    String channel = SSE_MSG_CHANNEL;

    SSEClient sseClient = SSEClient(url, eventType, channel);

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

  Future<void> fetchMessages() async {
    // 从 API 获取数据并解析 JSON，此处仅为示例
    List<Map<String, dynamic>> jsonResponse = [
      {"userId": "user1", "text": "Text 1", "type": "text"},
      {"userId": "user2", "text": "Text 2", "type": "link"},
      {"userId": "user3", "text": "Text 3", "type": "reserved"},
    ];

    List<MessageModel> newMessages =
        jsonResponse.map((json) => MessageModel.fromJson(json)).toList();
    messages.addAll(newMessages);
  }
}

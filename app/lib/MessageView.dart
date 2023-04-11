import 'package:app/config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/controller.dart';
import 'package:app/MessageController.dart';
import 'package:app/message_bubble.dart';

class MessageView extends StatelessWidget {
  MessageView({required Key key }) : super(key: key);
  
  final Controller c = Get.find();
  final MessageController messageController = Get.find<MessageController>();
  
  @override
  Widget build(BuildContext context) {
    Future<String> Username = c.getUserName();
    Username.then((u) {
      messageController.setUsername(u);
      try{
        messageController.closeSSE();
      }catch(e){
        // print(e);
      }

      if (u == ""){
        messageController.handleSSE(SSE_MSG_DEFAULT_CHANNEL);
      }else{
        messageController.handleSSE(u);
      }
      // 加载服务器端历史消息
      messageController.chatRecord.fetchMessages(u, 0).then((value2) {
      });
    });

    

    return Obx(() {
      final messages = messageController.messages;
      return ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return MessageBubble(
            key: message.key,
            sender: message.username,
            dataList: message.dataList,
            type: message.type,
          );
        },
        shrinkWrap: true,
      );
    });
  }
}
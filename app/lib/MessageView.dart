import 'package:app/config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/controller.dart';
import 'package:app/MessageController.dart';
import 'package:app/message_item.dart';

class MessageView extends StatelessWidget {
  MessageView({required Key key }) : super(key: key);
  
  final Controller c = Get.find();
  final MessageController messageController = Get.put(MessageController());

  @override
  Widget build(BuildContext context) {
    // 通过这种方式将MVC中的Controller和程序框架的Controller隔离开来
    Future<String> Username = c.getUserName();
    Username.then((value) {
      messageController.setUsername(value);
      try{
        messageController.closeSSE();
      }catch(e){
        // print(e);
      }
      if (value == DEFAULT_AYONYMOUS_USER_ID){
        messageController.handleSSE(SSE_MSG_DEFAULT_CHANNEL);
      }else{
        messageController.handleSSE(value);
      }
    });


    return Obx(
        () => ListView.builder(
          itemCount: messageController.messages.length,
          itemBuilder: (context, index) {
            final message = messageController.messages[index];
            return MessageItem(message: message);
          },
          // reverse: true,
          shrinkWrap: true,
        ),
      );
  }
}
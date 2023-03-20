
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

    messageController.setUserId(c.getUserId());
    messageController.handleSSE();

    return Obx(
        () => ListView.builder(
          itemCount: messageController.messages.length,
          itemBuilder: (context, index) {
            final message = messageController.messages[index];
            return MessageItem(message: message);
          },
          reverse: true,
          shrinkWrap: true,
        ),
      );
  }
}
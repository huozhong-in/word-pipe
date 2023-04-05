import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class Message {
  final String text;

  Message(this.text);
}

class MessageController extends GetxController {
  final messages = <Message>[].obs;

  @override
  void onInit() {
    super.onInit();
    messages.add(Message("Message 1"));
    Timer.periodic(Duration(milliseconds: 200), (timer) {
      final Message firstMessage = messages[0];
      final updatedText = firstMessage.text + "a";
      messages[0] = Message(updatedText);
    });
  }
}

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final messageController = Get.put(MessageController());

    return Obx(() {
      final messages = messageController.messages;

      return Material(
        child: ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return ListTile(
              title: Text(message.text),
            );
          },
        ),
      );
    });
  }
}

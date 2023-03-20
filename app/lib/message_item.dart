import 'package:flutter/material.dart';
import 'package:app/MessageModel.dart';
import 'package:app/message_bubble.dart';
import 'package:app/config.dart';

class MessageItem extends StatelessWidget {
  final MessageModel message;

  MessageItem({required this.message});

  @override
  Widget build(BuildContext context) {
    // 根据类型选择不同的 Widget 渲染
    switch (message.type) {
      case WordPipeMessageType.reserved:
        return const Text("reserved");
      case  WordPipeMessageType.word_root:
        // 返回一个消息气泡
        return MessageBubble(userId: message.userId, dataList: message.dataList, type: message.type);
      // 根据需要添加更多类型
      default:
        return const Text('Unknown type');
    }
  }
}

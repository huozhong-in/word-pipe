import 'package:flutter/material.dart';
import 'package:app/MessageModel.dart';
import 'package:app/message_bubble.dart';
import 'package:app/typing_bubble.dart';
import 'package:app/config.dart';
import 'package:get/get.dart';

class MessageItem extends StatelessWidget {
  final MessageModel message;

  const MessageItem({required this.message});

  @override
  Widget build(BuildContext context) {
    // 根据类型选择不同的 Widget 渲染，大部分需要气泡样式的消息都转到 MessageBubble 中处理
    switch (message.type as int) {
      case WordPipeMessageType.reserved: 
        // 保留
        return const Text("reserved");
      case  WordPipeMessageType.typing:
        // 正在输入。机器人收到任务后，立即回复一个loading的效果当作占位符，等待后续信息到达
        return TypingBubble(key: message.key, sender: message.username, dataList: message.dataList);
      default:
        return MessageBubble(
          key: message.key, 
          sender: message.username, 
          sender_uuid: message.uuid,
          dataList: message.dataList, 
          type: message.type);
    }
  }
}

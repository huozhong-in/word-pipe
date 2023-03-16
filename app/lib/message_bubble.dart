import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessageBubbleClipper extends CustomClipper<Path> {
  final bool isSender;

  MessageBubbleClipper({required this.isSender});

  @override
  Path getClip(Size size) {
    final path = Path();
    const tailWidth = 5.0;
    const tailHeight = 10.0;
    const borderRadius = 5.0;

    if (isSender) {
      path.addRRect(RRect.fromLTRBR(0, 0, size.width - tailWidth, size.height, const Radius.circular(borderRadius)));
      path.lineTo(size.width - tailWidth, tailHeight);
      path.lineTo(size.width, tailHeight + tailHeight / 2);
      path.lineTo(size.width - tailWidth, tailHeight * 2);
      path.lineTo(0, tailHeight);
      path.addRRect(RRect.fromLTRBR(0, 0, size.width - tailWidth, size.height, const Radius.circular(borderRadius)));
    } else {
      path.addRRect(RRect.fromLTRBR(tailWidth, 0, size.width, size.height, const Radius.circular(borderRadius)));
      path.lineTo(tailWidth, tailHeight);
      path.lineTo(0, tailHeight + tailHeight / 2);
      path.lineTo(tailWidth, tailHeight * 2);
      path.lineTo(tailWidth, tailHeight);
      path.addRRect(RRect.fromLTRBR(tailWidth, 0, size.width, size.height, const Radius.circular(borderRadius)));
    }
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


class MessageBubble extends StatelessWidget {
  final String message;
  final bool isSender;
  final Color bubbleColor;

  const MessageBubble({super.key, 
    required this.message,
    required this.isSender,
    required this.bubbleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width * 0.8,
      padding: isSender
          ? const EdgeInsets.fromLTRB(16, 8, 30, 8)
          : const EdgeInsets.fromLTRB(30, 8, 16, 8),
      child: ClipPath(
        clipper: MessageBubbleClipper(isSender: isSender),
        child: Container(
          color: bubbleColor,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
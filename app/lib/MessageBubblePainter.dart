import 'package:flutter/material.dart';

class MessageBubblePainter extends CustomPainter {
  final bool isMe;
  final Color bubbleColor;

  MessageBubblePainter({required this.isMe, required this.bubbleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = bubbleColor;
    final path = Path();
    const tailWidth = 5.0;
    const tailHeight = 10.0;
    const borderRadius = 5.0;

    if (isMe) {
      path.addRRect(
          RRect.fromLTRBR(0, 0, size.width - tailWidth, size.height, const Radius.circular(borderRadius)));
      path.lineTo(size.width - tailWidth, tailHeight);
      path.lineTo(size.width, tailHeight + tailHeight / 2);
      path.lineTo(size.width - tailWidth, tailHeight * 2);
      path.close();
    } else {
      path.addRRect(
          RRect.fromLTRBR(tailWidth, 0, size.width, size.height, const Radius.circular(borderRadius)));
      path.lineTo(tailWidth, tailHeight);
      path.lineTo(0, tailHeight + tailHeight / 2);
      path.lineTo(tailWidth, tailHeight * 2);
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
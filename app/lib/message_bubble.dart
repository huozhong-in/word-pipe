import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app/controller.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

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

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });
  
  @override
  Widget build(BuildContext context) {
    void copyTextToClipboard() async {
      await Clipboard.setData(ClipboardData(text: message));
      log('Text content copied to clipboard.');
      ScaffoldMessenger.of(Get.overlayContext!).showSnackBar(
        customSnackBar(content: "内容已复制到剪贴板"),
      );
    }
    Color bubbleColor;
    if(isMe){
      bubbleColor = const Color.fromRGBO(40, 178, 95, 1);
    }else{
      bubbleColor = Colors.green[200]!;
    }
    
    return GestureDetector(
      onLongPress: () {
        copyTextToClipboard();
      },
      child: Container(
        margin: isMe
            ? const EdgeInsets.fromLTRB(8, 8, 8, 8)
            : const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Stack(
          children: [
            CustomPaint(
              painter: MessageBubblePainter(isMe: isMe, bubbleColor: bubbleColor),
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: SelectableText.rich(
                  TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: <InlineSpan>[
                      TextSpan(text: message),
                      TextSpan(
                        text: '链接',
                        style: const TextStyle(color: Color.fromARGB(255, 11, 66, 93), decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            Uri url = Uri.parse('https://translate.google.com/?sl=en&tl=zh-CN&text=demonstration&op=translate');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              ScaffoldMessenger.of(Get.overlayContext!).showSnackBar(
                                const SnackBar(content: Text('无法打开链接')),
                              );
                            }
                          },
                      ),
                      // const TextSpan(text: '查看更多信息。'),
                    ],
                  )
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
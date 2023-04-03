import 'dart:developer';
import 'package:app/MessageController.dart';
import 'package:app/controller.dart';
import 'package:flutter/material.dart';
import 'package:app/config.dart';
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  final String sender;
  final dynamic dataList;
  final int type;

  MessageBubble({
    super.key,
    required this.sender,
    required this.dataList,
    required this.type,
  });

  final Controller c = Get.find();
  bool get isMe => sender == Get.find<MessageController>().getUsername() || sender == DEFAULT_AYONYMOUS_USER_ID;

  @override
  Widget build(BuildContext context) {
    // void copyTextToClipboard() async {
    //   await Clipboard.setData(ClipboardData(text: message));
    //   log('Text content copied to clipboard.');
    //   ScaffoldMessenger.of(Get.overlayContext!).showSnackBar(
    //     customSnackBar(content: "内容已复制到剪贴板"),
    //   );
    // }
    Color bubbleColor;
    if(isMe){
      bubbleColor = const Color.fromRGBO(40, 178, 95, 1);
    }else{
      bubbleColor = Colors.green[200]!;
    }
    
    return GestureDetector(
      // onLongPress: () {
      //   copyTextToClipboard();
      // },
      child: Container(
        margin: isMe
            ? const EdgeInsets.fromLTRB(80, 8, 8, 8)
            : const EdgeInsets.fromLTRB(8, 8, 80, 8),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: IntrinsicWidth(
            child: Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  // Left avatar
                  Container(
                    width: 50,
                    height: 50,
                    color: Colors.black12,
                    margin: const EdgeInsets.only(right: 8),
                    child: CachedNetworkImage(
                      width: 40,
                      height: 40,
                      imageUrl: "${HTTP_SERVER_HOST}/avatar-Javris",
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                              // colorFilter:
                              //     ColorFilter.mode(Colors.red, BlendMode.colorBurn)
                              ),
                        ),
                      ),
                      placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                ],
                Flexible(
                  child: Stack(
                    children: [
                      CustomPaint(
                        painter:
                            MessageBubblePainter(isMe: isMe, bubbleColor: bubbleColor),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          // constraints: BoxConstraints(
                          //   minWidth: 320,
                          // ),
                          child: SelectableText.rich(
                            templateDispatch(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMe) ...[
                  // Right avatar
                  Container(
                    width: 50,
                    height: 50,
                    // color: Colors.black12,
                    margin: const EdgeInsets.only(left: 8),
                    child: SvgPicture.network(
                      "${HTTP_SERVER_HOST}/${AVATAR_FILE_DIR}/${Get.find<MessageController>().getUsername()}",
                      height: 40,
                      width: 40,
                      semanticsLabel: 'user avatar',
                      placeholderBuilder: (BuildContext context) => Container(
                          padding: const EdgeInsets.all(40.0),
                          child: const CircularProgressIndicator()),
                      )
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  // todo pending 的效果，因为跟机器人的对话实质是下任务，所以要有回执，有回复就占用回执的位置显示出来
  // todo 机器人的回复，要有一个loading的效果，因为机器人的回复是异步的，所以要有loading的效果，使用SSE实现
  TextSpan templateDispatch(BuildContext context) {
    if(type==WordPipeMessageType.word2root){
      return templateWord2Root(context);
    }else if(type==WordPipeMessageType.root2word){
      return templateRoot2Word(context);
    }else{
      return templateText(context);
    }
  }


  TextSpan templateWord2Root(BuildContext context) {
    List<TextSpan> spans = [];

    dataList.forEach((word_list) {
      word_list.forEach((word_name, root_list) {
        spans.add(TextSpan(text: word_name, style: TextStyle(
          fontFamily: GoogleFonts.getFont('Source Sans Pro').fontFamily,
          fontFamilyFallback: const ['Arial'],
          fontWeight: FontWeight.bold, fontSize: 16)));
        spans.add(TextSpan(text: "\n"));
        root_list.forEach((root) {
          root.forEach((root_name, attr_list) {
            spans.add(TextSpan(text: root_name, style: TextStyle(color: Colors.blue)));
            spans.add(TextSpan(text: "\n"));
            attr_list.forEach((attr) {
              attr.forEach((key, value) {
                if (key == 'example') {
                  // Handle 'example' key, which contains a list of strings
                  List<String> examples = List<String>.from(value);
                  spans.add(TextSpan(text: "Examples:\n"));
                  examples.forEach((example) {
                    spans.add(TextSpan(text: " ["));
                    spans.add(
                      TextSpan(
                        text: example, 
                        style: TextStyle(
                          color: Color.fromARGB(255, 11, 66, 93),
                          fontFamily: GoogleFonts.getFont('Source Sans Pro').fontFamily,
                          fontSize: 14,
                          decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              await c.chat(Get.find<MessageController>().getUsername(), "/root $example");
                            },
                      )
                    );
                    spans.add(TextSpan(text: "] "));
                  });
                  spans.add(TextSpan(text: "\n"));
                  spans.add(TextSpan(text: "\n"));
                } else {
                  // Handle other keys, which contain strings
                  spans.add(TextSpan(text: "    ${key}: ${(value as String).trim()}\n", style: TextStyle(color: Colors.blueGrey)));
                }
              });
            });
          });
        });
      });
    });

    return TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: spans,
    );
  }



  TextSpan templateText(BuildContext context) {
    return TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: <InlineSpan>[
        TextSpan(text: dataList[0] as String),
      ],
    );
  }

  TextSpan templateRoot2Word(BuildContext context) {
    return TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: <InlineSpan>[
        ...dataList.map((value) => TextSpan(
          text: value,
          style: TextStyle(
              color: Color.fromARGB(255, 210, 10, 220),
              decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              await c.chat(Get.find<MessageController>().getUsername(), "/root $value");
            },
        )),
      ],
    );
  }
}

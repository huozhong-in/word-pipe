import 'package:app/MessageController.dart';
import 'package:app/controller.dart';
import 'package:flutter/material.dart';
import 'package:app/config.dart';
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/MessageBubblePainter.dart';


// ignore: must_be_immutable
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
  final MessageController messageController = Get.find<MessageController>();
  bool get isMe => sender == messageController.getUsername() || sender == DEFAULT_AYONYMOUS_USER_ID;
  
  //   List<InlineSpan> spans = [];
  //   RegExp exp = RegExp(r'(\[.*?\])');
  //   List<String> texts = text.split(exp);
  //   for (var i = 0; i < texts.length; i++) {
  //     if (texts[i].startsWith('[') && texts[i].endsWith(']')) {
  //       String emoji = texts[i].substring(1, texts[i].length - 1);
  //       spans.add(WidgetSpan(
  //         child: SvgPicture.asset(
  //           'assets/emoji/$emoji.svg',
  //           width: 20,
  //           height: 20,
  //         ),
  //       ));
  //     } else {
  //       spans.add(TextSpan(text: texts[i]));
  //     }
  //   }
  //   return spans;
  // }

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
                      imageUrl: "${HTTP_SERVER_HOST}/avatar-Jarvis",
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
  
  TextSpan templateDispatch(BuildContext context) {
    if(type == WordPipeMessageType.word2root){
      // 通过单词查词根
      return templateWord2Root(context);
    }else if(type == WordPipeMessageType.root2word){
      // 通过词根查单词
      return templateRoot2Word(context);
    }else if(type == WordPipeMessageType.stream){
      // 因为机器人的回复是异步且流式，当消息陆续到达，逐一显示
      return templateStream(context);
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
              await c.chat(messageController.getUsername(), "/root $value");
            },
        )),
      ],
    );
  }

  TextSpan templateText(BuildContext context) {
    return TextSpan(text: dataList[0] as String);
  }

  TextSpan templateStream(BuildContext context) {
    return TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: <InlineSpan>[
        TextSpan(text: dataList[0] as String),
      ],
    );
  }
}
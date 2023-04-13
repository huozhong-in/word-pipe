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
import 'package:lottie/lottie.dart';

// ignore: must_be_immutable
class MessageBubble extends StatelessWidget {
  final String sender;
  final String sender_uuid;
  final List<dynamic> dataList;
  final RxInt type;

  MessageBubble({
    super.key,
    required this.sender,
    required this.sender_uuid,
    required this.dataList,
    required RxInt type,
  }) : this.type = type;
  // }) : this.dataList = dataList.map((e) => e.toString()).toList(),
  //      this.type = type;

  final Controller c = Get.find();
  final MessageController messageController = Get.find<MessageController>();
  String username = "";
  bool isMe = false;
  

  @override
  Widget build(BuildContext context) {
    Future<void> setIsMe() async {
      c.getUUID().then((_uuid) {
        isMe = _uuid == sender_uuid;
      });
      c.getUserName().then((_username) {
        username = _username;
      });
    }
    
    Widget _buildItem(){
      Color bubbleColor;
      if(isMe){
        bubbleColor = const Color.fromRGBO(40, 178, 95, 1);
      }else{
        bubbleColor = Colors.green[200]!;
      }
      
      return GestureDetector(
        child: Container(
          margin: isMe
              ? const EdgeInsets.fromLTRB(80, 8, 8, 8)
              : const EdgeInsets.fromLTRB(8, 8, 80, 8),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: SizedBox(
              width: double.maxFinite,
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
                            child: Obx(() => SelectableText.rich(
                              templateDispatch(context),
                              minLines: 1,
                            )),
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
                        "${HTTP_SERVER_HOST}/${AVATAR_FILE_DIR}/${username}",
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
    return FutureBuilder<void>(
      future: setIsMe(),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Failed to load messages.'));
        } else {
          return _buildItem();
        }
      },
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
    }else if(type == WordPipeMessageType.typing){
      return TextSpan(children: [WidgetSpan(child: Lottie.network('https://assets6.lottiefiles.com/packages/lf20_nZBVpi.json', width: 30, height: 20, repeat: true, animate: true))]);
    }else if(type == WordPipeMessageType.chathistory){
      return templateChatHistory(context);
    }else{
      return templateText(context);
    }
  }

  TextSpan templateStream(BuildContext context) {
    // 将dataList中的每个元素都转换为TextSpan
    List<TextSpan> spans = [];
    dataList.forEach((element) {
      spans.add(TextSpan(text: element as String));
    });
    return TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: <InlineSpan>[
        ...spans,
      ],
    );
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
                              await c.chat(username, "/root $example");
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
              await c.chat(await c.getUserName(), "/root $value");
            },
        )),
      ],
    );
  }

  TextSpan templateText(BuildContext context) {
    return TextSpan(text: dataList[0] as String);
  }

  TextSpan templateChatHistory(BuildContext context){
    List<TextSpan> spans = [];
    dataList.forEach((element) {
      spans.add(TextSpan(text: element as String));
    });
    return TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: spans,
    );
  }
}
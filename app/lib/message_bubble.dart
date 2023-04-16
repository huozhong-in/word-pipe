import 'dart:io';
import 'package:wordpipe/MessageController.dart';
import 'package:wordpipe/controller.dart';
import 'package:flutter/material.dart';
import 'package:wordpipe/config.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wordpipe/MessageBubblePainter.dart';
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
  bool isMe = false;
  

  @override
  Widget build(BuildContext context) {
    Future<void> setIsMe() async {
      c.getUUID().then((_uuid) {
        isMe = _uuid == sender_uuid;
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
                    showAvatar()
                  ],
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end ,
                      children: [
                        Stack(
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
                        Container(
                          width: 30,
                          height: 30,
                          // color: Colors.black12,
                          margin: const EdgeInsets.all(1),
                          child: IconButton(
                            onPressed: () {
                              if (dataList.length > 0){
                                String total_text = "";
                                for (var i = 0; i < dataList.length; i++) {
                                  // if dataList[i] is String, join them
                                  if (dataList[i] is String)
                                    total_text += dataList[i];
                                }
                                Clipboard.setData(ClipboardData(text: total_text));
                                if (total_text.length > 0)
                                  customSnackBar(title: "Success", content: "Copied to clipboard");
                              }                              
                            },
                            icon: Icon(Icons.copy, size: 15, color: Colors.black26)
                            ),
                        )
                      ],
                    ),
                  ),
                  if (isMe) ...[
                    // Right avatar
                    showAvatar()
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

  Widget showAvatar() {
    return FutureBuilder<String>(
      future: c.imageTypes("${HTTP_SERVER_HOST}/${AVATAR_FILE_DIR}/${sender}"),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Icon(Icons.error);
          }
          if (snapshot.data == 'jpeg') {
            return CachedNetworkImage(
              imageUrl: "${HTTP_SERVER_HOST}/${AVATAR_FILE_DIR}/${sender}",
              imageBuilder: (context, imageProvider) => Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              placeholder: (context, url) => Container(
                width: 50,
                height: 50,
                color: Colors.black12,
                margin: const EdgeInsets.only(right: 8),
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Icon(Icons.error),
            );
          } else {
            return SvgPicture.network(
              "${HTTP_SERVER_HOST}/${AVATAR_FILE_DIR}/${sender}",
              height: 40,
              width: 40,
              semanticsLabel: 'avatar',
              placeholderBuilder: (BuildContext context) => Container(
                width: 50,
                height: 50,
                color: Colors.black12,
                margin: const EdgeInsets.only(right: 8),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
        }
        return Container(
          width: 50,
          height: 50,
          color: Colors.black12,
          margin: const EdgeInsets.only(right: 8),
          child: Center(child: CircularProgressIndicator()),
        );
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
    if ( dataList.length == 0 ) {
      return TextSpan(children: [TextSpan(text: "No root information was found for this word."), WidgetSpan(child: Icon(Icons.sentiment_dissatisfied, color: Colors.red, size: 20))]);
    }

    List<InlineSpan> spans = [];

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
                    spans.add(
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: TextButton(
                          onPressed: () async {
                            await c.chat(await c.getUserName(), "/root $example");
                          }, 
                          child: Text(
                            example,
                            style: TextStyle(
                              color: Color.fromARGB(255, 11, 66, 93),
                              fontSize: 14,
                              decoration: TextDecoration.underline
                            )
                          )
                        )
                      )
                    );
                  });
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
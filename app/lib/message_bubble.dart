import 'package:wordpipe/config.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/MessageController.dart';
import 'package:wordpipe/MessageBubblePainter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final MessageController messageController = Get.find();
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
        bubbleColor = Colors.green[100]!;
      }

      // 移动端调窄边距
      double edge = GetPlatform.isMobile ? 8 : 80;
      
      return GestureDetector(
        child: Container(
          margin: isMe
              ? EdgeInsets.fromLTRB(edge, 8, 8, 8)
              : EdgeInsets.fromLTRB(8, 8, edge, 8),
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
                    showAvatar2()
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
                                  templateDispatcher(context),
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
                    showAvatar2()
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

  Widget showAvatar2() {
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

  TextSpan templateDispatcher(BuildContext context) {
    if(type == WordPipeMessageType.word_highlight){
      // 将句子内单词高亮
      return templateWordHighlight(context);
    }else if(type == WordPipeMessageType.system){
      // 显示系统消息，比如：某某撤回一条消息，某某加入群聊
      return templateSysMsg(context);
    }else if(type == WordPipeMessageType.stream){
      // 因为机器人的回复是异步且流式，当消息陆续到达，逐一显示
      return templateStream(context);
    }else if(type == WordPipeMessageType.typing){
      // 显示机器人正在输入
      return TextSpan(children: [WidgetSpan(child: Lottie.network('https://assets6.lottiefiles.com/packages/lf20_nZBVpi.json', width: 30, height: 20, repeat: true, animate: true))]);
    }else if(type == WordPipeMessageType.chathistory){
      // 加载聊天历史
      return templateChatHistory(context);
    }else if(type == WordPipeMessageType.reply_for_query_sentence){

      return templateReply4Sentence(context);
    }else if(type == WordPipeMessageType.reply_for_query_word){
      return templateReply4Word(context);
    }else{
      // 普通多行文本
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

  TextSpan templateRoot2Word(BuildContext context) {
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
                            c.chat(await c.getUserName(), "$example");
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

  TextSpan templateWord2Root(BuildContext context) {
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
              c.chat(await c.getUserName(), "$value");
            },
        )),
      ],
    );
  }

  TextSpan templateText(BuildContext context) {
    List<TextSpan> spans = [];
    int i=0;
    dataList.forEach((element) {
      spans.add(TextSpan(text: element as String));
      if (i < dataList.length - 1)
        spans.add(TextSpan(text: "\n"));
      i++;
    });
    return TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: spans,
    );
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
  
  TextSpan templateReply4Sentence(BuildContext context) {
    List<TextSpan> spans = [];
    // split `scraping`|`process` to two words
    List<String> dataList = this.dataList[0].split('|');

    // 我猜你想知道[`scraping`|`process`]的具体意思，已经为你高亮。如果我猜错了，你可点击其他单词以获取其意思。或选择通过例句从上下文来猜测意思。
    dataList.forEach((element) {
      spans.add(TextSpan(text: element.trim()));
    });
    return TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: spans,
    );
  }

  TextSpan templateReply4Word(BuildContext context) {
      List<TextSpan> spans = [];
      dataList.forEach((element) {
        spans.add(TextSpan(text: element as String));
      });
      return TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: spans,
      );
  }
  
  TextSpan templateWordHighlight(BuildContext context) {
  List<InlineSpan> spans = [];
  RegExp exp = RegExp(r'(\w+|\w+-*\w+|\W+)');
  
  for (int i = 0; i < dataList.length; i++) {
    String str = dataList[i] as String;
    int lastEnd = 0;
    Iterable<RegExpMatch> matches = exp.allMatches(str);
    
    for (RegExpMatch match in matches) {
      if (match.group(0)!.contains(RegExp(r'[a-zA-Z]+')) &&  
      !match.group(0)!.contains('-')) {
        spans.add(
          WidgetSpan(  
            alignment: PlaceholderAlignment.middle,
            child: TextButton(
              style: ButtonStyle(
                minimumSize: MaterialStateProperty.all<Size>(Size(8, 8)),
                padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.all(1)),
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green[100]!),
                overlayColor: MaterialStateProperty.all<Color>(Colors.green[200]!),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  )
                )
              ),
              onPressed: () async {
                c.chat(await c.getUserName(), match.group(0)!);
              }, 
              child: Text(
                match.group(0)!,
                style: TextStyle(
                  color: Color.fromARGB(255, 11, 66, 93),
                  // decoration: TextDecoration.underline
                )
              )
            )
          )
        ); 
      } else {
        spans.add(TextSpan(text: match.group(0)!));
      }
      lastEnd = match.end;
    }
  }
  
  return TextSpan(
    style: DefaultTextStyle.of(context).style,
    children: spans,
  ); 
}
  
  TextSpan templateSysMsg(BuildContext context) {
    return TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: <InlineSpan>[
        TextSpan(
          text: dataList[0] as String,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),)
      ],
    );
  }
}

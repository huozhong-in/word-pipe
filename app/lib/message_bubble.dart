import 'package:wordpipe/config.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/MessageController.dart';
import 'package:wordpipe/MessageBubblePainter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wordpipe/custom_widgets.dart';


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
  final SettingsController settingsController = Get.find<SettingsController>();
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
                      crossAxisAlignment: CrossAxisAlignment.end,
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
                        Visibility(
                          visible: type != WordPipeMessageType.autoreply,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Visibility(
                                visible: isMe == false,
                                child: Tooltip(
                                  message: "Play audio",
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    margin: const EdgeInsets.all(1),
                                    child: IconButton(
                                      onPressed: () {
                                        String keyString = key.hashCode.toString();
                                        // 判断已经是当前音频的播放状态，则点击暂停
                                        if (messageController.whichIsPlaying.value == keyString) {
                                          if (messageController.buttonNotifier.value == ButtonState.playing) {
                                            messageController.buttonNotifier.value = ButtonState.paused;
                                            messageController.ttsPlayer.pause();
                                          } else if (messageController.buttonNotifier.value == ButtonState.paused) {
                                            messageController.buttonNotifier.value = ButtonState.playing;
                                            messageController.ttsPlayer.play();
                                          }
                                          if (messageController.ttsJobs.containsKey(keyString)) {
                                            messageController.ttsJobs.remove(keyString);
                                          }
                                        }else{
                                          // 如果是在播放其他音频，则先停止播放，重新设置正在播放的音频
                                          if (messageController.ttsPlayer.playerState.playing){
                                            messageController.ttsPlayer.pause().then((value) {
                                              messageController.whichIsPlaying.value = keyString;
                                              messageController.buttonNotifier.value = ButtonState.loading;
                                              messageController.addToTTSJobs(keyString, dataList.join('').split('[W0RDP1PE]')[0]);
                                            });
                                          }else{
                                            messageController.whichIsPlaying.value = keyString;
                                            messageController.buttonNotifier.value = ButtonState.loading;
                                            messageController.addToTTSJobs(keyString, dataList.join('').split('[W0RDP1PE]')[0]);
                                          }
                                        }
                                      },
                                      icon: Obx(() {
                                        if (messageController.whichIsPlaying.value == key.hashCode.toString()) {
                                          switch (messageController.buttonNotifier.value) {
                                            case ButtonState.loading:
                                              return CircularProgressIndicator(strokeWidth: 2,color: Colors.black26,);
                                            case ButtonState.paused:
                                              return Icon(Icons.play_arrow, size: 15, color: Colors.black26);
                                            case ButtonState.playing:
                                              return Icon(Icons.pause, size: 15, color: Colors.black26);
                                            default:
                                              return Icon(Icons.play_arrow, size: 15, color: Colors.black26);
                                          }
                                        } else {
                                          return Icon(Icons.play_arrow, size: 15, color: Colors.black26);
                                        }
                                      }),
                                    ),
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: "Copy to clipboard",
                                child: Container(
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
                                ),
                              ),
                            ],
                          ),
                        ),
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

  // Widget showAvatar() {
  //   return FutureBuilder<String>(
  //     future: c.imageTypes("${HTTP_SERVER_HOST}/${AVATAR_FILE_DIR}/${sender}"),
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.done) {
  //         if (snapshot.hasError) {
  //           return Icon(Icons.error);
  //         }
  //         if (snapshot.data == 'jpeg') {
  //           return CachedNetworkImage(
  //             imageUrl: "${HTTP_SERVER_HOST}/${AVATAR_FILE_DIR}/${sender}",
  //             imageBuilder: (context, imageProvider) => Container(
  //               width: 50,
  //               height: 50,
  //               margin: const EdgeInsets.only(right: 8),
  //               decoration: BoxDecoration(
  //                 borderRadius: BorderRadius.circular(3),
  //                 image: DecorationImage(
  //                   image: imageProvider,
  //                   fit: BoxFit.cover,
  //                 ),
  //               ),
  //             ),
  //             placeholder: (context, url) => Container(
  //               width: 50,
  //               height: 50,
  //               color: Colors.black12,
  //               margin: const EdgeInsets.only(right: 8),
  //               child: Center(child: CircularProgressIndicator()),
  //             ),
  //             errorWidget: (context, url, error) => Icon(Icons.error),
  //           );
  //         } else {
  //           return SvgPicture.network(
  //             "${HTTP_SERVER_HOST}/${AVATAR_FILE_DIR}/${sender}",
  //             height: 40,
  //             width: 40,
  //             semanticsLabel: 'avatar',
  //             placeholderBuilder: (BuildContext context) => Container(
  //               width: 50,
  //               height: 50,
  //               color: Colors.black12,
  //               margin: const EdgeInsets.only(right: 8),
  //               child: Center(child: CircularProgressIndicator()),
  //             ),
  //           );
  //         }
  //       }
  //       return Container(
  //         width: 50,
  //         height: 50,
  //         color: Colors.black12,
  //         margin: const EdgeInsets.only(right: 8),
  //         child: Center(child: CircularProgressIndicator()),
  //       );
  //     },
  //   );
  // }

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
    if(type == WordPipeMessageType.system){
      // 显示系统消息，比如：某某撤回一条消息，某某加入群聊
      return templateSysMsg(context);
    }else if(type == WordPipeMessageType.autoreply){
      // 显示自动回复，比如：你好，我是机器人
      return templateAutoReply(context);
    }else if(type == WordPipeMessageType.stream){
      // 因为AI的回复是异步且流式，当消息陆续到达，逐一显示。可以认为每item是一个字符，包括\n，不需要额外处理
      return templateStreamWithHighlight(context);
    }else if(type == WordPipeMessageType.chathistory){
      // 加载聊天历史。文本里会有\n，所以依次append即可
      return templateRawText(context);
    }else if(type == WordPipeMessageType.flask_reply_for_word){
      // 处理从flask server返回的单词问询消息
      return templateFlaskReply4Word(context);
    }else if(type == WordPipeMessageType.flask_reply_for_sentence){
      // 处理从flask server返回的单词例句生成消息
      return templateFlaskReply4Sentence(context);
    }else if(type == WordPipeMessageType.reply_for_query_word){
      // 处理从OpenAI API返回的单词查询结果
      return templateReply4Word(context);
    }else if(type == WordPipeMessageType.reply_for_query_word_example_sentence){
      // 处理从OpenAI API返回的单词例句生成结果
      return templateReply4WordExampleSentence(context);
    }else if(type == WordPipeMessageType.reply_for_translate_sentence){
      return templateReply4TranslateSentence(context);
    }else if(type == WordPipeMessageType.reply_for_answer_question){
      return templateReply4AnswerQuestion(context);
    }else if(type == WordPipeMessageType.flask_reply_for_sentence_zh_en){
      return templateFlaskReply4SentenceZhEn(context);
    }else if(type == WordPipeMessageType.reply_for_translate_sentence_zh_en){
      return templateReply4TranslateSentenceZhEn(context);
    }else{
      // 普通多行文本，每行是一个字符串
      return templateText(context);
    }
  }

  TextSpan templateStreamWithHighlight(BuildContext context) {
    // 处理流式消息，每个item是一个字符，包括\n
    return TextSpan(
      style: TextStyle(fontSize: settingsController.fontSizeConfig.value),
      children: _wordHighlight(dataList),
    );
  }

  // TextSpan templateRoot2Word(BuildContext context) {
  //   if ( dataList.length == 0 ) {
  //     return TextSpan(children: [TextSpan(text: "No root information was found for this word."), WidgetSpan(child: Icon(Icons.sentiment_dissatisfied, color: Colors.red, size: 20))]);
  //   }

  //   List<InlineSpan> spans = [];

  //   dataList.forEach((word_list) {
  //     word_list.forEach((word_name, root_list) {
  //       spans.add(TextSpan(text: word_name, style: TextStyle(
   //         fontSize: 16)));
  //       spans.add(TextSpan(text: "\n"));
  //       root_list.forEach((root) {
  //         root.forEach((root_name, attr_list) {
  //           spans.add(TextSpan(text: root_name, style: TextStyle(color: Colors.blue)));
  //           spans.add(TextSpan(text: "\n"));
  //           attr_list.forEach((attr) {
  //             attr.forEach((key, value) {
  //               if (key == 'example') {
  //                 // Handle 'example' key, which contains a list of strings
  //                 List<String> examples = List<String>.from(value);
  //                 spans.add(TextSpan(text: "Examples:\n"));
  //                 examples.forEach((example) {
  //                   spans.add(
  //                     WidgetSpan(
  //                       alignment: PlaceholderAlignment.middle,
  //                       child: TextButton(
  //                         onPressed: () async {
  //                           c.chat(await c.getUserName(), "$example");
  //                         }, 
  //                         child: Text(
  //                           example,
  //                           style: TextStyle(
  //                             color: Color.fromARGB(255, 11, 66, 93),
  //                             fontSize: 14,
  //                             decoration: TextDecoration.underline
  //                           )
  //                         )
  //                       )
  //                     )
  //                   );
  //                 });
  //                 spans.add(TextSpan(text: "\n"));
  //               } else {
  //                 // Handle other keys, which contain strings
  //                 spans.add(TextSpan(text: "    ${key}: ${(value as String).trim()}\n", style: TextStyle(color: Colors.blueGrey)));
  //               }
  //             });
  //           });
  //         });
  //       });
  //     });
  //   });

  //   return TextSpan(
  //     style: TextStyle(fontSize: settingsController.fontSizeConfig.value),
  //     children: spans,
  //   );
  // }

  // TextSpan templateWord2Root(BuildContext context) {
  //   return TextSpan(
  //     style: TextStyle(fontSize: settingsController.fontSizeConfig.value),
  //     children: <InlineSpan>[
  //       ...dataList.map((value) => TextSpan(
  //         text: value,
  //         style: TextStyle(
  //             color: Color.fromARGB(255, 210, 10, 220),
  //             decoration: TextDecoration.underline),
  //         recognizer: TapGestureRecognizer()
  //           ..onTap = () async {
  //             c.chat(await c.getUserName(), "$value");
  //           },
  //       )),
  //     ],
  //   );
  // }

  TextSpan templateText(BuildContext context) {
    // 处理多行长字符串，所以要手动加回车符
    List<TextSpan> spans = [];
    int i=0;
    dataList.forEach((element) {
      spans.add(TextSpan(text: element as String));
      if (i < dataList.length - 1)
        spans.add(TextSpan(text: "\n"));
      i++;
    });
    return TextSpan(
      style: TextStyle(fontSize: settingsController.fontSizeConfig.value),
      children: spans,
    );
  }

  TextSpan templateRawText(BuildContext context){
    // 直接拼接结果，不需要换行，也不需要单词高亮
    List<TextSpan> spans = [];
    dataList.forEach((element) {
      spans.add(TextSpan(text: element as String));
    });
    return TextSpan(
      style: TextStyle(fontSize: settingsController.fontSizeConfig.value),
      children: spans,
    );
  }
  
  TextSpan templateReplyGenSentence(BuildContext context) {
    List<InlineSpan> spans = [];
    // split `scraping`|`process` to two words
    List<String> dataList = this.dataList[0].split('|');

    // 我猜你想知道[`scraping`|`process`]的具体意思，已经为你高亮。如果我猜错了，你可点击其他单词以获取其意思。或选择通过例句从上下文来猜测意思。
    dataList.forEach((element) {
      spans.add(TextSpan(text: element.trim()));
    });
    return TextSpan(
      style: TextStyle(fontSize: settingsController.fontSizeConfig.value),
      children: spans,
    );
  }
  TextSpan templateReply4Word(BuildContext context) {
    // 处理流式消息，每个item是一个字符，包括\n
    return TextSpan(
      style: TextStyle(fontSize: settingsController.fontSizeConfig.value),
      children: <InlineSpan>[
        ..._wordHighlight(dataList),
      ],
    );
  }
  TextSpan templateFlaskReply4Word(BuildContext context) {
      List<InlineSpan> spans = [];
      spans.add(TextSpan(text: dataList[0] as String));
      spans.add(TextSpan(text: "\n"));
      spans.add(
        WidgetSpan(  
          alignment: PlaceholderAlignment.middle,
          child: TextButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.yellow[100]!),
              overlayColor: MaterialStateProperty.all<Color>(Colors.green[200]!),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                )
              )
            ),
            onPressed: () async {
              messageController.getChatCompletion('gpt-3.5-turbo', dataList[1] as String, WordPipeMessageType.reply_for_query_word);
            }, 
            child: Text(
              "直接告诉我答案",
              style: TextStyle(
                color: Color.fromARGB(255, 11, 66, 93),
                // decoration: TextDecoration.underline
              )
            )
          )
        )
      );
      spans.add(TextSpan(text: " 或 "));
      spans.add(
        WidgetSpan(  
          alignment: PlaceholderAlignment.middle,
          child: TextButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.yellow[100]!),
              overlayColor: MaterialStateProperty.all<Color>(Colors.green[200]!),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                )
              )
            ),
            onPressed: () async {
              messageController.getChatCompletion('gpt-3.5-turbo', dataList[1] as String, WordPipeMessageType.reply_for_query_word_example_sentence);
            }, 
            child: Text(
              "生成例句猜猜看",
              style: TextStyle(
                color: Color.fromARGB(255, 11, 66, 93),
              )
            )
          )
        )
      );
      return TextSpan(
        style: TextStyle(fontSize: settingsController.fontSizeConfig.value),
        children: spans,
      );
  }
  
  List<InlineSpan> _wordHighlight(List<dynamic> dataList, {bool autoNewline = false}) {
    List<InlineSpan> spans = [];
    RegExp exp = RegExp(r'\b[a-zA-Z]{3,}(?:-[a-zA-Z]{3,})*\b');
    for (int i = 0; i < dataList.length; i++) {
      String text = dataList[i] as String;
      var matches = exp.allMatches(text);
      int lastIndex = 0;
      for (Match match in matches) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
        spans.add(
          WidgetSpan(  
            alignment: PlaceholderAlignment.middle,
            child: TextButton(
              style: ButtonStyle(
                minimumSize: MaterialStateProperty.all<Size>(Size(8, 8)),
                padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.all(1)),
                backgroundColor: isMe? MaterialStateProperty.all<Color>(Color.fromRGBO(40, 178, 95, 1)) : MaterialStateProperty.all<Color>(Colors.green[100]!),
                overlayColor: MaterialStateProperty.all<Color>(Colors.green[200]!),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  )
                )
              ),
              onPressed: () async {
                c.chat(await c.getUserName(), match.group(0)!, messageController.conversation_id.value);
              }, 
              child: Text(
                match.group(0)!,
                style: TextStyle(
                  fontSize: settingsController.fontSizeConfig.value,
                  color: Color.fromARGB(255, 11, 66, 93),
                  // textBaseline: TextBaseline.alphabetic,
                )
              )
            )
          )
        );
        lastIndex = match.end;
      }
      spans.add(TextSpan(text: text.substring(lastIndex)));
      if (autoNewline) {
        spans.add(TextSpan(text: "\n"));
      }
    }
    
    return spans; 
  }
  
  TextSpan templateSysMsg(BuildContext context) {
    return TextSpan(
      style: TextStyle(fontSize: settingsController.fontSizeConfig.value),
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
  
  TextSpan templateReply4WordExampleSentence(BuildContext context) {
    List<InlineSpan> spans = [];

    String last_item = dataList.last as String;
    if (last_item.contains('[W0RDP1PE]')){
      // print(last_item);
      String answer = last_item.split('[W0RDP1PE]')[1];
      dataList.removeLast();
      spans = _wordHighlight(dataList);
      spans.add(TextSpan(text: "\n"));
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: QuestionButtons(answer: answer)
        )
      );
      dataList.add(last_item);
    }else{
      dataList.forEach((element) {
        spans.add(TextSpan(text: element as String));
      });
    }
    

    
    return TextSpan(
      style: TextStyle(fontSize: settingsController.fontSizeConfig.value),
      children: spans,
    );
  }
  
  TextSpan templateFlaskReply4Sentence(BuildContext context) {
    List<InlineSpan> spans = [];
    spans = _wordHighlight(dataList, autoNewline: true);
    spans.add(
      WidgetSpan(  
        alignment: PlaceholderAlignment.middle,
        child: TextButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.yellow[100]!),
            overlayColor: MaterialStateProperty.all<Color>(Colors.green[200]!),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              )
            )
          ),
          onPressed: () async {
            messageController.getChatCompletion('gpt-3.5-turbo', dataList[0] as String, WordPipeMessageType.reply_for_translate_sentence);
          }, 
          child: Text(
            "帮我翻译这个句子",
            style: TextStyle(
              color: Color.fromARGB(255, 11, 66, 93),
              // decoration: TextDecoration.underline
            )
          )
        )
      )
    );
    spans.add(TextSpan(text: " 或 "));
    spans.add(
      WidgetSpan(  
        alignment: PlaceholderAlignment.middle,
        child: TextButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.yellow[100]!),
            overlayColor: MaterialStateProperty.all<Color>(Colors.green[200]!),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              )
            )
          ),
          onPressed: () async {
            messageController.getChatCompletion('gpt-3.5-turbo', dataList[0] as String, WordPipeMessageType.reply_for_answer_question);
          }, 
          child: Text(
            "回答这个问题",
            style: TextStyle(
              color: Color.fromARGB(255, 11, 66, 93),
            )
          )
        )
      )
    );
    return TextSpan(
      style: TextStyle(fontSize: settingsController.fontSizeConfig.value),
      children: spans,
    );
  }
  
  TextSpan templateReply4TranslateSentence(BuildContext context) {
    return templateRawText(context);
  }
  
  TextSpan templateReply4AnswerQuestion(BuildContext context) {
    return templateStreamWithHighlight(context);
  }
  
  TextSpan templateFlaskReply4SentenceZhEn(BuildContext context) {
    List<InlineSpan> spans = [];
    spans = _wordHighlight(dataList, autoNewline: true);
    spans.add(
      WidgetSpan(  
        alignment: PlaceholderAlignment.middle,
        child: TextButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.yellow[100]!),
            overlayColor: MaterialStateProperty.all<Color>(Colors.green[200]!),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              )
            )
          ),
          onPressed: () async {
            messageController.getChatCompletion('gpt-3.5-turbo', dataList[0] as String, WordPipeMessageType.reply_for_translate_sentence_zh_en);
          }, 
          child: Text(
            "帮我翻译这个句子",
            style: TextStyle(
              color: Color.fromARGB(255, 11, 66, 93),
              // decoration: TextDecoration.underline
            )
          )
        )
      )
    );
    spans.add(TextSpan(text: " 或 "));
    spans.add(
      WidgetSpan(  
        alignment: PlaceholderAlignment.middle,
        child: TextButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.yellow[100]!),
            overlayColor: MaterialStateProperty.all<Color>(Colors.green[200]!),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              )
            )
          ),
          onPressed: () async {
            messageController.getChatCompletion('gpt-3.5-turbo', dataList[0] as String, WordPipeMessageType.reply_for_answer_question);
          }, 
          child: Text(
            "回答这个问题",
            style: TextStyle(
              color: Color.fromARGB(255, 11, 66, 93),
            )
          )
        )
      )
    );
    return TextSpan(
      style: TextStyle(fontSize: settingsController.fontSizeConfig.value),
      children: spans,
    );
  }
  
  TextSpan templateReply4TranslateSentenceZhEn(BuildContext context) {
    return templateStreamWithHighlight(context);
  }
  
  TextSpan templateAutoReply(BuildContext context) {
    return templateText(context);
  }
}

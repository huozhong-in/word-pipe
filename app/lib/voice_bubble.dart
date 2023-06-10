import 'package:cached_network_image/cached_network_image.dart';
import 'package:wordpipe/config.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/MessageController.dart';
import 'package:wordpipe/MessageBubblePainter.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:get/get.dart';

// ignore: must_be_immutable
class VoiceBubble extends StatelessWidget {
  final String sender;
  final String sender_uuid;
  final List<dynamic> dataList;
  final RxInt type;
  RxBool isSent;

  VoiceBubble({
    super.key,
    required this.sender,
    required this.sender_uuid,
    required this.dataList,
    required RxInt type,
    required RxBool isSent,
  }) : this.type = type, this.isSent = isSent;

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
        bubbleColor = Color.fromARGB(155, 59, 214, 157);//Colors.green[100]!;
      }else{
        bubbleColor = Colors.black12; //const Color.fromRGBO(40, 178, 95, 1);
      }

      // 移动端调窄边距
      double edge = GetPlatform.isMobile ? 8 : 100;

      return Container(
        margin: isMe
            ? EdgeInsets.fromLTRB(edge, 8, 8, 8)
            : EdgeInsets.fromLTRB(8, 8, edge, 8),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  showAvatar2(),
                Obx(() {
                  if (isMe)
                    return Visibility(
                      visible: isSent.value==false, 
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3,color: Colors.green,)
                      )
                    );
                  else
                    return SizedBox(width: 0, height: 0);
                },),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CustomPaint(
                        painter:
                          MessageBubblePainter(isMe: isMe, bubbleColor: bubbleColor),
                        child: Container(
                          padding: const EdgeInsets.all(0),
                          constraints: BoxConstraints(
                            // maxWidth: 150,
                            minWidth: 150
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () async {
                                  // 根据isSent判断，成功发送到服务器之前从本地播放，之后从服务器`dataList[2]`播放
                                  if(isSent.value == false){
                                    Directory temporaryDirectory = await getTemporaryDirectory();
                                    String fileName = dataList[1] as String;
                                    String filePath = temporaryDirectory.path + '/' + fileName + '.m4a';
                                    if (File(filePath).existsSync()) {
                                      messageController.playVoice(key.hashCode.toString(), filePath, false);
                                      return;
                                    }
                                  }
                                  String filePath = dataList[2] as String;
                                  messageController.playVoice(key.hashCode.toString(), HTTP_SERVER_HOST + filePath, true);
                                },
                                child: Container(
                                  padding: EdgeInsets.fromLTRB(0, 12, 25, 12),
                                  alignment: Alignment.centerRight,
                                  child: Icon(
                                    Icons.graphic_eq_outlined,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                                child: Obx(() => SelectableText.rich(
                                  templateDispatcher(context),
                                  minLines: 1,
                                )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMe)
                  showAvatar2()                  
              ],
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

  Widget showAvatar2() {
    String imgUrl = "${HTTP_SERVER_HOST}/${AVATAR_FILE_DIR}/${sender}";
    if (settingsController.freeChatMode.value && sender == 'Jasmine')
      imgUrl = "${HTTP_SERVER_HOST}/${AVATAR_FILE_DIR}/Jasmine-freechat";
    
    return CachedNetworkImage(
      imageUrl: imgUrl,
      imageBuilder: (context, imageProvider) => Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.scaleDown,
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
  }

  TextSpan templateDispatcher(BuildContext context) {
    List<InlineSpan> spans = [];
    String msg = dataList[0] as String;
    spans.add(TextSpan(text: msg));
    return TextSpan(
      // text: key.toString(),
      style: TextStyle(fontSize: settingsController.fontSizeConfig.value),
      children: spans,
    );
  }
}
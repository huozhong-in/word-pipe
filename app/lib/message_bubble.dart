import 'dart:developer';
import 'package:app/MessageController.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:app/config.dart';
import 'package:get/get.dart';
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
  final String userId;
  final dynamic dataList;
  final int type;

  const MessageBubble({
    super.key,
    required this.userId,
    required this.dataList,
    required this.type,
  });
  
  bool get isMe => userId == Get.find<MessageController>().getUserId();

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
                    width: 40,
                    height: 40,
                    color: Colors.black12, // Replace with your avatar image
                    margin: const EdgeInsets.only(right: 8),
                    child: CachedNetworkImage(
                      width: 30,
                      height: 30,
                      imageUrl: "http://wx.qlogo.cn/mmhead/ver_1/22L33xntlj70zzQKIljicaA5fk2z1fzFXjyqkiajicsHQsZtN3pGgw7mmju2M5VDaymv2iayhicEkR9ww2ibVW5ep4rA/132",
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
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
                            templateWordRoot(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMe) ...[
                  // Right avatar
                  Container(
                    width: 40,
                    height: 40,
                    color: Colors.black12, // Replace with your avatar image
                    margin: const EdgeInsets.only(left: 8),
                    child: CachedNetworkImage(
                      width: 30,
                      height: 30,
                      imageUrl: "https://wx.qlogo.cn/mmhead/ver_1/A2d22lUC03hNxPgdZ9iaSMwQUuwBMsol0cTWdQbjqGpdpQtGP1iaAia4UR5yvf0rhLicbiaLkSVUibpX1wqvzn9d1hMj0NicfZev8v58w0b8tInn8g/0",
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
// TODO pending 的效果，因为跟机器人的对话实质是下任务，所以要有回执，有回复就占用回执的位置显示出来
  TextSpan templateWordRoot(BuildContext context) {
    return TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: <InlineSpan>[
        TextSpan(text: dataList),
        // TextSpan(
        //   text: '链接',
        //   style: const TextStyle(
        //       color: Color.fromARGB(255, 11, 66, 93),
        //       decoration: TextDecoration.underline),
        //   recognizer: TapGestureRecognizer()
        //     ..onTap = () async {
        //       Uri url = Uri.parse(
        //           'https://translate.google.com/?sl=en&tl=zh-CN&text=demonstration&op=translate');
        //       if (await canLaunchUrl(url)) {
        //         await launchUrl(url);
        //       } else {
        //         ScaffoldMessenger.of(Get.overlayContext!)
        //             .showSnackBar(
        //           const SnackBar(
        //               content: Text('无法打开链接')),
        //         );
        //       }
        //     },
        // ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wordpipe/config.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/MessageController.dart';
import 'package:wordpipe/MessageView.dart';
import 'package:wordpipe/custom_widgets.dart';


class ConversationView extends StatelessWidget {
  ConversationView({super.key});

  final Controller c = Get.find<Controller>();
  final MessageController messageController = Get.find<MessageController>();
  final SettingsController settingsController = Get.find<SettingsController>();

  @override
  Widget build(BuildContext context) {

    Future<List<dynamic>> _getListTile() async {
      return messageController.conversation_R(await c.getUserName());
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          return Visibility(
            visible: settingsController.freeChatMode.value,
            child: Container(
              width: 180,
              margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
              constraints: BoxConstraints(
                maxWidth: 180,
                minWidth: 180,
              ),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 94, 211, 168).withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Tooltip(
                    message: '开个新话题',
                    child: ListTile(
                      leading: Icon(Icons.add),
                      title: Text('新话题', style: appThemeBright.textTheme.bodyMedium),
                      minLeadingWidth: 0,
                      minVerticalPadding: 0,
                      onTap: () async {
                        messageController.messages.clear();
                        messageController.lastSegmentBeginId = 0;
                        messageController.messsage_view_first_build = true;
                        messageController.conversation_id.value = -2; // 强制MessageView刷新
                        messageController.conversation_id.value = -1;
                        messageController.selectedConversationName.value = '';
                        messageController.commentFocus.requestFocus();
                      },
                    ),
                  ),
                  FutureBuilder<List<dynamic>>(
                    future: _getListTile(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        messageController.radioListTiles.clear();
                        for (var i = 0; i < snapshot.data!.length; i++) {
                          Map<String, dynamic> item = snapshot.data![i];
                          messageController.radioListTiles.add(customRadioListTile(item));
                        }
                        return ListView(
                          shrinkWrap: true,
                          children: messageController.radioListTiles,
                        );
                      } else if (snapshot.hasError) {
                        return Text("${snapshot.error}");
                      }
                      return Center(child: CircularProgressIndicator());
                    },
                  )
                ],
              ),
            ),
          );
        }),
        Expanded(child: 
          FutureBuilder<void>(
            future: _getListTile().then((value) => print("MessageView first build done.")),
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ));
              } else if (snapshot.hasError) {
                return const Center(child: Text('Failed to load messages.'));
              } else {
                return Obx(() => MessageView(key: ValueKey(DateTime.now()), conversation_id: messageController.conversation_id.value));
              }
            },
          )          
        ),
      ],
    );
  }
}


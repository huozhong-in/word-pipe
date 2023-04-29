import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/MessageController.dart';
import 'package:wordpipe/MessageView.dart';


class ConversationView extends StatelessWidget {
  ConversationView({super.key});

  final Controller c = Get.find<Controller>();
  final MessageController messageController = Get.find<MessageController>();
  final SettingsController settingsController = Get.find<SettingsController>();

  @override
  Widget build(BuildContext context) {

    Future<List<ListTile>> getListTiles(BuildContext context) async {
      print("getListTiles");
      List<ListTile> _listTiles = [];
      if (settingsController.freeChatMode.value){
        // 如果没有开启Free chat mode，则不需要请求数据库
        String curr_user = await c.getUserName();
        List<dynamic> _conversationList = await messageController.conversation_R(curr_user);
        for (var i = 0; i < _conversationList.length; i++) {
          Map<String,dynamic> item = _conversationList[i];
          _listTiles.add(
            ListTile(
              leading: Icon(Icons.message_rounded,size: 20),
              title: Text(item['conversation_name'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14)),
              minLeadingWidth: 0,
              minVerticalPadding: 0,
              contentPadding: EdgeInsets.fromLTRB(2, 0, 0, 0),
              horizontalTitleGap: 4,
              onTap: () => {
                print(item['pk_conversation'].toString()),
                messageController.conversation_id = item['pk_conversation'],
              },
            ),
          );
        }
      }
      return _listTiles;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() { 
          return Visibility(
            visible: settingsController.freeChatMode.value,
            child: Container(
              width: 160,
              margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
              constraints: BoxConstraints(
                maxWidth: 160,
                minWidth: 160,
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
                      title: Text('新话题', style: TextStyle(fontSize: 14)),
                      minLeadingWidth: 0,
                      minVerticalPadding: 0,
                      onTap: () async {
                        messageController.messages.clear();
                        messageController.messsage_view_first_build = true;
                        messageController.conversation_id.value = -2; // 强制MessageView刷新
                        messageController.conversation_id.value = -1;
                        messageController.commentFocus.requestFocus();
                      },
                    ),
                  ),
                  Divider(),
                  FutureBuilder<List<ListTile>>(
                    future: getListTiles(context),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ListView(
                          shrinkWrap: true,
                          children: snapshot.data!,
                        );
                      } else if (snapshot.hasError) {
                        return Text("${snapshot.error}");
                      }
                      return Center(child: CircularProgressIndicator());
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        Expanded(child: 
          FutureBuilder<void>(
            future: getListTiles(context).then((value) => print("getListTiles done")),
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
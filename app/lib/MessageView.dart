import 'package:wordpipe/MessageModel.dart';
import 'package:wordpipe/config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/MessageController.dart';
import 'package:wordpipe/message_bubble.dart';

// ignore: must_be_immutable
class MessageView extends StatelessWidget {
  MessageView({required Key key }) : super(key: key);
  
  final Controller c = Get.find();
  final MessageController messageController = Get.find();
  
  @override
  Widget build(BuildContext context) {
    
    // void _scrollToBottom() {
    //   _scrollController.animateTo(
    //     _scrollController.position.minScrollExtent,
    //     duration: const Duration(milliseconds: 300),
    //     curve: Curves.easeOut,
    //   );
    // }

    Future<void> getChatHistory() async {
      c.getUserName().then((user_name){
        if (user_name != ""){
          messageController.handleSSE(user_name);
          if (messageController.messsage_view_first_build == true){
            Future<int> _lastSegmentBeginId = messageController.chatHistory(user_name, messageController.lastSegmentBeginId);
            // Welcome message to new user!
            _lastSegmentBeginId.then((lastId) => {
              if (lastId == -1){
                messageController.addMessage(
                  MessageModel(
                    dataList: RxList(['“Huh? Whoa, whoa, whoa, whoa, whoa.”']), 
                    type: WordPipeMessageType.text, 
                    username: 'Jarvis', 
                    uuid: 'b811abd7-c0bb-4301-9664-574d0d8b11f8',
                    createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                    key: UniqueKey(), 
                  )
                )
              }
            });
          }
        }
      });
    }
    
    Widget _buildListView() {
      return Obx(() {
        return ListView.builder(
        controller: messageController.scrollController,
        itemCount: messageController.messages.length,
        itemBuilder: (context, index) {
          MessageModel message = messageController.messages[index];
          // print("_buildListView(index ${index}): ${message.username} ${message.dataList} ${message.type}");
          return MessageBubble(
            key: message.key,
            sender: message.username,
            sender_uuid: message.uuid,
            dataList: message.dataList,
            type: message.type,
          );
        },
        shrinkWrap: true,
        reverse: true,
      );
    }); 
    }

    return FutureBuilder<void>(
      future: getChatHistory(),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Failed to load messages.'));
        } else {
          return _buildListView();
        }
      },
    );
  }
}
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
  RxBool newMessageArrived = false.obs;

  @override
  Widget build(BuildContext context) {
    
    Future<void> getChatHistory() async {
      c.getUserName().then((user_name){
        if (user_name != ""){
          messageController.handleSSE(user_name);
          // 检查是不是第一次打开MessageView
          if (messageController.messsage_view_first_build == true){
            // 从数据库里拿最新的一些消息
            Future<int> _lastSegmentBeginId = messageController.chatHistory(user_name, messageController.lastSegmentBeginId);
            // Welcome message
            _lastSegmentBeginId.then((lastId) => {
              if (lastId == -1){
                // -1意味着没有任何历史消息，是新用户，发送欢迎信息
                messageController.addMessage(
                  MessageModel(
                    dataList: RxList(
                      [
                        'Hi, I am Jasmine. I am here to help you. Try to input a word!',
                        '你好，我是Jasmine。希望我能在外语学习方面帮到你。试着输入一个单词吧！'
                      ]
                    ), 
                    type: WordPipeMessageType.autoreply, 
                    username: 'Jasmine', 
                    uuid: 'b811abd7-c0bb-4301-9664-574d0d8b11f8',
                    createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                    key: UniqueKey(), 
                  )
                )
              }else{
                // 欢迎老用户回来
                messageController.addMessage(
                  MessageModel(
                    dataList: RxList(
                      [
                        'Welcome back! Ask me some words or sentences :)',
                        '欢迎回来！问我一些单词或句子吧 :)'
                      ]
                    ), 
                    type: WordPipeMessageType.autoreply, 
                    username: 'Jasmine', 
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

      // 判断有新消息过来，而且滚动条不在最底端，则显示一个提示气泡，点击后滚动到最底端。因为dataList是一个RxList，所以只要dataList有变化，就会触发这个“滚动条位置判定”函数。
      // messageController.messages.listen((messages) {
      //   messageController.messages.listen((messages) {
         // TODO 被触发2000多次，这里有性能问题
      //     // print(messages.length);
      //     // if (!messageController.scrollController.position.atEdge && messageController.scrollController.offset != messageController.scrollController.position.minScrollExtent) {
      //     //   newMessageArrived.value = true;
      //     // }
      //   });
      //   // if (messageController.scrollController.offset != messageController.scrollController.position.minScrollExtent){
      //   //   newMessageArrived.value = true;
      //   // }
      // });

      return Obx(() {
        return Stack(
          children: [
            ListView.builder(
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
            ),
            Visibility(
              visible: newMessageArrived.value,
              child: Positioned(
                left: Get.width / 3,
                bottom: 0,
                child: Container(
                  height: 30,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.only(bottom: 5),
                  // button with text and icon
                  child: TextButton.icon(
                    label: Text('New Message Arrived!', style: TextStyle(color: Colors.black)),
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: Icon(Icons.keyboard_double_arrow_down_rounded, color: Colors.black),
                    ),
                    onPressed: () {
                      messageController.scrollController.animateTo(
                        messageController.scrollController.position.minScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                      // hide self
                      newMessageArrived.value = false;
                    },
                  )
                ),
              ),
            ),
          ],
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
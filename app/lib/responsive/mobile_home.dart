import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wordpipe/custom_widgets.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/MessageView.dart';
import 'package:wordpipe/user_profile.dart';
import 'package:wordpipe/MessageController.dart';
import 'package:wordpipe/settings.dart';
import 'package:wordpipe/about_us.dart';
import 'package:record/record.dart';
import 'dart:async';
import '../config.dart';

// ignore: must_be_immutable
class MobileHome extends StatelessWidget {
  MobileHome({super.key});

  final Controller c = Get.find();
  final MessageController messageController = Get.find<MessageController>();
  final SettingsController settingsController = Get.find<SettingsController>();
  late String _username = "";
  final TextEditingController _textController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  final TextEditingController conversationNameController = TextEditingController();
  

  Future<String> _getUserName() async {
    _username = await c.getUserName();
    return _username;
  }

  Future<List<dynamic>> _getListTile() async {
    return messageController.conversation_R(await c.getUserName());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: messageController.scaffoldKey,
        appBar: AppBar(
          title: Obx(() {
            return Text(
              messageController.selectedConversationName.value, 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[900]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );                                          
          }),
          centerTitle: true,
          backgroundColor: Color.fromARGB(255, 59, 214, 157),//Colors.greenAccent[100],
          elevation: 5,
          scrolledUnderElevation: 5,
          automaticallyImplyLeading: true,
          actions: [
            Obx(() {
              return DropdownButton(
                icon: Icon(Icons.more_vert),
                // iconDisabledColor: Colors.grey[100],
                items: [
                  DropdownMenuItem(
                    enabled: messageController.conversation_id.value > 0,
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: messageController.conversation_id.value > 0?Colors.black:Colors.grey,),
                        SizedBox(width: 10),
                        Text('修改名称', style: TextStyle(fontSize: 14, color: messageController.conversation_id.value > 0?Colors.black:Colors.grey)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    enabled: messageController.conversation_id.value > 0,
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: messageController.conversation_id.value > 0?Colors.black:Colors.grey,),
                        SizedBox(width: 10),
                        Text('删除话题', style: TextStyle(fontSize: 14, color: messageController.conversation_id.value > 0?Colors.black:Colors.grey)),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == 'edit') {
                    // show a dialog for modify messageControll.seletedConversationName
                    conversationNameController.text = messageController.selectedConversationName.value;
                    Get.defaultDialog(
                      title: '编辑',
                      content: TextField(
                        controller: conversationNameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '话题名称',
                        ),
                        maxLength: 50,
                      ),
                      textConfirm: '保存',
                      textCancel: '取消',
                      confirmTextColor: Colors.white,
                      buttonColor: Colors.green,
                      onConfirm: () async {
                        // update conversation name
                        if (await messageController.updateConversationName(messageController.conversation_id.value, conversationNameController.text)){
                          Get.back();
                        }else{
                          print('update error');
                        }
                      },
                    );
                  } else if (value == 'delete') {
                    // show a dialog for delete messageControll.radioListTile current item
                    Get.defaultDialog(
                      title: '删除话题',
                      content: Text('你确定要删除当前话题记录吗?'),
                      textConfirm: '删除',
                      textCancel: '取消',
                      confirmTextColor: Colors.white,
                      buttonColor: Colors.red,
                      onConfirm: () async {
                        // delete conversation
                        if (await messageController.deleteConversation(messageController.conversation_id.value)){
                          Get.back();
                          if (messageController.scaffoldKey.currentState!.hasDrawer){
                            messageController.scaffoldKey.currentState!.openDrawer();
                          }
                        }else{
                          print('delete error');
                        }
                      },
                    );
                  }
                },
              );
            },)
          ],
        ),
        resizeToAvoidBottomInset : true,
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                    child: RichText(
                      text: TextSpan(
                        text: 'WordPipe',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.black54,
                          fontSize: 20,
                          fontFamily: 'SofadiOne',
                          fontWeight: FontWeight.w600),
                        children: <TextSpan>[
                          TextSpan(
                            text: '  alpha',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.blue,
                              fontSize: 12),
                          ),
                        ],
                      )
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.account_circle),
                  title: Text('我的'),
                  onTap: () => Get.offAll(() => UserProfile()),
                ),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('设置'),
                  onTap: () => Get.offAll(() => Settings()),
                ),
                ListTile(
                  leading: Icon(Icons.info),
                  title: Text('关于WordPipe'),
                  onTap: () => Get.offAll(() => AboutUs()),
                ),
                Divider(),
                Obx(() {
                  return SwitchListTile(
                    activeColor: Colors.green[600],
                    activeTrackColor: Colors.green[100],
                    inactiveThumbColor: Colors.green[200],
                    inactiveTrackColor: Colors.green[100],
                    title: Text('连续对话模式', style: TextStyle(fontSize: 14)), 
                    subtitle: Text('会员专享', style: TextStyle(fontSize: 12, color: Colors.blue)),
                    value: settingsController.freeChatMode.value,
                    onChanged: ((bool value) async {
                      if (value==true){
                        int premiumType = await c.getPremium();
                        if (premiumType != 0) {
                          settingsController.toggleFreeChatMode(value);
                          messageController.messages.clear();
                          messageController.messsage_view_first_build = true;
                          messageController.conversation_id.value = -1;
                        } else {
                          if (settingsController.openAiApiKey.value != '') {
                            settingsController.toggleFreeChatMode(value);
                            messageController.messages.clear();
                            messageController.messsage_view_first_build = true;
                            messageController.conversation_id.value = -1;
                          } else {
                            settingsController.freeChatMode.value = false;
                            customSnackBar(title: "错误提示", content: "请设置自己的OpenAI API key或者升级为付费会员.");
                          }
                        }
                      }else{
                        // 重新加载非free-chat聊天记录
                        settingsController.toggleFreeChatMode(value);
                        messageController.messages.clear();
                        messageController.lastSegmentBeginId = 0;
                        messageController.messsage_view_first_build = true;
                        messageController.conversation_id.value = 0;
                        messageController.selectedConversationName.value = '';
                      }
                    }),
                  );                    
                },),
                Obx(() {
                  if (settingsController.freeChatMode.value){
                    return FutureBuilder<List<dynamic>>(
                      future: _getListTile(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          messageController.radioListTiles.clear();
                          for (var i = 0; i < snapshot.data!.length; i++) {
                            Map<String, dynamic> item = snapshot.data![i];
                            messageController.radioListTiles.add(customRadioListTile(item));
                          }
                          return Column(
                            children: [
                              Tooltip(
                                message: '开个新话题',
                                child: ListTile(
                                  tileColor: Color.fromARGB(255, 94, 211, 168).withOpacity(0.5),
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
                                    if (messageController.scaffoldKey.currentState != null && messageController.scaffoldKey.currentState!.hasDrawer && messageController.scaffoldKey.currentState!.isDrawerOpen){
                                      messageController.scaffoldKey.currentState!.closeDrawer();
                                    }
                                    messageController.commentFocus.requestFocus();
                                  },
                                ),
                              ),
                              ...messageController.radioListTiles
                            ],
                          );
                        } else if (snapshot.hasError) {
                          return Text("${snapshot.error}");
                        }
                        return Center(child: CircularProgressIndicator());
                      },
                    );
                  }else{
                    return Container();
                  }
                }),
              ],
            ),
          ),
        ),
        body: Center(
          child: Column(
            children: [
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
              Container(
                margin: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 5,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: _myTextFild(context),
                      )
                    ),
                    Container(
                      width: 45,
                      height: 45,
                      margin: EdgeInsets.only(left: 5),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 59, 214, 157),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            ),
                          padding: const EdgeInsets.all(0),
                        ),
                        onPressed: () {
                          _handleSubmitted(_textController.text);
                          _commentFocus.unfocus();
                        },
                        child: const Icon(Icons.send_rounded, color: Colors.black54, size: 24),
                      )
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _myTextFild(BuildContext context){
    return TextField(
      focusNode: _commentFocus,
      // autofocus: true,
      controller: _textController,
      textInputAction: TextInputAction.newline,
      maxLines: 1,
      minLines: 1,
      decoration: InputDecoration(
        hintText: '输入单词或句子',
        hintStyle: TextStyle(color: Colors.grey),
        prefixIcon: IconButton(
            color: Colors.grey,
            hoverColor: Colors.black54,
            onPressed: () async {
              final record = Record();
              if (await record.hasPermission()) {
                // Directory temporaryDirectory = await getTemporaryDirectory();
                // String voiceFilePath = temporaryDirectory.path + '/voice.m4a';
                // log(voiceFilePath);
                // await record.start(
                //   path: voiceFilePath,
                //   encoder: AudioEncoder.aacLc,
                //   bitRate: 128000,
                //   samplingRate: 44100,
                // );
              }
            }, 
            icon: const Icon(Icons.mic_rounded)
          ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10),),
          borderSide: BorderSide(
            color: Colors.grey,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10),),
          borderSide: BorderSide(
            color: Colors.grey,
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10),),
          borderSide: BorderSide(
            color: Colors.redAccent,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.redAccent,
            width: 1,
          ),
        ),
      ),
    );
  }

  void _handleSubmitted(String text) async {
    if(text.trim() == "")
      return;
    String username = await _getUserName();
    if( username == "")
      return;
    // 向服务端发送消息
    // 如果conversation_id == -1，说明是新话题，需要先创建话题，话题ID是服务端生成返回
    if (messageController.conversation_id.value == -1){
      messageController.conversation_id.value = await messageController.conversation_CUD(_username, "create", messageController.conversation_id.value);
    }
    Map<String, dynamic>  ret = await messageController.new_chat(_username, text.trim(), messageController.conversation_id.value);
    if(ret['errcode'] as int == 0){
      _textController.clear();
      if (settingsController.freeChatMode.value == true){
        messageController.freeChat('gpt-3.5-turbo', messageController.conversation_id.value, text);
      }
    }else{
      customSnackBar(title: "错误", content: ret['errmsg'] as String);
    }   
  }
}
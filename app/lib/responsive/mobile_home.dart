import 'package:wordpipe/config.dart';
import 'package:wordpipe/responsive/mobile_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/MessageView.dart';
import 'package:wordpipe/user_profile.dart';

// ugly code
import 'package:wordpipe/MessageController.dart';
import 'package:wordpipe/MessageModel.dart';

class MobileHome extends StatelessWidget {
  MobileHome({super.key});

  final Controller c = Get.find();
  final MessageController messageController = Get.put(MessageController());
  final TextEditingController _textController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            text: 'Word Pipe',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.black54,
              fontSize: 20,
              fontFamily: GoogleFonts.getFont('Comfortaa').fontFamily,
              fontWeight: FontWeight.w600),
            children: <TextSpan>[
              TextSpan(
                text: '  alpha',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.black54,
                  fontSize: 12),
              ),
            ],
          )
        ),
        centerTitle: true,
        backgroundColor: Colors.greenAccent[100],
        automaticallyImplyLeading: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.7),
              ),
              child: Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            // ListTile(
            //   leading: Icon(Icons.message),
            //   title: Text('Messages'),
            // ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Profile'),
              onTap: () => Get.offAll(UserProfile()),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('About Us'),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                child: 
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.topCenter,
                    color: Colors.white24,
                    child: MessageView(key: ValueKey(DateTime.now()))
                  )
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(5, 0, 5, 5),
              padding: const EdgeInsets.all(10),
              // height: 100,
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
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: Colors.green[400],
                    onPressed: () {
                      _handleSubmitted(_textController.text);
                      _commentFocus.requestFocus();
                    },
                    hoverColor: Colors.black54,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _myTextFild(BuildContext context){
    return TextField(
      focusNode: _commentFocus,
      autofocus: true,
      controller: _textController,
      textInputAction: TextInputAction.newline,
      style: TextStyle(fontWeight: FontWeight.bold),
      maxLines: 1,
      minLines: 1,
      decoration: InputDecoration(
        hintText: 'ask some questions',
        hintStyle: TextStyle(color: Colors.grey),
        prefixIcon: IconButton(
            color: Colors.grey,
            hoverColor: Colors.black54,
            onPressed: () {
              // messageController.getChatCompletion('gpt-3.5-turbo', 'What is hallucinate?');
              customSnackBar(title: "not open yet", content: "not open yet");
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

  void _handleSubmitted(String text) {
    if(text.trim() == ""){
      return;
    }
    // 向服务端发送消息，如果返回http code 204，则将消息添加到消息列表中
    c.getUserName().then((_username){
      Future<bool> r = c.chat(_username, text.trim());
      r.then((ret){
        if(ret == true){
          _textController.clear();
          _commentFocus.unfocus();
          c.getUUID().then((_uuid){
            messageController.addMessage(
              MessageModel(
                dataList: RxList([text.trim()]), 
                type: WordPipeMessageType.text, 
                username: _username, 
                uuid: _uuid,
                createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                key: UniqueKey(), 
              )
            );
            if(text.trim().substring(0,1) != "/"){
              messageController.getChatCompletion('gpt-3.5-turbo', text.trim());
            }
          });
        }else{
          customSnackBar(title: "Error", content: "Failed to send message, please Sign In again.");
          // 三秒后跳转到登录页面
          Future.delayed(Duration(seconds: 3), () {
            Get.offAll(MobileSignIn());
          });
        }
      });
    });
  }
}
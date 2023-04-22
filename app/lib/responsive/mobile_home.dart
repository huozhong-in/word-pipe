import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wordpipe/config.dart';
import 'package:wordpipe/responsive/mobile_sign_in.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/MessageView.dart';
import 'package:wordpipe/user_profile.dart';
import 'package:wordpipe/MessageController.dart';
// import 'package:wordpipe/MessageModel.dart';

class MobileHome extends StatelessWidget {
  MobileHome({super.key});

  final Controller c = Get.find();
  final MessageController messageController = Get.find<MessageController>();
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
      resizeToAvoidBottomInset : true,
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
              title: Text('About WordPipe'),
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
                  Container(
                          width: 45,
                          height: 40,
                          margin: EdgeInsets.only(left: 5),
                          decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.green[900],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                                ),
                              padding: const EdgeInsets.all(0),
                            ),
                            onPressed: () {
                              _handleSubmitted(_textController.text);
                              _commentFocus.unfocus();
                            },
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                          )
                        )
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
      maxLines: 1,
      minLines: 1,
      decoration: InputDecoration(
        hintText: '输入单词或句子',
        hintStyle: TextStyle(color: Colors.grey),
        prefixIcon: IconButton(
            color: Colors.grey,
            hoverColor: Colors.black54,
            onPressed: () {
              customSnackBar(title: "Info", content: "not open yet");
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
    // 向服务端发送消息
    c.getUserName().then((_username){
      Future<bool> r = c.chat(_username, text.trim());
      r.then((ret){
        if(ret == true){
          _textController.clear();
          _commentFocus.unfocus();
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
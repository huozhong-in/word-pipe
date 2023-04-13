import 'package:app/config.dart';
import 'package:app/responsive/desktop_home.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:app/controller.dart';
import 'package:app/responsive/mobile_sign_in.dart';
import 'package:app/MessageController.dart';
import 'package:flutter_svg/flutter_svg.dart';



// ignore: must_be_immutable
class UserProfile extends StatelessWidget {
  UserProfile({Key? key}) : super(key: key);
  final Controller c = Get.find();
  final MessageController messageController = Get.put(MessageController());
  late String username = "";

  @override
  Widget build(BuildContext context) {
    Future<String> myId = c.getUserName();
    myId.then((value) => username = value);

    return FutureBuilder(
      future: checkUserLogin(), // 调用异步方法检查用户是否登录
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasError) {
            return Text('Error initializing.');
          } else if (snapshot.connectionState ==
              ConnectionState.done) {
            if (username != "") {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  home: Scaffold(
                    appBar: AppBar(
                      title: Text('User Profile'),
                      centerTitle: true,
                      backgroundColor: Colors.green.withOpacity(0.6),
                      automaticallyImplyLeading: false,
                      leading: IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                          Get.offAll(DesktopHome());
                        },
                      )
                    ),
                    body: Center(
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          Text('User ID: $username'),
                          SizedBox(height: 20),                          
                          Container(
                            width: 200,
                            height: 200,
                            // color: Colors.black12,
                            margin: const EdgeInsets.only(left: 8),
                            child: SvgPicture.network(
                              "${HTTP_SERVER_HOST}/${AVATAR_FILE_DIR}/${username}",
                              height: 200,
                              width: 200,
                              semanticsLabel: 'user avatar',
                              placeholderBuilder: (BuildContext context) => Container(
                                  padding: const EdgeInsets.all(40.0),
                                  child: const CircularProgressIndicator()),
                              )
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              await c.signout();
                              // 登出后清空消息列表
                              messageController.messages.clear();
                              messageController.closeSSE();
                              Get.offAll(MobileSignIn());
                            },
                            child: Text('Sign Out'),
                          ),
                        ],
                      )
                    ),
                  )
                );
            }else{
              return MaterialApp(
                home: MobileSignIn(),
              );
            }
          }
        return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  CustomColors.splashStart,
                  CustomColors.splashEnd,
                ],
              ),
            ),
            child: SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white,
                ),
              ),
            ),
          );
      },
    );
  }

  Future<bool> checkUserLogin() async {
    // 异步方法检查用户登录状态，返回true表示已登录，false表示未登录
    Future<bool> result = Future.value(false);
    if (username == "") {
      result = Future.value(false);
    } else {
      result = Future.value(true);
    }    
    return result;
  }
}

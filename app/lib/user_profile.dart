import 'package:app/config.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:app/controller.dart';
import 'package:app/sign_in.dart';




// ignore: must_be_immutable
class UserProfile extends StatelessWidget {
  UserProfile({Key? key}) : super(key: key);
  final Controller c = Get.find();
  late String userId = DEFAULT_AYONYMOUS_USER_ID;

  @override
  Widget build(BuildContext context) {
    Future<String> myId = c.getUserId();
    myId.then((value) => userId = value);

    return FutureBuilder(
      future: checkUserLogin(), // 调用异步方法检查用户是否登录
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasError) {
            return Text('Error initializing.');
          } else if (snapshot.connectionState ==
              ConnectionState.done) {
            if (userId != DEFAULT_AYONYMOUS_USER_ID) {
                return MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(
                      title: Text('User Profile'),
                      centerTitle: true,
                      backgroundColor: Colors.green,
                    ),
                    body: Center(
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          Text('User ID: $userId'),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              await c.signout();
                              Get.offAll(SignIn());
                            },
                            child: Text('Sign Out'),
                          ),],
                      )
                    ),
                  )
                );
            }else{
              return MaterialApp(
                home: SignIn(),
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
    if (userId == DEFAULT_AYONYMOUS_USER_ID) {
      result = Future.value(false);
    } else {
      result = Future.value(true);
    }    
    return result;
  }
}

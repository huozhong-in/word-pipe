import 'package:cached_network_image/cached_network_image.dart';
import 'package:wordpipe/config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/MessageController.dart';
import 'package:wordpipe/responsive/responsive_layout.dart';



// ignore: must_be_immutable
class UserProfile extends StatelessWidget {
  UserProfile({Key? key}) : super(key: key);
  final Controller c = Get.find();
  final MessageController messageController = Get.find();
  late String username = "";

  Future<bool> checkUserLogin() async {
    // 异步方法检查用户登录状态，返回true表示已登录，false表示未登录
    Future<String> myId = c.getUserName();
    myId.then((value) => username = value);
    if (username == "") {
      return Future.value(false);
    }
    return Future.value(true);    
  }

  @override
  Widget build(BuildContext context) {
    

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
                      title: const Text('User Profile', style: TextStyle(color: Colors.white70, fontSize: 24)),
                      centerTitle: true,
                      backgroundColor: Colors.green.withOpacity(0.6),
                      automaticallyImplyLeading: false,
                      leading: IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                          Get.offAll(ResponsiveLayout());
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
                            width: 100,
                            height: 100,
                            // color: Colors.black12,
                            margin: const EdgeInsets.only(left: 8),
                              
                            child: CachedNetworkImage(
                              imageUrl: "${HTTP_SERVER_HOST}/${AVATAR_FILE_DIR}/${username}",
                              imageBuilder: (context, imageProvider) => Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.scaleDown,
                                  ),
                                ),
                              ),
                              placeholder: (context, url) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.black12,
                                margin: const EdgeInsets.only(right: 8),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Icon(Icons.error),
                            )
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              bool r = await c.signout();
                              if (r){
                                // 登出后清空消息列表
                                messageController.messages.clear();
                                messageController.closeSSE();
                                messageController.messsage_view_first_build = true;
                                messageController.conversationNameMap.clear();
                                messageController.lastSegmentBeginId = 0;
                                messageController.selectedConversationName.value = "";
                                messageController.conversation_id.value = 0;
                                Get.offAll(ResponsiveLayout());
                              }else{
                                Get.snackbar("Error", "Sign out failed");
                              }
                            },
                            child: Text('Sign Out'),
                          ),
                        ],
                      )
                    ),
                  )
                );
            }else{
              Get.offAll(ResponsiveLayout());
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

  
}

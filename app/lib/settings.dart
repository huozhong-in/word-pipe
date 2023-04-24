import 'package:flutter/material.dart';
import 'package:wordpipe/config.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/responsive/responsive_layout.dart';
import 'package:get/get.dart';


// ignore: must_be_immutable
class Settings extends StatelessWidget {
  Settings({Key? key}) : super(key: key);
  final Controller c = Get.find();
  final SettingsController settingsController = Get.find<SettingsController>();
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
          } else if (snapshot.connectionState == ConnectionState.done) {
            if (username != "") {
                return Scaffold(
                    appBar: AppBar(
                      title: Text('Settings'),
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
                          Text('Chat conversion font size', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          SizedBox(height: 20),                          
                          Container(
                            // width: 200,
                            // height: 200,
                            // color: Colors.black12,
                            margin: const EdgeInsets.all(20),
                            child: Obx(() {  
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Text('Small'),
                                      Expanded(
                                        child: Slider(
                                            value: settingsController.fontSizeConfig.value,
                                            min: 12,
                                            max: 24,
                                            divisions: 12,
                                            label: settingsController.fontSizeConfig.value.round().toString(),
                                            activeColor: Colors.green[600],
                                            onChanged: (double value) {
                                              settingsController.setFontSize(value);
                                            },
                                          )
                                      ),
                                      Text('Large'),
                                    ],
                                  ),
                                  Text('Current font size: ' + settingsController.fontSizeConfig.value.round().toString()),
                                ],
                              );
                            },)
                          ),
                          SizedBox(height: 20,),
                          Divider(height: 1, thickness: 1, color: Colors.black12, indent: 20, endIndent: 20,),
                          SizedBox(height: 20,),
                          Text('When Jasmine answer question, use', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          SizedBox(height: 20),
                          Container(
                            margin: const EdgeInsets.all(20),
                            child: Obx(() {  
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile(
                                          value: 0,
                                          activeColor: Colors.green[600],
                                          groupValue: settingsController.aiAssistantLanguage.value,
                                          title: Text('English'),
                                          onChanged: (value) {
                                            settingsController.setAiAssistantLanguage(value as int);
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile(
                                          value: 1,
                                          activeColor: Colors.green[600],
                                          groupValue: settingsController.aiAssistantLanguage.value,
                                          title: Text('中文'),
                                          onChanged: (value) {
                                            settingsController.setAiAssistantLanguage(value as int);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text('Current language: ' + (settingsController.aiAssistantLanguage.value == 0 ? 'English' : '中文')),
                                  SizedBox(height: 20,),
                                  Divider(height: 1, thickness: 1, color: Colors.black12, indent: 20, endIndent: 20,),
                                  SizedBox(height: 20,),
                                  Text('When Jasmine make new sentences, can use word\'s various forms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                                  SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile(
                                          value: true,
                                          activeColor: Colors.green[600],
                                          groupValue: settingsController.useOtherWordForms.value,
                                          title: Text('Yes'),
                                          onChanged: (value) {
                                            settingsController.toggleUseOtherWordForms(value as bool);
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile(
                                          value: false,
                                          activeColor: Colors.green[600],
                                          groupValue: settingsController.useOtherWordForms.value,
                                          title: Text('No'),
                                          onChanged: (value) {
                                            settingsController.toggleUseOtherWordForms(value as bool);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },)
                          ),
                        ],
                      )
                    ),
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
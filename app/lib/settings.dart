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
  TextEditingController openAiApiKeyController = TextEditingController();

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
                    title: const Text('参数设置', style: TextStyle(color: Colors.white, fontSize: 24)),
                    centerTitle: true,
                    backgroundColor: Color.fromARGB(255, 59, 214, 157),
                    automaticallyImplyLeading: false,
                    toolbarHeight: 70,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back, size: 30,),
                      onPressed: () {
                        Get.offAll(() => ResponsiveLayout());
                      },
                    )
                  ),
                  body: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          Text('聊天字体尺寸', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
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
                                      Text('小'),
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
                                      Text('大'),
                                    ],
                                  ),
                                  Text('当前尺寸: ' + settingsController.fontSizeConfig.value.round().toString()),
                                ],
                              );
                            },)
                          ),
                          SizedBox(height: 20,),
                          Divider(height: 1, thickness: 1, color: Colors.black12, indent: 20, endIndent: 20,),
                          SizedBox(height: 20,),
                          Text('当Jasmine回答问题时，使用', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
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
                                          title: Text('汉语'),
                                          onChanged: (value) {
                                            settingsController.setAiAssistantLanguage(value as int);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text('当前语言: ' + (settingsController.aiAssistantLanguage.value == 0 ? 'English' : '汉语')),
                                  SizedBox(height: 20,),
                                  Divider(height: 1, thickness: 1, color: Colors.black12, indent: 20, endIndent: 20,),
                                  SizedBox(height: 20,),
                                  Text('当Jasmine造句时，可以使用单词的多种形态', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                                  SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile(
                                          value: true,
                                          activeColor: Colors.green[600],
                                          groupValue: settingsController.useOtherWordForms.value,
                                          title: Text('是'),
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
                                          title: Text('否'),
                                          onChanged: (value) {
                                            settingsController.toggleUseOtherWordForms(value as bool);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20,),
                                  Divider(height: 1, thickness: 1, color: Colors.black12, indent: 20, endIndent: 20,),
                                  SizedBox(height: 20,),
                                  Text('使用你私有的OpenAI API key', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                                  SizedBox(height: 20),
                                  Container(
                                    margin: const EdgeInsets.all(20),
                                    child: Obx(() {
                                      return Column(
                                        children: [
                                          TextField(
                                            controller: openAiApiKeyController,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                              labelText: '这里粘贴OpenAI API key',
                                              labelStyle: TextStyle(
                                                color: Colors.black54,
                                              ),
                                              prefixIcon: Icon(Icons.key),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(10),),
                                                borderSide: BorderSide(
                                                  color: Colors.grey,
                                                  width: 1,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: CustomColors.appBarColor2,
                                                  width: 1,
                                                ),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(10),),
                                                borderSide: BorderSide(
                                                  color: CustomColors.firebaseOrange,
                                                  width: 1,
                                                ),
                                              ),
                                              focusedErrorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: CustomColors.firebaseAmber,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              settingsController.setOpenAiApiKey(value.trim());
                                              if (value.trim() == ''){
                                                settingsController.freeChatMode.value = false;
                                                openAiApiKeyController.text = '';
                                              };
                                            },
                                            // onChanged: () {
                                            //   settingsController.setOpenAiApiKey(openAiApiKeyController.text);
                                            // },
                                          ),
                                          SizedBox(height: 20,),
                                          Text('当前 OpenAI API key: '),
                                          SelectableText(settingsController.openAiApiKey.value),
                                        ],
                                      );
                                    },)
                                  ),
                                  SizedBox(height: 20,),
                                  Divider(height: 1, thickness: 1, color: Colors.black12, indent: 20, endIndent: 20,),
                                  SizedBox(height: 20,),
                                  Text('中英文混合句子的朗读者', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                                  SizedBox(height: 20),
                                  RadioListTile(
                                    title: Text('Xiaoxiao (zh-CN)'),
                                    value: "zh-CN-XiaoxiaoNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoiceZhEn.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoiceZhEn(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Xiaoyi (zh-CN)'),
                                    value: "zh-CN-XiaoyiNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoiceZhEn.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoiceZhEn(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('HiuGaai (zh-HK)'),
                                    value: "zh-HK-HiuGaaiNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoiceZhEn.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoiceZhEn(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('HiuMaan (zh-HK)'),
                                    value: "zh-HK-HiuMaanNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoiceZhEn.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoiceZhEn(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('HsiaoChen (zh-TW)'),
                                    value: "zh-TW-HsiaoChenNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoiceZhEn.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoiceZhEn(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('HsiaoYu (zh-TW)'),
                                    value: "zh-TW-HsiaoYuNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoiceZhEn.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoiceZhEn(value as String);
                                    },
                                  ),
                                  SizedBox(height: 20,),
                                  Divider(height: 1, thickness: 1, color: Colors.black12, indent: 20, endIndent: 20,),
                                  SizedBox(height: 20,),
                                  Text('纯英语句子的朗读者', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                                  SizedBox(height: 20),
                                  RadioListTile(
                                    title: Text('Aria (en-US)'),
                                    value: "en-US-AriaNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Ana (en-US)'),
                                    value: "en-US-AnaNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Jenny (en-US)'),
                                    value: "en-US-JennyNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Michelle (en-US)'),
                                    value: "en-US-MichelleNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Natasha (en-AU)'),
                                    value: "en-AU-NatashaNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Clara (en-CA)'),
                                    value: "en-CA-ClaraNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Libby (en-GB)'),
                                    value: "en-GB-LibbyNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Maisie (en-GB)'),
                                    value: "en-GB-MaisieNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Sonia (en-GB)'),
                                    value: "en-GB-SoniaNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Yan (en-HK)'),
                                    value: "en-HK-YanNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Emily (en-IE)'),
                                    value: "en-IE-EmilyNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('NeerjaExpressive (en-IN)'),
                                    value: "en-IN-NeerjaExpressiveNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Nerrja (en-IN)'),
                                    value: "en-IN-NeerjaNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Asilia (en-KE)'),
                                    value: "en-KE-AsiliaNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Ezinne (en-NG)'),
                                    value: "en-NG-EzinneNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Molly (en-NZ)'),
                                    value: "en-NZ-MollyNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Rosa (en-PH)'),
                                    value: "en-PH-RosaNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Luna (en-SG)'),
                                    value: "en-SG-LunaNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Imani (en-TZ)'),
                                    value: "en-TZ-ImaniNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  RadioListTile(
                                    title: Text('Leah (en-ZA)'),
                                    value: "en-ZA-LeahNeural", 
                                    activeColor: Colors.green[600],
                                    groupValue: settingsController.aiAssistantTtsVoice.value, 
                                    onChanged: (value) {
                                      settingsController.setAiAssistantTtsVoice(value as String);
                                    },
                                  ),
                                  SizedBox(height: 20,),
                                  Divider(height: 1, thickness: 1, color: Colors.black12, indent: 20, endIndent: 20,),
                                  SizedBox(height: 20,),
                                  Text('Jasmine的语速调节 (%)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                                  SizedBox(height: 20),                        
                                  Container(
                                    margin: const EdgeInsets.all(20),
                                    child: Obx(() {  
                                      return Column(
                                        children: [
                                          Row(
                                            children: [
                                              Text('慢'),
                                              Expanded(
                                                child: Slider(
                                                    value: settingsController.aiAssistantTtsRate.value.toDouble() ,
                                                    min: -20,
                                                    max: 20,
                                                    divisions: 4,
                                                    label: settingsController.aiAssistantTtsRate.value.round().toString(),
                                                    activeColor: Colors.green[600],
                                                    onChanged: (double value) {
                                                      settingsController.setAiAssistantTtsRate(value.toInt());
                                                    },
                                                  )
                                              ),
                                              Text('快'),
                                            ],
                                          ),
                                          Text('当前语速: ' + settingsController.aiAssistantTtsRate.value.round().toString() + '%'),
                                        ],
                                      );
                                    },)
                                  )
                                ],
                              );
                            },)
                          ),
                        ],
                      ),
                    )
                  ),
                );
            }else{
              Get.offAll(() => ResponsiveLayout());
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
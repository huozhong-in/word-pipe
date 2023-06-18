import 'package:flutter_desktop_audio_recorder/flutter_desktop_audio_recorder.dart';
import 'package:get/get.dart';
import 'package:wordpipe/config.dart';
import 'package:wordpipe/cache_helper.dart';
import 'dart:async';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer';

class Controller extends GetxController{
  final WordsProvider _wordsProvider = WordsProvider();
  final UserProvider _userProvider = UserProvider();
  
  @override
  void onInit() async{
    super.onInit();
    _userProvider.timeout = Duration(seconds: 45);
  }
  
  Future<Map<String, dynamic>> getSessionData() async{
    return await _userProvider.getLocalStorge();
  }
  Future<String> getUserName() async{
    Map<String, dynamic> sessionData = await _userProvider.getLocalStorge();
    if (sessionData.containsKey('error') == false)
        return sessionData['username'] as String;
    return "";
  }
  Future<String> getUUID() async{
    Map<String, dynamic> sessionData = await _userProvider.getLocalStorge();
    if (sessionData.containsKey('error') == false)
        return sessionData['uuid'] as String;
    return "";
  }
  // Future<String> getAccessToken() async{
  //   Map<String, dynamic> sessionData = await _userProvider.getLocalStorge();
  //   if (sessionData.containsKey('error') == false)
  //       return sessionData['access_token'] as String;
  //   return "";
  // }
  // Future<String> getApiKey() async{
  //   Map<String, dynamic> sessionData = await _userProvider.getLocalStorge();
  //   if (sessionData.containsKey('error') == false)
  //       return sessionData['apiKey'] as String;
  //   return "";
  // }
  // Future<String> getBaseUrl() async{
  //   Map<String, dynamic> sessionData = await _userProvider.getLocalStorge();
  //   if (sessionData.containsKey('error') == false)
  //       return sessionData['baseUrl'] as String;
  //   return "";
  // }
  Future<int> getPremium() async{
    Map<String, dynamic> sessionData = await _userProvider.getLocalStorge();
    if (sessionData.containsKey('error') == false)
        return sessionData['premium'] as int;
    return 0;
  }
  Future<List<dynamic>> searchWords(String word) async{
    return await _wordsProvider.searchWords(word);
  }
  Future<List<dynamic>> getWord(String word) async{
    return await _wordsProvider.getWord(word);
  }
  Future<List<dynamic>> getWords(List<dynamic> word_json_list) async {
    return await _wordsProvider.getWords(word_json_list);
  }
  Future<Map<String ,dynamic>> chat(String username, String message, int conversation_id, String message_key) async{
    return await _userProvider.chat(username, message, conversation_id, message_key);
  }
  Future<Map<String, dynamic>> voiceChat(String username, String message, String fileName, String message_key, int conversation_id) async{
    return await _userProvider.voiceChat(username, message, fileName, message_key, conversation_id);
  }
  Future<Map<String, dynamic>> signin(String username, String password) async{
    return await _userProvider.signin(username, password);
  }
  Future<Map<String, dynamic>> signup(String username, String password) async{
    return await _userProvider.signup(username, password);
  }
  Future<bool> signout() async{
    if(await CacheHelper.hasData('sessionData')){
      await CacheHelper.setData('sessionData', null);
    }
    return true;
  }
  
  Future<String> getWordPipeAppVersion() async {
    if (GetPlatform.isMacOS == false)
      return "0.0.0";
    
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // String appName = packageInfo.appName;
    // String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    // String buildNumber = packageInfo.buildNumber;

    return version; 
  }
}


class WordsProvider extends GetConnect {
  // @override
  // void onInit() async {
  //   String dbPath = await getDatabasesPath();
  //   var db = await openDatabase( dbPath+ 'my_db.db');
  // }

  Future<List<dynamic>> searchWords(String word) async{
    // 检查缓存中是否有数据
    if (await CacheHelper.hasData(word)) {
      // print('Fetching data from cache in searchWords("$word")');
      return await CacheHelper.getData(word) as List<dynamic>;
    }
    // 如果缓存中没有数据，则发起网络请求
    final response = await get('$HTTP_SERVER_HOST/s?k=$word');
    if (response.statusCode == 200) {
      // 解码响应体
      List<dynamic> data = response.body as List<dynamic>;
      // 将数据存储到缓存中
      await CacheHelper.setData(word, data);
      return data;
    } else {
      // throw Exception('Failed to fetch items in searchWords("$word")');
      return [{"result":[]}];
    }
  }

  Future<List<dynamic>> getWord(String word) async{
    if (await CacheHelper.hasData(word)) {
      // print('Fetching data from cache in getWord("$word")');
      return await CacheHelper.getData(word) as List<dynamic>;
    }
    final response = await get('$HTTP_SERVER_HOST/p?k=$word');
    if (response.statusCode == 200) {
      List<dynamic> data = response.body as List<dynamic>;
      await CacheHelper.setData(word, data);
      return data;
    } else {
      return [];
    }
  }

  Future<List<dynamic>> getWords(List<dynamic> word_json_list) async{
    Uri url = Uri.parse('$HTTP_SERVER_HOST/qb');
    // String data = jsonEncode(word_json_list);
    final response = await post(url.toString(), word_json_list);
    
    if (response.statusCode == 200) {
      return response.body as List<dynamic>;
    } else {
      throw Exception('Failed to fetch items');
    }
  }
  
  // GetSocket userMessages() {
  //   return socket('https://yourapi/users/socket');
  // }
}


class UserProvider extends GetConnect {

  Future<Map<String, dynamic>> chat(String username, String message, int conversation_id, String message_key) async{
    // String baseUrl='$HTTP_SERVER_HOST/chat';
    // Uri url = Uri.parse(baseUrl).replace(
    //   queryParameters: <String, String>{
    //     'username': username,
    //     'message': message
    //   },
    // );
    Uri url = Uri.parse('$HTTP_SERVER_HOST/chat');
    Map data = {};
    data['username'] = username;
    data['message'] = message;
    data['conversation_id'] = conversation_id;
    data['message_key'] = message_key;
    String access_token = "";
    if (await CacheHelper.hasData('sessionData')){
      if(await CacheHelper.getData('sessionData') != null){
        Map<String, dynamic> sessionData = await CacheHelper.getData('sessionData');
        access_token = sessionData['access_token'] as String;
      }
    }
    Map<String,String> hs = {};
    if (access_token != ""){
      hs['X-access-token'] = access_token;
    }
    final response = await post(url.toString(), data, headers: hs, contentType: 'application/json');
    if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.body);
      } else {
        log('in controller chat(), response.statusCode !=200 : ${response.body}');
        return {"errcode": 3, "errmsg": response.body};
      }
  }

  Future<Map<String, dynamic>> voiceChat(String username, String message, String fileName, String message_key, int conversation_id) async{
    Uri url = Uri.parse('$HTTP_SERVER_HOST/voicechat');
    String access_token = "";
    String apiKey = '';
    if (await CacheHelper.hasData('sessionData')){
      if(await CacheHelper.getData('sessionData') != null){
        Map<String, dynamic> sessionData = await CacheHelper.getData('sessionData');
        access_token = sessionData['access_token'] as String;
        apiKey = sessionData['apiKey'] as String;
      }
    }
    Map<String,String> hs = {};
    if (access_token != ""){
      hs['X-access-token'] = access_token;
    }

    Directory temporaryDirectory = await getTemporaryDirectory();
    String audio_suffix = "mp3";
    if (GetPlatform.isMacOS || GetPlatform.isIOS)
      audio_suffix = FlutterDesktopAudioRecorder().macosFileExtension;
    else if (GetPlatform.isWindows)
      audio_suffix = FlutterDesktopAudioRecorder().windowsFileExtension;
    String filePath = temporaryDirectory.path + '/' + fileName + '.' + audio_suffix;
    if (!File(filePath).existsSync()) {
      return {"errcode": 4, "errmsg": "file not exist"};
    }
    MultipartFile f = MultipartFile(await File(filePath).readAsBytes(), filename: fileName + '.' + audio_suffix);
    final SettingsController settingsController = Get.find();
    FormData formdata = FormData({
      'username': username,
      'message': message,
      'message_key': message_key,
      'conversation_id':conversation_id,
      'file': f,
      'voice': settingsController.aiAssistantTtsVoiceZhEn.value,
      'rate': settingsController.aiAssistantTtsRate.value,
      'api_key': apiKey,
    });
    final response = await post(url.toString(), formdata, headers: hs, contentType: 'multipart/form-data');
    if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.body);
      } else {
        log('in controller voicechat(), response.statusCode != 200: ${response.body}');
        return {"errcode": 3, "errmsg": response.body};
      }
  }

  Future<Map<String, dynamic>> signin(String username, String password) async{
    Uri url = Uri.parse('$HTTP_SERVER_HOST/user/signin');
    Map data = {};
    data['username'] = username;
    data['password'] = password;
    final response = await post(url.toString(), data);
    Map<String, dynamic> rsp = Map<String, dynamic>.from(response.body);
    if (response.statusCode == 200) {
      await setLocalStorge(username, rsp);
    }
    return rsp;
  }

  Future<Map<String, dynamic>> signup(String username, String password) async{
    Uri url = Uri.parse('$HTTP_SERVER_HOST/user/signup');
    Map data = {};
    data['username'] = username;
    data['password'] = password;
    final response = await post(url.toString(), data);
    if (response.statusCode == 200) {
      Map<String, dynamic> rsp = Map<String, dynamic>.from(response.body);
      await setLocalStorge(username, rsp);
      return rsp;
    } else {
      return {"errcode": 2, "errmsg": response.body};
    }
  }

  Future<void> setLocalStorge(String username, Map<String, dynamic> rsp) async {
    // 将登录后的数据保存在本地
    Map<String, dynamic> sessionData = {};
    sessionData['username'] = username;
    sessionData['access_token'] = rsp['access_token'] as String;
    sessionData['expires_at'] = rsp['expires_at'] as int;
    sessionData['uuid'] = rsp['uuid'] as String;
    sessionData['apiKey'] = decrypt(rsp['apiKey']);
    sessionData['baseUrl'] = rsp['baseUrl'] as String;
    sessionData['premium'] = rsp['premium'] as int;
    await CacheHelper.setData('sessionData', sessionData);
  }

  Future<Map<String, dynamic>> getLocalStorge() async {
    if (await CacheHelper.hasData('sessionData')){
      if(await CacheHelper.getData('sessionData') != null){
        Map<String, dynamic> sessionData = await CacheHelper.getData('sessionData');
        return sessionData;
      }
    }
    return {"error": ""};
  }
}

class SettingsBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SettingsController());
  }
}
class SettingsController extends GetxController {
  late SharedPreferences prefs;
  
  // 关闭英语输入助手
  RxBool englishInputHelperConfig = true.obs;
  // 聊天区域字体大小
  RxDouble fontSizeConfig = 18.0.obs;
  // AI助手回答问题使用语言配置
  RxInt aiAssistantLanguage = 0.obs; // 0-English, 1-Chinese
  // 用单词造句时可以使用这个单词其他词性形式
  RxBool useOtherWordForms = false.obs;
  // AI助手TTS语音发声人选择-纯英语
  RxString aiAssistantTtsVoice = 'en-US-AnaNeural'.obs;
  // AI助手TTS语音发声人选择-中英混合
  RxString aiAssistantTtsVoiceZhEn = 'zh-CN-XiaoxiaoNeural'.obs;
  // AI助手TTS语音语速
  RxInt aiAssistantTtsRate = RxInt(-10);
  // User's OpenAI API Key
  RxString openAiApiKey = ''.obs;

  RxBool freeChatMode = false.obs;
  
  @override
  void onInit() async {
    super.onInit();
    prefs = await SharedPreferences.getInstance();
    englishInputHelperConfig.value = prefs.getBool('englishInputHelperConfig') ?? englishInputHelperConfig.value;
    fontSizeConfig.value = await prefs.getDouble('fontSizeConfig') ?? fontSizeConfig.value;
    aiAssistantLanguage.value = await prefs.getInt('aiAssistantLanguage') ?? aiAssistantLanguage.value;
    useOtherWordForms.value = await prefs.getBool('useOtherWordForms') ?? useOtherWordForms.value;
    aiAssistantTtsVoice.value = await prefs.getString('aiAssistantTtsVoice') ?? aiAssistantTtsVoice.value;
    aiAssistantTtsVoiceZhEn.value = await prefs.getString('aiAssistantTtsVoiceZhEn') ?? aiAssistantTtsVoiceZhEn.value;
    aiAssistantTtsRate.value = await prefs.getInt('aiAssistantTtsRate') ?? aiAssistantTtsRate.value;
    openAiApiKey.value = await prefs.getString('openAiApiKey') ?? openAiApiKey.value;
    freeChatMode.value = await prefs.getBool('freeChatMode') ?? freeChatMode.value;
  }
 
  void toggleEnglishInputHelper(bool value) async {
    englishInputHelperConfig.value = value;
    await prefs.setBool('englishInputHelperConfig', value);
  }
  void setFontSize(double value) async {
    fontSizeConfig.value = value.toDouble();
    await prefs.setDouble('fontSizeConfig', value.toDouble());
  }
  void setAiAssistantLanguage(int value) async {
    aiAssistantLanguage.value = value;
    await prefs.setInt('aiAssistantLanguage', value);
  }
  void toggleUseOtherWordForms(bool value) async {
    useOtherWordForms.value = value;
    await prefs.setBool('useOtherWordForms', value);
  }
  void setAiAssistantTtsVoice(String value) async {
    aiAssistantTtsVoice.value = value;
    await prefs.setString('aiAssistantTtsVoice', value);
  }
  void setAiAssistantTtsVoiceZhEn(String value) async {
    aiAssistantTtsVoiceZhEn.value = value;
    await prefs.setString('aiAssistantTtsVoiceZhEn', value);
  }
  void setAiAssistantTtsRate(int value) async {
    aiAssistantTtsRate.value = value;
    await prefs.setInt('aiAssistantTtsRate', value);
  }
  void setOpenAiApiKey(String value) async {
    openAiApiKey.value = value;
    await prefs.setString('openAiApiKey', value);
  }
  void toggleFreeChatMode(bool value) async {
    freeChatMode.value = value;
    await prefs.setBool('freeChatMode', value);
  }
}

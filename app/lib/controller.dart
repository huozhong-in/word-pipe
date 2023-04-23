import 'package:get/get.dart';
import 'package:wordpipe/config.dart';
import 'package:wordpipe/cache_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';


class Controller extends GetxController{
  final WordsProvider _wordsProvider = WordsProvider();
  final UserProvider _userProvider = UserProvider();
  
  // Future<bool> a() async {
  //   final SharedPreferences prefs = await SharedPreferences.getInstance();
  //   return prefs.containsKey('sessionData');
  // }

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
  Future<String> getAccessToken() async{
    Map<String, dynamic> sessionData = await _userProvider.getLocalStorge();
    if (sessionData.containsKey('error') == false)
        return sessionData['access_token'] as String;
    return "";
  }
  Future<String> getApiKey() async{
    Map<String, dynamic> sessionData = await _userProvider.getLocalStorge();
    if (sessionData.containsKey('error') == false)
        return sessionData['apiKey'] as String;
    return "";
  }
  Future<String> getBaseUrl() async{
    Map<String, dynamic> sessionData = await _userProvider.getLocalStorge();
    if (sessionData.containsKey('error') == false)
        return sessionData['baseUrl'] as String;
    return "";
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
  Future<bool> chat(String username, String message) async{
    return await _userProvider.chat(username, message);
  }
  Future<Map<String, dynamic>> signin(String username, String password) async{
    return await _userProvider.signin(username, password);
  }
  // Future<bool> signup(String username, String password) async{
  //   if (await _userProvider.signup(username, password)){
  //     return true;
  //   }else{
  //     return false;
  //   }
  // }
  Future<bool> signup_with_promo(String username, String password, String promo) async{
    if (await _userProvider.signup_with_promo(username, password, promo)){
      return true;
    }else{
      return false;
    }
  }
  Future<bool> signout() async{
    if(await CacheHelper.hasData('sessionData')){
      await CacheHelper.setData('sessionData', null);
    }
    return true;
  }
  Future<String> imageTypes(String url) async {
    var response = await http.head(Uri.parse(url));
    if (response.statusCode != 200){
      return "not exists";
    }
    // response.headers.forEach((key, value) {
    //   print(key + " : " + value);
    // });
    if(response.headers['content-type'] != null){
      if(response.headers['content-type']!.contains('jpeg')){
        return "jpeg";
      }else if(response.headers['content-type']!.contains('png')){
        return "png";
      }else if(response.headers['content-type']!.contains('svg')){
        return "svg";
      }   
    }
    return "not exists";
  }
}


class WordsProvider extends GetConnect {
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
      throw Exception('Failed to fetch items in searchWords("$word")');
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
      throw Exception('Failed to fetch items in getWord("$word")');
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

  Future<bool> chat(String username, String message) async{
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
    String  access_token = "";
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
      return true;
    } else {
      // signout
      if(await CacheHelper.hasData('sessionData')){
        await CacheHelper.setData('sessionData', null);
      }
      return false;
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
  // Future<bool> signup(String username, String password) async{
  //   Uri url = Uri.parse('$HTTP_SERVER_HOST/user/signup');
  //   Map data = {};
  //   data['username'] = username;
  //   data['password'] = password;
  //   final response = await post(url.toString(), data);
  //   if (response.statusCode == 200) {
  //     Map<String, dynamic> rsp = Map<String, dynamic>.from(response.body);
  //     await setLocalStorge(username, rsp);
  //     return true;
  //   } else {
  //     return false;
  //   }
  // }
  Future<bool> signup_with_promo(String username, String password, String promo) async{
    Uri url = Uri.parse('$HTTP_SERVER_HOST/user/signup_with_promo');
    Map data = {};
    data['username'] = username;
    data['password'] = password;
    data['promo'] = promo;
    final response = await post(url.toString(), data);
    if (response.statusCode == 200) {
      Map<String, dynamic> rsp = Map<String, dynamic>.from(response.body);
      await setLocalStorge(username, rsp);
      return true;
    } else {
      return false;
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
  RxDouble fontSizeConfig = 16.0.obs;
  // AI助手回答问题使用语言配置
  RxInt aiAssistantLanguage = 0.obs; // 0-English, 1-Chinese
  // 用单词造句时可以使用这个单词其他词性形式
  RxBool useOtherWordForms = false.obs;
  
  
  @override
  void onInit() async {
    super.onInit();
    prefs = await SharedPreferences.getInstance();
    englishInputHelperConfig.value = prefs.getBool('englishInputHelperConfig') ?? englishInputHelperConfig.value;
    fontSizeConfig.value = await prefs.getDouble('fontSizeConfig') ?? fontSizeConfig.value;
    aiAssistantLanguage.value = await prefs.getInt('aiAssistantLanguage') ?? aiAssistantLanguage.value;
    useOtherWordForms.value = await prefs.getBool('useOtherWordForms') ?? useOtherWordForms.value;
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
}

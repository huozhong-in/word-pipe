import 'package:get/get.dart';
import 'package:app/config.dart';
import 'package:app/cache_helper.dart';
import 'dart:async';


class Controller extends GetxController{
  final WordsProvider _wordsProvider = WordsProvider();
  final UserProvider _userProvider = UserProvider();
  
  Future<String> getUserName() async{
    if (await CacheHelper.hasData('username')){
      if(await CacheHelper.getData('username') != null){
        return await CacheHelper.getData('username');
      }
    }
    return "";
  }
  Future<String> getUUID() async{
    if (await CacheHelper.hasData('uuid')){
      if(await CacheHelper.getData('uuid') != null){
        return await CacheHelper.getData('uuid');
      }
    }
    return "";
  }
  Future<String> getAccessToken() async{
    if (await CacheHelper.hasData('access_token')){
      if(await CacheHelper.getData('access_token') != null){
        Future<String> access_token = await CacheHelper.getData('access_token');
        return access_token;
      }
    }
    return "";
  }
  Future<String> getApiKey() async{
    if (await CacheHelper.hasData('apiKey')){
      if(await CacheHelper.getData('apiKey') != null){
        Future<String> apiKey = await CacheHelper.getData('apiKey');
        return apiKey;
      }
    }
    return "";
  }
  Future<String> getBaseUrl() async{
    if (await CacheHelper.hasData('baseUrl')){
      if(await CacheHelper.getData('baseUrl') != null){
        Future<String> baseUrl = await CacheHelper.getData('baseUrl');
        return baseUrl;
      }
    }
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
  Future<bool> signin(String username, String password) async{
    if (await _userProvider.signin(username, password)){
      return true;
    }else{
      return false;
    }
  }
  Future<bool> signup(String username, String password) async{
    if (await _userProvider.signup(username, password)){
      return true;
    }else{
      return false;
    }
  }
  Future<bool> signup_with_promo(String username, String password, String promo) async{
    if (await _userProvider.signup_with_promo(username, password, promo)){
      return true;
    }else{
      return false;
    }
  }
  Future<bool> signout() async{
    if(await CacheHelper.hasData('username')){
      await CacheHelper.setData('username', null);
    }
    if(await CacheHelper.hasData('access_token')){
      await CacheHelper.setData('access_token', null);
    }
    if(await CacheHelper.hasData('expires_at')){
      await CacheHelper.setData('expires_at', null);
    }
    return true;
  }
}


class WordsProvider extends GetConnect {
  Future<List<dynamic>> searchWords(String word) async{
    // 检查缓存中是否有数据
    if (await CacheHelper.hasData(word)) {
      print('Fetching data from cache in searchWords("$word")');
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
      print('Fetching data from cache in getWord("$word")');
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
    if (await CacheHelper.hasData('access_token')){
      if(await CacheHelper.getData('access_token') != null){
        access_token = await CacheHelper.getData('access_token');
      }
    }
    Map<String,String> hs = {};
    if (access_token != ""){
      hs['X-access-token'] = access_token;
    }
    final response = await post(url.toString(), data, headers: hs, contentType: 'application/json');
    if (response.statusCode == 204) {
      return true;
    } else {
      if (response.statusCode == 401){
        // signout
        if(await CacheHelper.hasData('username')){
          await CacheHelper.setData('username', null);
        }
        if(await CacheHelper.hasData('access_token')){
          await CacheHelper.setData('access_token', null);
        }
        if(await CacheHelper.hasData('expires_at')){
          await CacheHelper.setData('expires_at', null);
        }
      }
      return false;
    }
  }

  Future<bool> signin(String username, String password) async{
    Uri url = Uri.parse('$HTTP_SERVER_HOST/user/signin');
    Map data = {};
    data['username'] = username;
    data['password'] = password;
    final response = await post(url.toString(), data);
    if (response.statusCode == 200) {
      Map<String, dynamic> rsp = Map<String, dynamic>.from(response.body);
      await setLocalStorge(username, rsp);
      return true;
    } else {
      return false;
    }
  }
  Future<bool> signup(String username, String password) async{
    Uri url = Uri.parse('$HTTP_SERVER_HOST/user/signup');
    Map data = {};
    data['username'] = username;
    data['password'] = password;
    final response = await post(url.toString(), data);
    if (response.statusCode == 200) {
      Map<String, dynamic> rsp = Map<String, dynamic>.from(response.body);
      await setLocalStorge(username, rsp);
      return true;
    } else {
      return false;
    }
  }
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
    await CacheHelper.setData('username', username);
    await CacheHelper.setData('access_token', rsp['access_token'] as String);
    await CacheHelper.setData('expires_at', rsp['expires_at'] as int);
    await CacheHelper.setData('uuid', rsp['uuid'] as String);
    await CacheHelper.setData('apiKey', decrypt(rsp['apiKey'] as String));
    await CacheHelper.setData('baseUrl', rsp['baseUrl'] as String);
  }
}

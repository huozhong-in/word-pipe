// import 'dart:convert';
// import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/config.dart';
import 'package:app/cache_helper.dart';


class Controller extends GetxController{
  final WordsProvider _wordsProvider = WordsProvider();
  final UserProvider _userProvider = UserProvider();
  
  Future<String> getUserId() async{
    if (await CacheHelper.hasData('userId')){
      return await CacheHelper.getData('userId');
    }
    return DEFAULT_AYONYMOUS_USER_ID;
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
  Future<bool> chat(String userId, String message) async{
    return await _userProvider.chat(userId, message);
  }
  Future<bool> signin(String username, String password) async{
    if (await _userProvider.signin(username, password)){
      await CacheHelper.setData('userId', username);
      return true;
    }else{
      return false;
    }
  }
  Future<bool> signup(String username, String password) async{
    if (await _userProvider.signup(username, password)){
      await CacheHelper.setData('userId', username);
      return true;
    }else{
      return false;
    }
  }
  Future<bool> signout() async{
    if(await CacheHelper.hasData('userId')){
      await CacheHelper.setData('userId', null);
      return true;
    }else{
      return false;
    }
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
  Future<bool> chat(String userId, String message) async{
    // String baseUrl='$HTTP_SERVER_HOST/chat';
    // Uri url = Uri.parse(baseUrl).replace(
    //   queryParameters: <String, String>{
    //     'userId': userId,
    //     'message': message
    //   },
    // );
    Uri url = Uri.parse('$HTTP_SERVER_HOST/chat');
    Map data = {};
    data['userId'] = userId;
    data['message'] = message;
    final response = await post(url.toString(), data);
    if (response.statusCode == 204) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> signin(String username, String password) async{
    Uri url = Uri.parse('$HTTP_SERVER_HOST/user/signin');
    Map data = {};
    data['username'] = username;
    data['password'] = password;
    final response = await post(url.toString(), data);
    if (response.statusCode == 204) {
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
    if (response.statusCode == 204) {
      return true;
    } else {
      return false;
    }
  }
  
}

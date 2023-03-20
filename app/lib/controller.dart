import 'package:get/get.dart';
import 'package:app/config.dart';


class Controller extends GetxController{
  final WordsProvider _wordsProvider = WordsProvider();
  final UserProvider _userProvider = UserProvider();

  String getUserId() {
    // final userId = await GetStorage().read('userId');
    // if (userId != null) {
    //   Get.find<Controller>().userId = userId;
    // }
    return DEFAULT_AYONYMOUS_USER_ID;
  }

  Future<List<dynamic>> searchWords(String word) async{
    return await _wordsProvider.searchWords(word);
  }

  Future<List<dynamic>> getWord(String word) async{
    return await _wordsProvider.getWord(word);
  }

  Future<bool> chat(String userId, String message) async{
    return await _userProvider.chat(userId, message);
  }
}

class WordsProvider extends GetConnect {
  Future<List<dynamic>> searchWords(String word) async{
    final response = await get('$HTTP_SERVER_HOST/s?k=$word');
    if (response.statusCode == 200) {
      return response.body as List<dynamic>;
    } else {
      throw Exception('Failed to fetch items');
    }
  }
  Future<List<dynamic>> getWord(String word) async{
    final response = await get('$HTTP_SERVER_HOST/p?k=$word');
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
    Uri url = Uri.parse('http://127.0.0.1/chat');
    Map data = {};
    data['userId'] = userId;
    data['message'] = message;
    final response = await post(url.toString(), data=data);
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}

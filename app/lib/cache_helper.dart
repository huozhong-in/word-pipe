import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  static Future<bool> hasData(String key) async {
    final prefs = await _prefs;
    return prefs.containsKey(key);
  }

  static Future<void> setData(String key, dynamic data) async {
    final prefs = await _prefs;
    String jsonString = json.encode(data);
    prefs.setString(key, jsonString);
  }

  static Future<dynamic> getData(String key) async {
    final prefs = await _prefs;
    String jsonString = prefs.getString(key) ?? '';
    return json.decode(jsonString);
  }
}

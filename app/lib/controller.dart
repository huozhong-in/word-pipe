import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final WordsProvider _wordsProvider = WordsProvider();
class WordsProvider extends GetConnect {
  Future<List<dynamic>> searchWords(String word) async{
    final response = await get('http://127.0.0.1/s?k=$word');
    if (response.statusCode == 200) {
      return response.body as List<dynamic>;
    } else {
      throw Exception('Failed to fetch items');
    }
  }
  Future<List<dynamic>> getWord(String word) async{
    final response = await get('http://127.0.0.1/p?k=$word');
    if (response.statusCode == 200) {
      return response.body as List<dynamic>;
    } else {
      throw Exception('Failed to fetch items');
    }
  }
  // Future<Response> postUser(Map data) => post('http://youapi/users', body: data);
  // GetSocket userMessages() {
  //   return socket('https://yourapi/users/socket');
  // }

}
class Controller extends GetxController{
  Future<List<dynamic>> searchWords(String word) async{
    return await _wordsProvider.searchWords(word);
  }
  Future<List<dynamic>> getWord(String word) async{
    return await _wordsProvider.getWord(word);
  }
}


final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  primarySwatch: Colors.green,
  primaryColor: const Color(0xFFF5F7FD),
  scaffoldBackgroundColor: const Color(0xFFF5F7FD),
  fontFamily: GoogleFonts.sourceSansPro().fontFamily, // 'Georgia'
  brightness: Brightness.light,
  // Define the default `TextTheme`. Use this to specify the default
  // text styling for headlines, titles, bodies of text, and more.
  // appBarTheme: ,
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
    bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.orange),

);

class CustomColors {
  static const Color splashStart = Color(0xFF5D18C6);
  static const Color splashEnd = Color(0xFF0D25BE);
  static const Color smallTipText = Color(0xFF676769);
  static const Color linkTipText = Color(0xFF0D25BE);

  static const Color firebaseNavy = Color(0xFF2C384A);
  static const Color firebaseOrange = Color(0xFFF57C00);
  static const Color firebaseAmber = Color(0xFFFFA000);
  static const Color firebaseYellow = Color(0xFFFFCA28);
  static const Color firebaseGrey =  Color(0xFFECEFF1);
  static const Color googleBackground = Color(0xFF4285F4);
}

var textFontStyle = TextStyle(
  color: Colors.black,
  fontFamily: GoogleFonts.sourceSansPro().fontFamily,
  fontFamilyFallback: const ['Arial','IosevkaNerdFontCompleteMono'],
);
var titleFontStyle = GoogleFonts.knewave(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold);
//
// 用到的地方用 .copyWith 这个方法, 如：
// Text(
// "显示我想要的字体",
// style: textFontStyle.copyWith(
// fontSize: 18.0,
// color: Colors.red,
// fontWeight: FontWeight.bold,
// ),
// )

// TextStyle的copyWith如下：
//
// TextStyle copyWith({
// bool inherit,
// Color color,
// Color backgroundColor,
// String fontFamily,
// List<String> fontFamilyFallback,
// double fontSize,
// FontWeight fontWeight,
// FontStyle fontStyle,
// double letterSpacing,
// double wordSpacing,
// TextBaseline textBaseline,
// double height,
// Locale locale,
// Paint foreground,
// Paint background,
// List<ui.Shadow> shadows,
// TextDecoration decoration,
// Color decorationColor,
// TextDecorationStyle decorationStyle,
// double decorationThickness,
// String debugLabel,
// })

SnackBar customSnackBar({required String content}) {
  return SnackBar(
    backgroundColor: Colors.greenAccent,
    content: Text(
      content,
      style: const TextStyle(color: Colors.blueGrey, letterSpacing: 0.5),
    ),
  );
}

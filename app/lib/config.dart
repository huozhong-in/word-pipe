import 'dart:core';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pointycastle/export.dart';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kDebugMode;
// final bool kDebugMode = true;
// final bool isDebug = bool.fromEnvironment('DEBUG', defaultValue: false);

final String SSE_SERVER_HOST = kDebugMode ? "http://192.168.2.31" : "https://wordpipe.huozhong.in";
final String SSE_SERVER_PATH = "/api/stream";
final String SSE_MSG_TYPE = "prod"; // prod, dev, test
final String SSE_MSG_DEFAULT_CHANNEL = "users.social";

final String HTTP_SERVER_HOST = kDebugMode ? "http://192.168.2.31/api" : "https://wordpipe.huozhong.in/api";

final AVATAR_FILE_DIR = "avatar";


// 1表示普通文本，3表示图片，34表示语音，43表示视频，47表示表情包，48表示位置，49是卡片消息(文件/视频号/引用/其他),10000表示系统消息
class WordPipeMessageType{
  static const int reserved = 0;
  static const int text = 1;
  static const int word_highlight = 101;
  static const int reply_for_query_sentence = 103;
  static const int reply_for_query_word = 104;
  static const int image = 3;
  static const int audio = 34;
  static const int video = 43;
  static const int emoticon = 47;
  static const int location = 48;
  static const int card = 49;
  static const int system = 10000;
  static const int typing = 10001;
  static const int stream = 10002;
  static const int chathistory = 10003;
}


final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primarySwatch: Colors.green,
  primaryColor: Colors.green,
  scaffoldBackgroundColor: const Color(0xFFF5F7FD),
  fontFamily: GoogleFonts.getFont('Source Sans Pro').fontFamily, // 'Georgia'
  fontFamilyFallback: ["PingFang SC" , "Heiti SC" , 'Noto Sans CJK SC', 'Noto Sans CJK TC', 'Noto Sans CJK JP', 'Noto Sans CJK KR', 'Noto Sans CJK HK'],
  // Define the default `TextTheme`. Use this to specify the default
  // text styling for headlines, titles, bodies of text, and more.
  // appBarTheme: ,
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
    bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
    displaySmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(fontSize: 18.0, fontStyle: FontStyle.italic),
    titleSmall: TextStyle(fontSize: 16.0, fontStyle: FontStyle.italic),
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.orange),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Colors.red,
    selectionColor: Colors.yellow,
    selectionHandleColor: Colors.black,
  )
);
final ThemeData appTheme2 = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primarySwatch: Colors.green,
  primaryColor: Color(0xFF98F5F8), //青色辅助色
  scaffoldBackgroundColor: const Color(0xFFF5F7FD),
  
  textTheme: TextTheme( //文本主题
    displayLarge: TextStyle(color: Color(0xFF98F5F8)),
    displayMedium: TextStyle(color: Color(0xFF06b6d4)),
    displaySmall: TextStyle(color: Colors.white),
    headlineMedium: TextStyle(color: Colors.black),
    headlineSmall: TextStyle(color: Color(0xFF98F5F8)),
    titleLarge: TextStyle(color: Color(0xFF06b6d4)),
  ), 
  colorScheme: ColorScheme(
    primary: Color(0xFF98F5F8), 
    secondary: Color(0xFF06b6d4),
    surface: Colors.white,
    background: Colors.white, 
    error: Colors.red,
    onPrimary: Colors.black,
    onSecondary: Colors.white,
    onSurface: Colors.black,
    onBackground: Colors.black,
    onError: Colors.white,
    brightness: Brightness.light,
  ).copyWith(secondary: Color(0xFF06b6d4)),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Colors.red,
    selectionColor: Colors.yellow,
    selectionHandleColor: Colors.black,
  )
);

class CustomColors {
  static const Color splashStart = Color.fromARGB(255, 24, 198, 56);
  static const Color splashEnd = Color.fromARGB(255, 3, 103, 16);
  static const Color smallTipText = Color(0xFF676769);
  static const Color linkTipText = Color(0xFF0D25BE);

  static const Color firebaseNavy = Color(0xFF2C384A);
  static const Color firebaseOrange = Color(0xFFF57C00);
  static const Color firebaseAmber = Color(0xFFFFA000);
  static const Color firebaseYellow = Color(0xFFFFCA28);
  static const Color firebaseGrey =  Color(0xFFECEFF1);
  static const Color googleBackground = Color(0xFF4285F4);

  static const Color gradientStart = Color.fromARGB(255, 148, 231, 225);
  static const Color gradientEnd = Color.fromARGB(255, 62, 182, 226);
  static const Color appBarColor = Color.fromARGB(255, 25, 172, 225);
  static const Color appBarColor2 =Color.fromARGB(255, 31, 165, 69);
  static const Color inputTextFieldBorder = Color(0xFF4285F4);
  static const Color desktopLeftNav = Color.fromARGB(255, 122, 207, 238);
  static const Color desktopLeftNav2 = Color.fromARGB(255, 59, 214, 157);
  static const Color listViewBg = Color.fromARGB(255, 25, 141, 199);
}

// define mobile layout and desktop layout width
const double MOBILE_LAYOUT_WIDTH = 600;
const double DESKTOP_LAYOUT_WIDTH = 1000;


var textFontStyle = TextStyle(
  color: Colors.black,
  fontFamily: GoogleFonts.getFont('Source Sans Pro').fontFamily,
  fontFamilyFallback: const ['Arial'],
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


SnackbarController customSnackBar({required String title, required String content}) {
  return Get.snackbar(title, content,
    snackPosition: SnackPosition.TOP,
    backgroundColor: Colors.black54,
    colorText: Colors.white,
    margin: const EdgeInsets.all(1),
    borderRadius: 8,
    duration: const Duration(seconds: 2),
    icon: const Icon(Icons.error, color: Colors.white),
    maxWidth: 375,
  );
}

String decrypt(String encryptedString) {
  int offset = 0;
  // 先将加密后的字符串解码为字节数组
  Uint8List bytes = base64.decode(encryptedString);
  // 对每个字节进行解密
  List<int> decryptedBytes = bytes.map((byte) {
    // 解密字节
    int decryptedByte = byte - offset;
    // 确保解密后的字节在0~255范围内
    if (decryptedByte < 0) {
      decryptedByte += 256;
    }
    return decryptedByte;
  }).toList();
  
  // 使用AESFastEngine解密
  BlockCipher cipher = AESEngine()
    ..init(false, KeyParameter(Uint8List.fromList("0123456789abcdef".codeUnits)));

  Uint8List plainText = Uint8List(decryptedBytes.length);

  while (offset < decryptedBytes.length) {
    offset += cipher.processBlock(
        Uint8List.fromList(decryptedBytes), offset, plainText, offset);
  }

  // 返回解密后的字符串
  return utf8.decode(plainText).trim();
}

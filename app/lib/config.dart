import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final bool kDebugMode = true;


final String SSE_SERVER_HOST = kDebugMode ? "http://127.0.0.1" : "https://wordpipe.huozhong.in";
final String SSE_SERVER_PATH = "/api/stream";
final String SSE_MSG_TYPE = "prod"; // prod, dev, test
final String SSE_MSG_DEFAULT_CHANNEL = "users.social";

final String HTTP_SERVER_HOST = kDebugMode ? "http://127.0.0.1/api" : "https://wordpipe.huozhong.in/api";

final String DEFAULT_AYONYMOUS_USER_ID = "anonymous";

final AVATAR_FILE_DIR = "avatar";

// 1表示普通文本，3表示图片，34表示语音，43表示视频，47表示表情包，48表示位置，49是卡片消息(文件/视频号/引用/其他),10000表示撤回消息
class WordPipeMessageType{
  static const int reserved = 0;
  static const int text = 1;
  static const int word2root = 101;
  static const int root2word = 102;
  static const int image = 3;
  static const int audio = 34;
  static const int video = 43;
  static const int emoticon = 47;
  static const int location = 48;
  static const int card = 49;
  static const int recall = 10000;
}


final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  primarySwatch: Colors.green,
  primaryColor: const Color(0xFFF5F7FD),
  scaffoldBackgroundColor: const Color(0xFFF5F7FD),
  fontFamily: GoogleFonts.getFont('Source Sans Pro').fontFamily, // 'Georgia'
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
}

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

SnackBar customSnackBar({required String content}) {
  return SnackBar(
    backgroundColor: Colors.greenAccent,
    content: Text(
      content,
      style: const TextStyle(color: Colors.blueGrey, letterSpacing: 0.5),
    ),
  );
}
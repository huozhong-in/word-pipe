import 'package:get/get.dart';
import 'package:app/controller.dart';
import 'package:flutter/material.dart';
import 'package:app/home.dart';
import 'package:app/sign_in.dart';
// import 'dart:io' show Platform;

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
//     window_size.DesktopWindow.setMinWindowSize(Size(375, 750));
//     window_size.DesktopWindow.setMaxWindowSize(Size(800, 1000));
//   }
//   runApp(const WordPipe());
// }
void main(){
  runApp(WordPipe());
}
// ignore: must_be_immutable
class WordPipe extends StatelessWidget {
  WordPipe({super.key});
  String user_name = "";

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Controller c = Get.put(Controller());
    c.getUserName().then((value) => user_name=value);

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Word Pipe',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.red,
          selectionColor: Colors.yellow,
          selectionHandleColor: Colors.black,
        ),
      ),
      home: user_name != "" ? Home(): SignIn(),
    );
  }
}

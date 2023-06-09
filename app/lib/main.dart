import 'package:wordpipe/config.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:wordpipe/controller.dart';
import 'responsive/responsive_layout.dart';


void main(){
  WidgetsFlutterBinding.ensureInitialized();
  runApp(WordPipe());
}
// ignore: must_be_immutable
class WordPipe extends StatelessWidget {
  WordPipe({super.key});
 
  @override
  Widget build(BuildContext context) {
    
     return GetMaterialApp(
      initialBinding: SettingsBinding(),
      debugShowCheckedModeBanner: false,
      title: 'WordPipe',
      theme: appThemeBright, // https://www.youtube.com/watch?v=6YuQEVN6j-g
      home: ResponsiveLayout()
    );
  }
}

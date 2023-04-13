import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'responsive/responsive_layout.dart';

void main(){
  runApp(WordPipe());
}
// ignore: must_be_immutable
class WordPipe extends StatelessWidget {
  WordPipe({super.key});
 
  @override
  Widget build(BuildContext context) {
    
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
      home: ResponsiveLayout()
    );
  }
}

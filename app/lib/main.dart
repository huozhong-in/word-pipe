import 'package:get/get.dart';
import 'package:app/controller.dart';
import 'package:flutter/material.dart';
import 'package:app/chat_screen.dart';
import 'package:app/home.dart';

void main() {
  runApp(const WordPipe());
}

class WordPipe extends StatelessWidget {
  const WordPipe({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final Controller c = Get.put(Controller());
    
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Word Pipe',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Home(),
    );
  }
}

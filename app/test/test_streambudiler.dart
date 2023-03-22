import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:developer';
// 参考自：https://stackoverflow.com/questions/55520829/how-to-get-response-body-with-request-send-in-dart


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SSE Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final _messages = Rx<String>('Loading messages...\n');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SSE Demo'),
      ),
      body: Center(
        child: Obx(() {
          final messages = StringBuffer();
          for (final message in _messages.value.split('\n')) {
            messages.writeln(message);
          }
          return Text(messages.toString());
        }),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: () {
          _messages.value = 'Loading messages...\n';
          _fetchMessages();
        },
      ),
    );
  }

  void _fetchMessages() async {
    var request = http.Request('POST', Uri.parse('http://example.com/messages'));
    // request.body = json.encode(data);
    // request.headers.addAll(headers);
    request.send().then((result) async {
      http.Response.fromStream(result).then((response) {
        if (response.statusCode == 200){
          log("Done!");
          log('response.body '+ response.body);
        }
        return response.body;
      });
    }).catchError((err){
      log('error : '+err.toString());
    }).whenComplete((){
        
    });
  }
}
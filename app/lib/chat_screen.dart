import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:app/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer';


class ChatScreen extends StatelessWidget {
  ChatScreen({super.key});
  final Controller c = Get.find();

  final List<Message> _messages = <Message>[].obs;
  final List<MatchWords> _matchWords = <MatchWords>[].obs;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  final WordsProvider _wordsProvider = WordsProvider();
  late int _indexGrey = 0;
  late String _lastWord = "";
  late int _leftOrRight = 0;

  void _handleSubmitted(String text) {
    if(text.trim() == ""){
      return;
    }
    _textController.clear();
    _matchWords.clear();
    _indexGrey = 0;
    _messages.insert(0, Message(text: text.trim(), isMe: true));
  }

  void _handleMatchWords(String text) {
    text = text.trim();
    if (text == ""){
      _matchWords.clear();
      return;
    }
    // 获取光标的位置
    int cursorPosition = _textController.selection.start;
    if(_leftOrRight == -1){
      cursorPosition = math.max(0, cursorPosition - 1);
    }else if(_leftOrRight == 1){
      cursorPosition = math.min(text.length, cursorPosition + 1);
    }
    _leftOrRight = 0;
    log("Cursor position: $cursorPosition");

    text = text.substring(0, cursorPosition);
    if (text == ""){
      _matchWords.clear();
      return;
    }
    // String test_input = "hello123worldABCD";
    RegExp regex = RegExp(r"[a-zA-Z]+$");
    Match? match = regex.firstMatch(text);
    if (match != null) {
      _lastWord = match.group(0)!;
      log("last word:$_lastWord");

      Future<List<dynamic>> r =  _wordsProvider.searchWords(_lastWord.toLowerCase());
      r.then((value){

        _matchWords.clear();

        List<dynamic> n = value[0]['result'];
        for (String element in n) {
          bool fullMatch = (element.toLowerCase() == _lastWord.toLowerCase());
          _matchWords.insert(0, MatchWords(text: element, fullMatch: fullMatch, isSelected: element == n[_indexGrey]));
        }
      });
    }else{
      _matchWords.clear();
      _lastWord = "";
    }
  }
  
  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _myTextFild()
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              _handleSubmitted(_textController.text);
              _commentFocus.requestFocus();
            }
          ),
        ],
      ),
    );
  }

  
  Widget _myTextFild(){
    return Focus(
      onKey: (node, RawKeyEvent event) {
          // cmd+enter发送信息
          if (event.isMetaPressed && event.isKeyPressed(LogicalKeyboardKey.enter)) {
            log("cmd+enter: ${_textController.text.trim()}");
            _handleSubmitted(_textController.text);
            _commentFocus.requestFocus();
            return KeyEventResult.handled;
          }
          if (event.isKeyPressed(LogicalKeyboardKey.arrowUp) | (event.isControlPressed && event.isKeyPressed(LogicalKeyboardKey.keyP))){
            log("arrowUp or ctrl+p");
            if (_indexGrey == 0 ){
              _indexGrey = _matchWords.length -1;
            }else{
              _indexGrey -= 1;
            }
            _handleMatchWords(_textController.text);
            return KeyEventResult.handled;
          }
          if (event.isKeyPressed(LogicalKeyboardKey.arrowDown) | (event.isControlPressed && event.isKeyPressed(LogicalKeyboardKey.keyN))){
            log("arrowDown or ctrl+n");
            if (_indexGrey == _matchWords.length -1 ){
              _indexGrey = 0;
            }else{
              _indexGrey += 1;
            }
            _handleMatchWords(_textController.text);
            return KeyEventResult.handled;
          }
          if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft) | (event.isControlPressed && event.isKeyPressed(LogicalKeyboardKey.keyB))){
            log("arrowLeft or ctrl+b");
            // int cursorStart = _textController.selection.start;
            // int cursorEnd = _textController.selection.end;
            // log('Cursor Start: $cursorStart Cursor End: $cursorEnd');
            _leftOrRight = -1;
            _handleMatchWords(_textController.text);
            return KeyEventResult.ignored;
          }
          if (event.isKeyPressed(LogicalKeyboardKey.arrowRight) | (event.isControlPressed && event.isKeyPressed(LogicalKeyboardKey.keyF))){
            log("arrowRight or ctrl+f");
            _leftOrRight = 1;
            _handleMatchWords(_textController.text);
            return KeyEventResult.ignored;
          }
          return KeyEventResult.ignored;
        },
      child: 
        TextField(
          focusNode: _commentFocus,
          controller: _textController,
          onChanged: (value) {
            _handleMatchWords(_textController.text);
          },
          textInputAction: TextInputAction.send,
          onSubmitted: (value) {
            // 按下回车，从候选词中选中上屏
            log('enter: $value');
            _commentFocus.requestFocus();

            int lastWordIndex = _textController.text.lastIndexOf(_lastWord);
            log("_lastWord:$_lastWord lastWordIndex:$lastWordIndex");
            if (_matchWords.isNotEmpty){ 
              log("_matchWords.length:${_matchWords.length}");
              if(lastWordIndex == 0){
                if(_textController.text[0] == _textController.text[0].toUpperCase()){
                  _textController.text = "${_matchWords[_matchWords.length-1-_indexGrey].text.capitalizeFirst} ";
                }else{
                  _textController.text = "${_matchWords[_matchWords.length-1-_indexGrey].text} ";
                }
              }else{
                // todo 这里有Bug，修改中间单词，回车后后面词会消失
                if(_lastWord[0] == _lastWord[0].toUpperCase()){
                  _textController.text = "${_textController.text.substring(0, lastWordIndex)}${_matchWords[_matchWords.length-1-_indexGrey].text.capitalizeFirst} ";
                }else{
                  _textController.text = "${_textController.text.substring(0, lastWordIndex)}${_matchWords[_matchWords.length-1-_indexGrey].text} ";
                }
              }
              _textController.value = _textController.value.copyWith(
                selection: TextSelection(
                  baseOffset: _textController.text.length,
                  extentOffset: _textController.text.length,
                ),
              );
            }
            _matchWords.clear();
            _indexGrey = 0;
          },
          decoration: const InputDecoration(
            hintText: 'Input some words..',
            hintStyle: TextStyle(color: Colors.grey),
            // prefixIcon: Icon(Icons.),
            // suffixIcon: Icon(Icons.check, color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10),),
              borderSide: BorderSide(
                color: Colors.blueGrey,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10),),
              borderSide: BorderSide(
                color: Colors.deepPurpleAccent,
                width: 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10),),
              borderSide: BorderSide(
                color: Colors.redAccent,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.redAccent,
                width: 1,
              ),
            ),
          )
        )
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Pipe'),
      ),
      body: Column(
        children: [
          Flexible(
            flex: 3,
            child: Obx((){
              return ListView.builder(
                itemBuilder: (_, int index) => _messages[index],
                reverse: true,
                itemCount: _messages.length,
              );
            })
          ),
          const Divider(height: 1.0),
          Flexible(
            flex: 2,
            child: Obx(() { 
              return ListView.builder(
                itemBuilder: (_, int index) => _matchWords[index],
                reverse: true,
                itemCount: _matchWords.length,
              );
            })
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

}

class Message extends StatelessWidget {
  const Message({super.key, required this.text, required this.isMe});

  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle textStyle = themeData.textTheme.bodyLarge!.copyWith(
      color: isMe ? Colors.white : Colors.black,
    );
    final BoxDecoration decoration = BoxDecoration(
      color: isMe ? themeData.primaryColor : Colors.grey[300],
      borderRadius: BorderRadius.circular(3.0),
    );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: textStyle),
        ],
      ),
    );
  }
}

class MatchWords extends StatelessWidget {
  const MatchWords({super.key, required this.text, required this.fullMatch, required this.isSelected});

  final String text;
  final bool fullMatch;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle textStyle = themeData.textTheme.bodyMedium!.copyWith(
      color: Colors.black87,
      backgroundColor: fullMatch ? Colors.blue : Colors.white,
    );
    return Container(
          color: isSelected ? Colors.grey: Colors.white,
          child: SizedBox(
            // width: 200,
            // height: 20,
            child: Text(text, style: textStyle),
          ),
    );
  }
}

class WordsProvider extends GetConnect {
  Future<List<dynamic>> searchWords(String word) async{
    final response = await get('http://127.0.0.1/s?k=$word');
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
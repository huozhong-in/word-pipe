import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:app/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/message_bubble.dart';
import 'dart:developer';


class Home extends StatelessWidget {
  Home({super.key});
  final Controller c = Get.find();

  final List<Message> _messages = <Message>[].obs;
  final List<MatchWords> _matchWords = <MatchWords>[].obs;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  late int _indexGrey = 0;
  late String _lastWord = "";
  late int _leftOrRight = 0;
  late final Map<String, String> _wordDetail = <String, String>{}.obs;
  
  
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
    if (text.trim() == ""){
      _matchWords.clear();
      _indexGrey = 0;
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
    if (text.trim() == ""){
      _matchWords.clear();
      _indexGrey = 0;
      return;
    }
    
    // String test_input = "hello123worldABCD";
    RegExp regex = RegExp(r"[a-zA-Z]+$");
    Match? match = regex.firstMatch(text);
    if (match != null) {
      _lastWord = match.group(0)!;
      log("last word:$_lastWord");

      Future<List<dynamic>> r =  c.searchWords(_lastWord.toLowerCase());
      r.then((value){

        _matchWords.clear();

        List<dynamic> n = value[0]['result'];
        int i = 0;
        for (String element in n) {
          if(i == _indexGrey){
            Future<List<dynamic>> rr = c.getWord(element);
            rr.then((m){
              Map<String, dynamic> stringMap = Map<String, dynamic>.from(m[0]);
              stringMap.forEach((key, value) {
                _wordDetail[key] = value.toString();
              });
              // log(_wordDetail['phonetic']!);
              // log(_wordDetail['definition']!);
              // log(_wordDetail['translation']!);
            });
          }
          bool fullMatch = (element.toLowerCase() == _lastWord.toLowerCase());
          _matchWords.insert(0, MatchWords(text: element, fullMatch: fullMatch, isSelected: element == n[_indexGrey]));
          i++;
        }
      });
    }else{
      _matchWords.clear();
      _indexGrey = 0;
      _lastWord = "";
    }
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
          // 阻止默认的回车提交功能，改为到onSubmitted()中手动控制
          if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
            log("enter: ${_textController.text.trim()}");
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
          autofocus: true,
          controller: _textController,
          onChanged: (value) {
            _handleMatchWords(_textController.text);
          },
          textInputAction: TextInputAction.send,
          onSubmitted: (value) {
            // 按下回车，从候选词中选中上屏
            log('enter2: $value');
            _commentFocus.requestFocus();

            int lastWordIndex = _textController.text.lastIndexOf(_lastWord);
            log("_lastWord:$_lastWord lastWordIndex:$lastWordIndex");
            if (_matchWords.isNotEmpty){ 
              log("_matchWords.length:${_matchWords.length}");
              if(lastWordIndex == 0){
                if(_textController.text[0] == _textController.text[0].toUpperCase()){
                  _textController.text = "${_matchWords[_matchWords.length-1-_indexGrey].text.capitalizeFirst}";
                }else{
                  _textController.text = _matchWords[_matchWords.length-1-_indexGrey].text;
                }
              }else{
                // todo 这里有Bug，修改中间单词，回车后后面词会消失
                if(_lastWord[0] == _lastWord[0].toUpperCase()){
                  _textController.text = "${_textController.text.substring(0, lastWordIndex)}${_matchWords[_matchWords.length-1-_indexGrey].text.capitalizeFirst}";
                }else{
                  _textController.text = "${_textController.text.substring(0, lastWordIndex)}${_matchWords[_matchWords.length-1-_indexGrey].text}";
                }
              }
              _textController.value = _textController.value.copyWith(
                selection: TextSelection(
                  baseOffset: _textController.text.length,
                  extentOffset: _textController.text.length,
                ),
              );
            }else{
              // todo 光标处加回车，并将光标移到回车处
              _textController.text = "${_textController.text}\n";
              _textController.selection = TextSelection(baseOffset: _textController.text.length, extentOffset: _textController.text.length) ;
            }
            _matchWords.clear();
            _indexGrey = 0;
          },
          style: const TextStyle(fontFamily: 'IosevkaNerdFontCompleteMono'),
          maxLines: 3,
          minLines: 3,
          decoration: const InputDecoration.collapsed(
            hintText: 'Input some words..',
            hintStyle: TextStyle(color: Colors.grey, fontFamily: 'IosevkaNerdFontCompleteMono'),
          ),
        )
      );
  }

  @override
  Widget build(context){
    return Scaffold(
      appBar: AppBar(
          title: Text('Word Pipe',
            style: TextStyle(
              color: Colors.black54,
              fontFamily: GoogleFonts.getFont('Comfortaa').fontFamily,
              fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: Colors.greenAccent[100],
          automaticallyImplyLeading: false,
        ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: const BoxDecoration(color: Colors.greenAccent),
                child: 
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.grey.withOpacity(0.5),
                        child: Obx(() {
                          return ListView.builder(
                            itemBuilder: (_, int index) => _messages[index],
                            reverse: true,
                            itemCount: _messages.length,
                            shrinkWrap: true,
                          );
                        },)
                      ),
                      Obx(() => 
                        Visibility(
                          visible: _matchWords.isNotEmpty.obs.value,
                          child: Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              constraints: const BoxConstraints(maxHeight: 400, minHeight: 400),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    blurRadius: 5,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                // mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text(
                                        'Mini vocabulary',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '↑↓ to choose word / ⏎ to confirm',
                                        style: TextStyle(fontSize: 14),
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        flex: 1,
                                        fit: FlexFit.tight,
                                        child: Obx(() {
                                          return ListView.builder(
                                          itemBuilder: (_, int index) => _matchWords[index],
                                          reverse: true,
                                          itemCount: _matchWords.length,
                                          shrinkWrap: true,
                                        );
                                        },),
                                      ),
                                      Flexible(
                                        flex: 2,
                                        fit: FlexFit.tight,
                                        child: Obx(() {
                                          return Flex(
                                            direction: Axis.vertical,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(_wordDetail['phonetic']!=null && _wordDetail['phonetic']!=""?"\\${_wordDetail['phonetic']}\\":"", style: const TextStyle(fontSize: 14)),
                                              Text(_wordDetail['translation']!=null && _wordDetail['translation']!=""?_wordDetail['translation'] as String:"", style: textFontStyle.copyWith(fontSize: 14)),
                                              Text(_wordDetail['definition']!=null && _wordDetail['definition']!=""?_wordDetail['definition'] as String:"", style: const TextStyle(backgroundColor: Colors.greenAccent, fontFamily: 'IosevkaNerdFontCompleteMono'))
                                            ],
                                          );
                                        },),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(5, 0, 5, 5),
              padding: const EdgeInsets.all(7),
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    blurRadius: 5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _myTextFild()
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: Colors.green[400],
                    onPressed: () {
                      _handleSubmitted(_textController.text);
                      _commentFocus.requestFocus();
                    },
                    tooltip: "cmd+enter",
                  ),
                ],
              ),
            )
          ],
        ),
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
    return MessageBubble(
            message: text,
            isSender: false,
            bubbleColor: const Color.fromRGBO(40, 178, 95, 1));
    // return Container(
    //   margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    //   decoration: decoration,
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       Text(text, style: textStyle),
          
    //     ],
    //   ),
    // );
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
      color: Colors.green[700],
      backgroundColor: isSelected ? Colors.lightGreenAccent: Colors.transparent,
      fontWeight: fullMatch ? FontWeight.bold : FontWeight.normal,
    );
    return SizedBox(
      child: Text(text, style: textStyle),
    );
  }
}

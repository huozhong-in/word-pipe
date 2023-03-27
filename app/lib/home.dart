
import 'dart:math' as math;
import 'package:app/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:app/controller.dart';
import 'package:app/MessageView.dart';
import 'package:app/user_profile.dart';
import 'dart:developer';

// ugly code
import 'package:app/MessageController.dart';
import 'package:app/MessageModel.dart';

// ignore: must_be_immutable
class Home extends StatelessWidget {
  Home({super.key});
  final Controller c = Get.find();

  final List<MatchWords> _matchWords = <MatchWords>[].obs;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  late int _indexHighlight = 0; // 此变量用于记录当前选中的匹配单词的索引
  late String _currentWord = ""; // 文本框中输入光标所在的单词
  late int _leftOrRight = 0; // 此变量用于记录当按下键盘左右键时，光标应向左移动还是向右移动，-1表示向左，1表示向右，0表示未移动
  late final Map<String, String> _wordDetail = <String, String>{}.obs;

  void _handleSubmitted(String text) {
    if(text.trim() == ""){
      return;
    }
    // 向服务端发送消息，如果返回http code 200，则将消息添加到消息列表中
    Future<bool> r = c.chat(c.getUserId() as String, text.trim());
    r.then((value){
      if(value){
        _textController.clear();
        _matchWords.clear();
        _indexHighlight = 0;
        //ugly code，因为系统中存在两个Controller，没有更好的隔离方法。按理说MessageController应该是MVC中的，而不是在这里直接能调用到
        final MessageController messageController = Get.put(MessageController());
        messageController.addMessage(MessageModel(dataList: [text.trim()], type: WordPipeMessageType.text, userId: c.getUserId() as String));
      }
    });    
  }

  
  void _handleMatchWords(String text) {
    if (text.trim() == ""){
      _matchWords.clear();
      _indexHighlight = 0;
      return;
    }
    // 获取光标的位置。
    // 因捕获键盘事件在前，_textControll.selection.start和end变化在后，
    // 导致此时获得的光标实际位置向左或向右偏移了1个字符，所以要预先设置_leftOrRight，并在这里修正
    // 注意光标变量不能小于0，也不能超过text的长度
    int cursorPosition = _textController.selection.start;
    if(_leftOrRight == -1){
      cursorPosition = math.max(0, cursorPosition - 1);
    }else if(_leftOrRight == 1){
      cursorPosition = math.min(text.length, cursorPosition + 1);
    }
    _leftOrRight = 0;
    log("Cursor position: $cursorPosition");

    // 获取当前光标所在的单词。单词用正则表达式从句子中匹配拆分出来，正则判读条件为所有大小写字母和带连字符“-”的单词
    bool isFound = false;
    RegExp exp = RegExp(r'\b[a-zA-Z]+(?:-[a-zA-Z]+)*\b');
    Iterable<RegExpMatch> matches = exp.allMatches(text);
    int startIndex = 0;
    int endIndex = 0;
    for (RegExpMatch match in matches) {
      String? word = match.group(0);
      startIndex = match.start;
      endIndex = match.end;
      log('Found "$word" at position $startIndex-$endIndex');
      if(cursorPosition > startIndex && cursorPosition <= endIndex){
        _currentWord = word!;
        isFound = true;
        log("_currentWord: $word");
        break;
      }
    }
    if (isFound == false){
      _currentWord = "";
      _matchWords.clear();
      _indexHighlight = 0;
    }

    if (_currentWord != ""){
      //取得当前单词中光标前的部分字符串
      String currentWordPart = _currentWord.substring(0, cursorPosition - startIndex);
      if (currentWordPart != "") {
        // 将单词前面的字符串当作前缀，拿到匹配的单词列表
        Future<List<dynamic>> r =  c.searchWords(currentWordPart.toLowerCase());
        r.then((value){
          try{
            List<dynamic> n = value[0]['result'];
            build_matchWords_list(n.map((e) => e.toString()).toList());
          }catch(e){
            log("_handleMatchWords() " + e.toString());
          }
        });
      }
    }else{
      _matchWords.clear();
      _indexHighlight = 0;
    }
  }

  void build_matchWords_list(List<String> words){
    _matchWords.clear();
    int i = 0;
    for (String element in words) {
      // 用isSelected变量告知前端是否高亮显示当前单词
      bool fullMatch = (element.toLowerCase() == _currentWord.toLowerCase());
      _matchWords.insert(_matchWords.length, MatchWords(text: element, fullMatch: fullMatch, isSelected: element == words[_indexHighlight]));
      // 获取列表中被高亮单词的详细信息，放入_wordDetail中，即在右侧显示音标、定义和翻译等信息
      if(i == _indexHighlight){
        Future<List<dynamic>> r = c.getWord(element);
        r.then((m){
          _wordDetail.clear();
          try{
            Map<String, dynamic> stringMap = Map<String, dynamic>.from(m[0]);
            stringMap.forEach((key, value) {
              _wordDetail[key] = value.toString();
            });
          }catch(e){
            _wordDetail.clear();
            log("build_matchWords_list($element) " + e.toString());
          }
        });
      }      
      i++;
    }
  }


  List<int> get_word_index_range_in_text(String text, int cursorPosition){
    RegExp exp = RegExp(r'\b[a-zA-Z]+(?:-[a-zA-Z]+)*\b');
    Iterable<RegExpMatch> matches = exp.allMatches(text);
    int startIndex = 0;
    int endIndex = 0;
    for (RegExpMatch match in matches) {
      String? word = match.group(0);
      startIndex = match.start;
      endIndex = match.end;
      log('get_word_index_range_in_text(): Found "$word" at position $startIndex-$endIndex');
      if(cursorPosition > startIndex && cursorPosition <= endIndex){
        _currentWord = word!;
        return [startIndex, endIndex];    
      }
    }
    return [0, 0];
  }


  Widget _myTextFild(){
    return Focus(
      onKey: (node, RawKeyEvent event) {
          // cmd+enter发送信息
          if (event.isMetaPressed && event.isKeyPressed(LogicalKeyboardKey.enter)) {
            // log("cmd+enter: ${_textController.text.trim()}");
            _handleSubmitted(_textController.text);
            _commentFocus.requestFocus();
            return KeyEventResult.handled;
          }
          // 按下回车，从匹配到的词列表中选中一个单词加到文本框中
          if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
            // log("enter2: ${_textController.text.trim()}");
            _commentFocus.requestFocus();
            // 当前光标位置
            int cursorStart = _textController.selection.start;
            // 取得当前光标所在单词的起始位置和结束位置
            List<int> currentWordIndexRange = get_word_index_range_in_text(_textController.text, cursorStart);
            // 如果从接口中查询到的匹配单词列表不为空
            if (_matchWords.isNotEmpty){ 
              // log("_matchWords.length:${_matchWords.length}");
              if(currentWordIndexRange != [0,0]){
                String words_behind = _textController.text.substring(currentWordIndexRange[1], _textController.text.length);
                String words_before = _textController.text.substring(0, currentWordIndexRange[0]);
                // log("words_before:$words_before");
                // log("words_behind:$words_behind");
                // log("_currentWord:${_currentWord}");
                if(_currentWord[0] == _currentWord[0].toUpperCase()){
                  _textController.text = "${words_before}${_matchWords[_indexHighlight].text.capitalizeFirst}${words_behind}";
                }else{
                  _textController.text = "${words_before}${_matchWords[_indexHighlight].text}${words_behind}";
                }
              }
              // 光标移到_matchWords[_indexGrey].text和words_behind之间
              _textController.selection = TextSelection(baseOffset: currentWordIndexRange[0]+_matchWords[_indexHighlight].text.length, extentOffset: currentWordIndexRange[0]+_matchWords[_indexHighlight].text.length) ;
            }else{
              return KeyEventResult.ignored;
            }
            _matchWords.clear();
            _indexHighlight = 0;
            return KeyEventResult.handled;
          }
          // 列表到顶后从底端继续循环
          if (event.isKeyPressed(LogicalKeyboardKey.arrowUp) | (event.isControlPressed && event.isKeyPressed(LogicalKeyboardKey.keyP))){
            // log("arrowUp or ctrl+p: ${_indexHighlight}");
            if (_matchWords.length == 0){
              return KeyEventResult.ignored;
            }
            if (_indexHighlight == 0 ){
              _indexHighlight = _matchWords.length -1;
            }else{
              _indexHighlight -= 1;
            }
            List<String> t = _matchWords.map((e) => e.text).toList();
            build_matchWords_list(t);
            return KeyEventResult.handled;
          }
          // 列表到底后从顶端继续循环
          if (event.isKeyPressed(LogicalKeyboardKey.arrowDown) | (event.isControlPressed && event.isKeyPressed(LogicalKeyboardKey.keyN))){
            // log("arrowDown or ctrl+n: ${_indexHighlight}");
            if (_matchWords.length == 0){
              return KeyEventResult.ignored;
            }
            if (_indexHighlight == _matchWords.length -1 ){
              _indexHighlight = 0;
            }else{
              _indexHighlight += 1;
            }
            List<String> t = _matchWords.map((e) => e.text).toList();
            build_matchWords_list(t);
            return KeyEventResult.handled;
          }
          // 光标向左移动，截取光标左侧单词的子串，匹配单词列表
          if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft) | (event.isControlPressed && event.isKeyPressed(LogicalKeyboardKey.keyB))){
            // log("arrowLeft or ctrl+b");
            _leftOrRight = -1;
            _handleMatchWords(_textController.text);
            return KeyEventResult.ignored;
          }
          // 光标向右移动，截取光标左侧单词的子串，匹配单词列表
          if (event.isKeyPressed(LogicalKeyboardKey.arrowRight) | (event.isControlPressed && event.isKeyPressed(LogicalKeyboardKey.keyF))){
            // log("arrowRight or ctrl+f");
            _leftOrRight = 1;
            _handleMatchWords(_textController.text);
            return KeyEventResult.ignored;
          }
          // if ESC pressed, clear the matchWords list, then close the Words list interface.
          if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
            // log("escape");
            _matchWords.clear();
            _indexHighlight = 0;
            return KeyEventResult.handled;
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
          textInputAction: TextInputAction.newline,
          style: TextStyle(fontFamily: GoogleFonts.getFont('Source Sans Pro').fontFamily, fontWeight: FontWeight.w400),
          maxLines: 3,
          minLines: 3,
          decoration: InputDecoration(
            hintText: '/ OR words',
            hintStyle: TextStyle(color: Colors.grey, fontFamily: GoogleFonts.getFont('Source Sans Pro').fontFamily, fontWeight: FontWeight.w400),
            prefixIcon: IconButton(
                color: Colors.grey,
                hoverColor: Colors.black54,
                onPressed: () {
                  ScaffoldMessenger.of(Get.overlayContext!).showSnackBar(
                    customSnackBar(content: "暂未开放"),
                  );
                }, 
                icon: const Icon(Icons.mic_rounded)
              ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10),),
              borderSide: BorderSide(
                color: Colors.grey,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10),),
              borderSide: BorderSide(
                color: Colors.grey,
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
          ),
        )
      );
  }

  @override
  Widget build(context){
    
    return Scaffold(
      appBar: AppBar(
        // actions: [
        //   // a button to configurate the app
        //   IconButton(
        //     icon: Icon(Icons.settings),
        //     color: Colors.black54,
        //     onPressed: () {
        //       Scaffold.of(context).openEndDrawer();
        //     },
        //   ),],
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
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.teal,
              ),
              child: Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            // ListTile(
            //   leading: Icon(Icons.message),
            //   title: Text('Messages'),
            // ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Profile'),
              onTap: () => Get.to(UserProfile()),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('About Us'),
            ),
          ],
        ),
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
                        alignment: Alignment.topCenter,
                        color: Colors.grey.withOpacity(0.5),
                        child: MessageView(key: ValueKey(DateTime.now()))
                      ),
                      Obx(() => 
                        Visibility(
                          visible: _matchWords.isNotEmpty.obs.value,
                          child: Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              height: 410,
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              // constraints: const BoxConstraints(maxHeight: 400, minHeight: 400),
                              decoration: BoxDecoration(
                                color: Colors.white70,
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
                                // mainAxisSize: MainAxisSize.max,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Live vocabulary helper',
                                        style: TextStyle(
                                          fontSize: 16, 
                                          fontWeight: FontWeight.bold,
                                          fontFamily: GoogleFonts.getFont('Roboto').fontFamily,
                                          ),
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
                                    // mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Flexible( 
                                        flex: 1,
                                        fit: FlexFit.tight,
                                        child: Obx(() {
                                          return ListView.builder(
                                          itemBuilder: (_, int index) => _matchWords[index],
                                          reverse: false,
                                          itemCount: _matchWords.length,
                                          shrinkWrap: true,
                                          primary: true
                                        );
                                        },),
                                      ),
                                      Flexible(
                                        flex: 2,
                                        fit: FlexFit.tight,
                                        child: Obx(() {
                                          return SizedBox(
                                            height: 350,
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.vertical,
                                              child: Scrollbar(
                                                thumbVisibility: true,
                                                child: Text.rich(
                                                  TextSpan(
                                                    text: '',
                                                    style: Theme.of(context).textTheme.bodyMedium!,
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                        text: _wordDetail['phonetic']!=null && _wordDetail['phonetic']!=""?"\\${_wordDetail['phonetic']}\\":"",
                                                        style: const TextStyle(fontSize: 16)
                                                      ),
                                                      const TextSpan(text: "\n"),
                                                      _addHighlightToTags(_wordDetail),
                                                      const TextSpan(text: "\n"),
                                                      TextSpan(
                                                        text: _wordDetail['translation']!=null && _wordDetail['translation']!=""?_wordDetail['translation'] as String:"",
                                                        style: const TextStyle(backgroundColor: Colors.greenAccent)
                                                      ),
                                                      const TextSpan(text: "\n"),
                                                      _addHighlightToPos(_wordDetail),
                                                      const TextSpan(text: "\n"),
                                                      _addHighlightToExchange(_wordDetail),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
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
              padding: const EdgeInsets.all(10),
              // height: 100,
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
                  // Ink(
                  //   decoration: const ShapeDecoration(
                  //     color: Colors.lightBlue,
                  //     shape: CircleBorder(),
                  //   ),
                  //   child: IconButton(
                  //     color: Colors.grey,
                  //     hoverColor: Colors.black54,
                  //     onPressed: () {
                  //       ScaffoldMessenger.of(Get.overlayContext!).showSnackBar(
                  //         customSnackBar(content: "暂未开放"),
                  //       );
                  //     }, 
                  //     icon: const Icon(Icons.mic_rounded)
                  //   ),
                  // ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: _myTextFild(),
                    )
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: Colors.green[400],
                    onPressed: () {
                      _handleSubmitted(_textController.text);
                      _commentFocus.requestFocus();
                    },
                    tooltip: "cmd+enter",
                    hoverColor: Colors.black54,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  TextSpan _addHighlightToTags(Map<String, String> tags) {
    if(tags['tag']!=null && tags['tag'] as String !=""){
      final List<TextSpan> children = <TextSpan>[];
      final List<String> words = (tags['tag'] as String).split(' ');
      for (final String word in words) {
        children.add(TextSpan(
          text: " $word ".replaceFirst('zk', '中考').replaceFirst('gk', '高考').replaceFirst('ky', '考研')
            .replaceFirst('cet4', '四级').replaceFirst('cet6', '六级').replaceFirst('toefl', '托福')
            .replaceFirst('ielts', '雅思').replaceFirst('gre', 'GRE'),
          style: const TextStyle(fontSize: 12,color: Colors.white, backgroundColor: Colors.teal),
        ));
      children.add(const TextSpan(text: ' '));
      }
      return TextSpan(children: children);
    }else{
      return TextSpan(text: "");
    }    
  }
}

// 拆分_wordDetail['exchange']的词性和释义
TextSpan _addHighlightToExchange(Map<String, String> wordDetail) {
  //   比如 perceive 这个单词的 exchange 为：
  // ```text
  // d:perceived/p:perceived/3:perceives/i:perceiving
  // ```

  // 意思是 perceive 的过去式（`p`） 为 perceived，过去分词（`d`）为 perceived, 现在分词（'i'）是 perceiving，第三人称单数（`3`）为 perceives。冒号前面具体项目为：

  // | 类型 | 说明                                                       |
  // | ---- | ---------------------------------------------------------- |
  // | p    | 过去式（did）                                              |
  // | d    | 过去分词（done）                                           |
  // | i    | 现在分词（doing）                                          |
  // | 3    | 第三人称单数（does）                                       |
  // | r    | 形容词比较级（-er）                                        |
  // | t    | 形容词最高级（-est）                                       |
  // | s    | 名词复数形式                                               |
  // | 0    | Lemma，如 perceived 的 Lemma 是 perceive                   |
  // | 1    | Lemma 的变换形式，比如 s 代表 apples 是其 lemma 的复数形式 |
  if(wordDetail['exchange']!=null && wordDetail['exchange'] as String !=""){
    final List<TextSpan> children = <TextSpan>[];
    final List<String> words = (wordDetail['exchange'] as String).split('/');
    for (final String word in words) {
      final List<String> wordList = word.split(':');
      children.add(TextSpan(
        text: wordList[0].replaceFirst('p', '过去式').replaceFirst('d', '过去分词').replaceFirst('i', '现在分词').replaceFirst('3', '第三人称单数')
        .replaceFirst('r', "形容词比较级").replaceFirst('t', "形容词最高级").replaceFirst('s', "名词复数").replaceFirst('0', '原型').replaceFirst('1', '原型变换'),
        style: const TextStyle(fontSize: 14,color: Colors.teal),
      ));
      if(wordList.length>1){
        children.add(TextSpan(
        text: wordList[1],
      ));
      }
    children.add(const TextSpan(text: '\n'));
    }
    return TextSpan(children: children);
  }else{
    return TextSpan(text: "");
  }    
}
// 拆分_wordDetail['pos']的词性和出现概率
TextSpan _addHighlightToPos(Map<String, String> wordDetail) {
  // fuse：pos = `n:46/v:54`
  // 代表 fuse 这个词有两个位置（词性），n（名词）占比 46%，v（动词）占比 54%，根据后面的比例，你可以知道该词语在语料库里各个 pos 所出现的频率
  if(wordDetail['pos']!=null && wordDetail['pos'] as String !=""){
    final List<TextSpan> children = <TextSpan>[];
    children.add(const TextSpan(text: '词性：'));
    final List<String> words = (wordDetail['pos'] as String).split('/');
    for (final String word in words) {
      final List<String> wordList = word.split(':');
      children.add(TextSpan(
        text: wordList[0].replaceFirst('n', '名词').replaceFirst('v', '动词').replaceFirst('j', '形容词').replaceFirst('r', '副词')
        .replaceFirst('m', '数词').replaceFirst('q', '量词').replaceFirst('p', '介词').replaceFirst('c', '连词')
        .replaceFirst('u', '助词').replaceFirst('y', '语气词').replaceFirst('e', '叹词').replaceFirst('o', '拟声词'),
      ));
      if(wordList.length>1){
        children.add(TextSpan(
        text: wordList[1]+"%",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      }
    children.add(const TextSpan(text: ' '));
    }
    return TextSpan(children: children,style: TextStyle(fontSize: 14,color: Colors.blue,fontFamily: GoogleFonts.getFont('Roboto').fontFamily),);
  }else{
    return TextSpan(text: "");
  }    
}

class MatchWords extends StatelessWidget {
  const MatchWords({super.key, required this.text, required this.fullMatch, required this.isSelected});

  final String text;
  final bool fullMatch;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = TextStyle(
      color: Colors.black87,
      backgroundColor: isSelected ? Colors.greenAccent: Colors.transparent,
      fontSize: 12,
      fontWeight: fullMatch ? FontWeight.bold : FontWeight.normal,
      fontFamily: GoogleFonts.getFont('Roboto').fontFamily,
      fontFamilyFallback: const ['Arial']
    );
    return Text(text, style: textStyle);
  }
}

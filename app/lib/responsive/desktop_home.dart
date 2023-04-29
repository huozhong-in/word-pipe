import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wordpipe/config.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/conversation_view.dart';
import 'package:wordpipe/responsive/responsive_layout.dart';
import 'package:wordpipe/user_profile.dart';
import 'package:wordpipe/MessageController.dart';
import 'package:wordpipe/settings.dart';
import 'package:wordpipe/about_us.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:developer';

// ignore: must_be_immutable
class DesktopHome extends StatelessWidget {
  DesktopHome({super.key});
  final Controller c = Get.find<Controller>();
  final MessageController messageController = Get.find<MessageController>();
  final SettingsController settingsController = Get.find<SettingsController>();
  final List<MatchWords> _matchWords = <MatchWords>[].obs;
  final TextEditingController _textController = TextEditingController();
  late FocusNode _commentFocus;
  late int _indexHighlight = 0; // 此变量用于记录当前选中的匹配单词的索引
  late String _currentWord = ""; // 文本框中输入光标所在的单词
  late int _leftOrRight = 0; // 此变量用于记录当按下键盘左右键时，光标应向左移动还是向右移动，-1表示向左，1表示向右，0表示未移动
  late final Map<String, String> _wordDetail = <String, String>{}.obs;
  ScrollController _scrollController = ScrollController();

  void _handleSubmitted(String text) {
    if(text.trim() == ""){
      return;
    }
    // 向服务端发送消息，
    c.getUserName().then((_username){
      if (settingsController.freeChatMode.value == true){
        // 如果是free-chat模式，则要开启新会话窗口
        messageController.freeChat('gpt-3.5-turbo', settingsController.openAiApiKey.value, messageController.conversation_id.value, text);
      }else{
        // 如果是普通模式，向服务端发送消息
        Future<bool> r = c.chat(_username, text.trim());
        r.then((ret){
          if(ret == true){
            _textController.clear();
            _matchWords.clear();
            _indexHighlight = 0;
          }else{
            customSnackBar(title: "Error", content: "Failed to send message, please Sign In again.");
            // 三秒后跳转到登录页面
            Future.delayed(Duration(seconds: 3), () {
              Get.offAll(ResponsiveLayout());
            });
          }
        });
      }
    });    
  }
  
  void _handleMatchWords(String text) {
    if(settingsController.englishInputHelperConfig == false){
      _matchWords.clear();
      _indexHighlight = 0;
      return;
    }
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
    // log("Cursor position: $cursorPosition");

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
      // log('Found "$word" at position $startIndex-$endIndex');
      if(cursorPosition > startIndex && cursorPosition <= endIndex){
        _currentWord = word!;
        isFound = true;
        // log("_currentWord: $word");
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
            build_matchWords_list(n.map((e) => e.toString()).toList(), '');
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

  void build_matchWords_list(List<String> words, String skey){
    _matchWords.clear();
    int i = 0;
    for (String element in words) {
      // 用isSelected变量告知前端是否高亮显示当前单词
      bool fullMatch = (element.toLowerCase() == _currentWord.toLowerCase());
      int cur_index = i;
      _matchWords.insert(_matchWords.length, 
        MatchWords(text: element, fullMatch: fullMatch, isSelected: element == words[_indexHighlight], 
          onTap:() {
            // 当用户点击某个单词时:查词；
            _indexHighlight = cur_index;
            build_matchWords_list(words, '');
            _commentFocus.requestFocus();
          },
        )
      );
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
    

    // 当用键盘　↑　↓　时，需要重新计算高亮单词的位置和滚动距离，保证高亮项始终在可视区域内
    final double listItemHeight = 20;
    final double listViewHeight = 350;
    final double listViewTopPadding = 20;
    final double listViewBottomPadding = 20;

    int newIndexHighlight;
    double newScrollOffset;
    if (skey == 'arrowUp') {
      // 计算新的高亮元素和滚动距离
      newIndexHighlight = _indexHighlight - 1;
      newScrollOffset = _scrollController.offset - listItemHeight;
      if (newScrollOffset < 0) {
        newScrollOffset = 0;
      }
      if (newIndexHighlight < 0) {
        newIndexHighlight = 0;
      }
    } else if (skey == 'arrowDown') {
      // 计算新的高亮元素和滚动距离
      newIndexHighlight = _indexHighlight + 1;
      newScrollOffset = _scrollController.offset + listItemHeight;
      if (newScrollOffset > _scrollController.position.maxScrollExtent) {
        newScrollOffset = _scrollController.position.maxScrollExtent;
      }
      if (newIndexHighlight >= _matchWords.length) {
        newIndexHighlight = _matchWords.length - 1;
      }
    } else {
      return;
    }
    // 判断新的高亮元素是否接近列表顶部或底部，需要滚动列表以保持高亮元素在视野内
    final double newListItemTop = newIndexHighlight * listItemHeight;
    final double newListItemBottom = (newIndexHighlight + 1) * listItemHeight;
    final double newScrollTop = newListItemTop - listViewTopPadding;
    final double newScrollBottom = newListItemBottom + listViewBottomPadding;
    if (newScrollTop < _scrollController.offset) {
      _scrollController.animateTo(newScrollTop,
          duration: Duration(milliseconds: 500), curve: Curves.ease);
    } else if (newScrollBottom > _scrollController.offset + listViewHeight) {
      _scrollController.animateTo(newScrollBottom - listViewHeight,
          duration: Duration(milliseconds: 500), curve: Curves.ease);
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
      // log('get_word_index_range_in_text(): Found "$word" at position $startIndex-$endIndex');
      if(cursorPosition > startIndex && cursorPosition <= endIndex){
        _currentWord = word!;
        return [startIndex, endIndex];    
      }
    }
    return [0, 0];
  }


  Widget _myTextFild(BuildContext context){
    return Focus(
      onKey: (node, RawKeyEvent event) {
          // 判断在Windows平台则用Ctrl+Enter发送信息
          // 判断在macOS平台则用CMD+Enter发送信息
          if ( GetPlatform.isWindows || GetPlatform.isLinux || GetPlatform.isFuchsia) {
            if (event is RawKeyDownEvent) {
              if (event.isControlPressed && event.isKeyPressed(LogicalKeyboardKey.enter)) {
                // log("ctrl+enter: ${_textController.text.trim()}");
                _handleSubmitted(_textController.text);
                _commentFocus.requestFocus();
                return KeyEventResult.handled;
              }
            }
          }else if (GetPlatform.isMacOS) {
            if (event is RawKeyDownEvent) {
              if (event.isMetaPressed && event.isKeyPressed(LogicalKeyboardKey.enter)) {
                // log("cmd+enter: ${_textController.text.trim()}");
                _handleSubmitted(_textController.text);
                _commentFocus.requestFocus();
                return KeyEventResult.handled;
              }
            }
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
            build_matchWords_list(t, 'arrowUp');
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
            build_matchWords_list(t,'arrowDown');
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
          style: TextStyle(fontSize: 16, color: Colors.black),
          maxLines: 3,
          minLines: 3,
          decoration: InputDecoration(
            hintText: '输入单词或句子' ,
            hintStyle: TextStyle(color: Colors.grey),
            // prefixIcon: IconButton(
            //     color: Colors.grey,
            //     hoverColor: Colors.black54,
            //     onPressed: () {
            //       // messageController.getChatCompletion('gpt-3.5-turbo', 'What is hallucinate?');
            //     }, 
            //     icon: const Icon(Icons.mic_rounded)
            //   ),
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

    _commentFocus = messageController.commentFocus;
    
    return Scaffold(
      appBar: null,
      body: Center(
        child: Row(
          children: [
            Container(
              width: 180,
              constraints: BoxConstraints(
                maxWidth: 180,
                minWidth: 180,
              ),
              decoration: BoxDecoration(
                // color: Color.fromARGB(255, 131, 198, 175),
                color: Color.fromARGB(255, 94, 211, 168).withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  // topLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
                gradient: new LinearGradient(
                  colors: [
                    Color.fromARGB(255, 148, 231, 170),
                    Color.fromARGB(255, 30, 167, 110),
                  ],
                ),
              ),
              child: ListView(
                padding: EdgeInsets.only(top: 10),
                children: <Widget>[
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(5),
                      alignment: AlignmentDirectional.center,
                      child: RichText(
                        text: TextSpan(
                          text: 'Word Pipe',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.black54,
                            fontSize: 18,
                            fontFamily: 'Comfortaa',
                            fontWeight: FontWeight.w600),
                          children: <TextSpan>[
                            TextSpan(
                              text: '  alpha',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: Colors.black54,
                                fontSize: 12),
                            ),
                          ],
                        )
                      ),
                    ),
                  ),
                  Divider(),
                  FutureBuilder<String>(
                    future: c.getUserName(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return SvgPicture.network(
                          "${HTTP_SERVER_HOST}/${AVATAR_FILE_DIR}/${snapshot.data}",
                          height: 80,
                          width: 80,
                          semanticsLabel: 'avatar',
                          placeholderBuilder: (BuildContext context) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.black12,
                            margin: const EdgeInsets.only(right: 8),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Text("${snapshot.error}");
                      }
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.black12,
                        margin: const EdgeInsets.only(right: 8),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.account_circle),
                    title: Text('Profile', style: TextStyle(fontSize: 16)),
                    minLeadingWidth: 0,
                    minVerticalPadding: 0,
                    onTap: () => Get.offAll(UserProfile()),
                  ),
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings', style: TextStyle(fontSize: 16)),
                    minLeadingWidth: 0,
                    minVerticalPadding: 0,
                    onTap: () => Get.offAll(Settings()),
                  ),
                  
                  ListTile(
                    leading: Icon(Icons.info),
                    title: Text('About', style: TextStyle(fontSize: 16)),
                    minLeadingWidth: 0,
                    minVerticalPadding: 0,
                    onTap: () => Get.offAll(AboutUs()),
                  ),
                  Divider(),
                  Obx(() {
                    return SwitchListTile(
                      activeColor: Colors.green[600],
                      activeTrackColor: Colors.green[100],
                      inactiveThumbColor: Colors.green[200],
                      inactiveTrackColor: Colors.green[100],
                      title: Text('English Input Helper', 
                      style: TextStyle(fontSize: 12)), 
                      value:  settingsController.englishInputHelperConfig.value, 
                      onChanged: ((bool value) {
                        settingsController.toggleEnglishInputHelper(value);
                      }
                      )
                    );
                  }),
                  Obx(() {
                    return SwitchListTile(
                      activeColor: Colors.green[600],
                      activeTrackColor: Colors.green[100],
                      inactiveThumbColor: Colors.green[200],
                      inactiveTrackColor: Colors.green[100],
                      title: Text('Free-Chat Mode', style: TextStyle(fontSize: 12)), 
                      // subtitle: Text('PRO only', style: TextStyle(fontSize: 10, color: Colors.blue)),
                      value: settingsController.freeChatMode.value,
                      onChanged: ((bool value) {
                        if (value==true){
                          c.getPremium().then((premiumType) {
                            if (premiumType != 0) {
                              settingsController.toggleFreeChatMode(value);
                              messageController.messages.clear();
                              messageController.messsage_view_first_build = true;
                              messageController.conversation_id.value = -1;
                              _commentFocus.requestFocus();
                            } else {
                              if (settingsController.openAiApiKey.value != '') {
                                settingsController.toggleFreeChatMode(value);
                                messageController.messages.clear();
                                messageController.messsage_view_first_build = true;
                                messageController.conversation_id.value = -1;
                                _commentFocus.requestFocus();
                              } else {
                                settingsController.freeChatMode.value = false;
                                customSnackBar(title: "Error", content: "Please config OpenAI key in config page or upgrade to PRO version.");
                              }
                            }
                          });
                        }else{
                          // 重新加载非free-chat聊天记录
                          settingsController.toggleFreeChatMode(value);
                          messageController.messages.clear();
                          messageController.lastSegmentBeginId = 0;
                          messageController.messsage_view_first_build = true;
                          messageController.conversation_id.value = 0;
                          _commentFocus.requestFocus();
                        }
                      }),
                    );                    
                  },)
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(0),
                      child: 
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              alignment: Alignment.topCenter,
                              color: Colors.white24,
                              child: Column(
                                children: [
                                  Container(
                                    height: 50,
                                    color: Colors.grey[200],
                                    padding: const EdgeInsets.fromLTRB(20, 5, 5, 5),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text('Jasmine', style: TextStyle(fontFamily: 'Comfortaa', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.green[900])),
                                        IconButton(onPressed: ()=>{
                                          customSnackBar(title: "Info", content: "not open yet")
                                        }, icon: Icon(Icons.more_vert))
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ConversationView(),
                                  ),
                                ],
                              )
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
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Live vocab experience',
                                              style: TextStyle(
                                                fontSize: 16, 
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Comfortaa',
                                                fontFamilyFallback: ['Arial']
                                                ),
                                            ),
                                            Text(
                                              '↑↓ to choose word\n⏎ to confirm',
                                              style: TextStyle(fontSize: 10),
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
                                              child: SizedBox(
                                                height: 350,
                                                child: GetPlatform.isMobile
                                                ? Obx(
                                                  () => ListView.builder(
                                                    itemBuilder: (_, int index) => InkWell(
                                                      onDoubleTap: () {
                                                        customSnackBar(title: "select word", content: _matchWords[index].text);
                                                      },
                                                      child: _matchWords[index],
                                                    ),
                                                    reverse: false,
                                                    itemCount: _matchWords.length,
                                                    shrinkWrap: true,
                                                    primary: true,
                                                  ),
                                                )
                                                : SingleChildScrollView(
                                                  controller: _scrollController,
                                                  scrollDirection: Axis.vertical,
                                                  child: Obx(
                                                    () => ListView.builder(
                                                      itemBuilder: (_, int index) => InkWell(
                                                        onDoubleTap: () {
                                                          print('isDesktop:You double tapped on ${_matchWords[index].text}');
                                                        },
                                                        child: _matchWords[index],
                                                      ),
                                                      reverse: false,
                                                      itemCount: _matchWords.length,
                                                      shrinkWrap: true,
                                                      primary: true,
                                                    ),
                                                  ),
                                                ),
                                              ),
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
                                                            style: TextStyle(fontSize: 16)
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
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
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
                        Ink(
                          decoration: const ShapeDecoration(
                            color: CustomColors.gradientEnd,
                            shape: CircleBorder(),
                          ),
                          child: Tooltip(
                            message: 'Not open yet',
                            child: IconButton(
                              color: Colors.grey,
                              hoverColor: Colors.black54,
                              onPressed: () {
                          
                              }, 
                              icon: const Icon(Icons.mic_rounded)
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: _myTextFild(context),
                          )
                        ),
                        Container(
                          width: 45,
                          height: 40,
                          margin: EdgeInsets.only(left: 5),
                          decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.green[900],
                          ),
                          child: Tooltip(
                            message: GetPlatform.isMacOS ? '⌘+Enter to send' : 'Ctrl+Enter to send',
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                  ),
                                padding: const EdgeInsets.all(0),
                              ),
                              onPressed: () {
                                _handleSubmitted(_textController.text);
                                _commentFocus.requestFocus();
                              },
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                            ),
                          )
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
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
    return TextSpan(children: children,style: TextStyle(fontSize: 14,color: Colors.blue,),);
  }else{
    return TextSpan(text: "");
  }
}

class MatchWords extends StatelessWidget {
  const MatchWords({
    Key? key,
    required this.text,
    required this.fullMatch,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  final String text;
  final bool fullMatch;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = TextStyle(
        color: Colors.black87,
        backgroundColor:
            isSelected ? Colors.greenAccent : Colors.transparent,
        fontSize: 12,
        fontWeight: fullMatch ? FontWeight.bold : FontWeight.normal,
        );

    return SizedBox(
      height: 20,
      child: InkWell(
        onTap: onTap,
        child: Text(text, style: textStyle),
      ),
    );
  }
}


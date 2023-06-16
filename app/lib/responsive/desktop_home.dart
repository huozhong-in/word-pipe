import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:wordpipe/config.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/conversation_view.dart';
import 'package:wordpipe/user_profile.dart';
import 'package:wordpipe/MessageController.dart';
import 'package:wordpipe/settings.dart';
import 'package:wordpipe/about_us.dart';
import 'package:wordpipe/custom_widgets.dart';
import 'package:updat/updat.dart';
import 'package:updat/theme/chips/default.dart';
import 'package:flutter_desktop_audio_recorder/flutter_desktop_audio_recorder.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:developer';

// ignore: must_be_immutable
class DesktopHome extends StatelessWidget {
  DesktopHome({super.key});
  final Controller c = Get.find<Controller>();
  final MessageController messageController = Get.find<MessageController>();
  final SettingsController settingsController = Get.find<SettingsController>();
  late String _username = "";
  final List<MatchWords> _matchWords = <MatchWords>[].obs;
  final TextEditingController _textController = TextEditingController();
  late FocusNode _commentFocus;
  late int _indexHighlight = 0; // 此变量用于记录当前选中的匹配单词的索引
  late String _currentWord = ""; // 文本框中输入光标所在的单词
  late int _leftOrRight = 0; // 此变量用于记录当按下键盘左右键时，光标应向左移动还是向右移动，-1表示向左，1表示向右，0表示未移动
  late final Map<String, String> _wordDetail = <String, String>{}.obs;
  ScrollController _scrollController = ScrollController();
  final TextEditingController conversationNameController = TextEditingController();

  RxBool _hasMicPermission = false.obs;
  FlutterDesktopAudioRecorder recorder = FlutterDesktopAudioRecorder();
  RxString _m4aFileName = "".obs;
  RxBool _isRecording = false.obs;
  RxDouble recordProgress = 0.0.obs;
  RxDouble playProgress = 0.0.obs;
  Timer? timer;
  Rx<Stream<WaveformProgress>> progressStream = Rx(Stream.empty());
  RxString stt_string = "".obs;


  Future<String> _getUserName() async {
    _username = await c.getUserName();
    return _username;
  }

  void _handleSubmitted(String text) async {
     if( _username == "")
      return;
    if(_m4aFileName.value == "" && text.trim() == "")
      return;
    // 如果conversation_id == -1，说明是新话题，需要先创建话题，话题ID是服务端生成返回
    if (messageController.conversation_id.value == -1){
      messageController.conversation_id.value = await messageController.conversation_CUD(_username, "create", messageController.conversation_id.value);
    }
    if(_m4aFileName.value != ""){
      // 发送语音消息
      if (stt_string.value.trim() == ''){
        customSnackBar(title: "语音转文字失败", content: "请重新录音");
        return;
      }
      Map<String, dynamic> ret = await
        messageController.voiceChat(_username, stt_string.value.trim(), _m4aFileName.value, messageController.conversation_id.value);
      if(ret['errcode'] as int == 0){
        deleteAllTempAudioFiles();
      }
      return;
    }else if (text.trim() != ""){
      // 发送文本消息
      Map<String, dynamic> ret = await messageController.chat(_username, text.trim(), messageController.conversation_id.value);
      if(ret['errcode'] as int == 0){
        _textController.clear();
        _matchWords.clear();
        _indexHighlight = 0;
        if (settingsController.freeChatMode.value == true){
          messageController.freeChat('gpt-3.5-turbo', messageController.conversation_id.value, text);
        }
      }else{
        customSnackBar(title: "发生错误", content: ret['errmsg'] as String);
      }
    }
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
        c.searchWords(currentWordPart.toLowerCase()).then((value){
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
        c.getWord(element).then((m){
          _wordDetail.clear();
          if (m.length != 0 && m[0] != null){
            try{
              Map<String, dynamic> stringMap = Map<String, dynamic>.from(m[0]);
              stringMap.forEach((key, value) {
                _wordDetail[key] = value.toString();
              });
            }catch(e){
              _wordDetail.clear();
              log("build_matchWords_list($element) " + e.toString());
            }
            
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


  Widget _myTextField(BuildContext context){
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
      child: Obx(() {
        return TextField(
          focusNode: _commentFocus,
          autofocus: true,
          controller: _textController,
          onChanged: (value) {
            _handleMatchWords(_textController.text);
          },
          textInputAction: TextInputAction.newline,
          style: TextStyle(fontSize: settingsController.fontSizeConfig.value, color: Colors.black),
          maxLines: 3,
          minLines: 3,
          decoration: InputDecoration(
            hintText: '跟Jasmine聊点什么呢' ,
            hintStyle: TextStyle(color: Colors.grey),
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
          ),
        );
      },)
      );
  }

  Future<void> _showWaveforms(String fileName) async {
    try {
      final Uint8List audioData = File(p.join((await getTemporaryDirectory()).path, '$fileName.m4a')).readAsBytesSync();
      final File audioFile = File(p.join((await getTemporaryDirectory()).path, '$fileName.bak.m4a'));
      audioFile.writeAsBytesSync(audioData);
      final waveFile = File(p.join((await getTemporaryDirectory()).path, '$fileName.wave'));
      // 学习一下这篇文章，随语音录入实时显示波形 https://coldstone.fun/post/2020/04/13/flutter-stream/
      progressStream.value = JustWaveform.extract(
        audioInFile: audioFile, 
        waveOutFile: waveFile,
        // zoom: const WaveformZoom.pixelsPerSecond(100)
      ).asBroadcastStream();
      // progressStream.value.listen((waveformProgress) {
      //   // print('Progress: %${(100 * waveformProgress.progress).toInt()}');
      //   if (waveformProgress.waveform != null) {
      //     print(waveformProgress.waveform!.sampleRate);
      //   }
      // });
      stt();
    } catch (e) {
      print(e);
    }
  }

  Future<void> stt() async {
    // 对音频进行文字识别
    Directory temporaryDirectory = await getTemporaryDirectory();
    String filePath = temporaryDirectory.path + '/' + _m4aFileName.value + '.m4a';
    stt_string.value = await messageController.convertSpeechToText(filePath);
  }

  Widget _myWaveformsBar(BuildContext context){
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  child: Obx(() {
                    return StreamBuilder<WaveformProgress>(
                      stream: progressStream.value,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        // final progress = snapshot.data?.progress ?? 0.0;
                        // if(progress==1){
                        //   print('waveform.duration: ${waveform.duration}');
                        // }
                        final waveform = snapshot.data?.waveform;
                        if (waveform == null) {
                          return Center(
                            child: SpinKitWave(color: Colors.blue, type: SpinKitWaveType.start),
                            // child: Text(
                            //   '${(100 * progress).toInt()}%',
                            //   style: Theme.of(context).textTheme.titleLarge,
                            // ),
                          );
                        }
                        return AudioWaveformWidget(
                          waveform: waveform,
                          start: Duration.zero,
                          duration: waveform.duration,
                        );
                      },
                    );
                  },),
                ),
              ),
              Container(
                alignment: AlignmentDirectional.topEnd,
                child: IconButton(
                  tooltip: '删除录音',
                  color: Colors.red[100],
                  hoverColor: Colors.red[200],
                  iconSize: 20,
                  onPressed: () async {
                    deleteAllTempAudioFiles();
                  }, 
                  icon: Icon(Icons.cancel, color: Colors.red[100])
                ),
              ),
            ],
          ),          
          Container(
            height: 50,
            width: double.infinity,
            margin: EdgeInsets.all(0),
            padding: EdgeInsets.all(0),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Obx(() => Text(stt_string.value , style: TextStyle(fontSize: 16), softWrap: true,)),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> deleteAllTempAudioFiles() async {
    Future<bool> result = Future.value(false);
    if (messageController.voicePlayer.playerState.playing){
      await messageController.voicePlayer.pause();
    }
    try {
      Directory temporaryDirectory = await getTemporaryDirectory();
      temporaryDirectory.listSync().forEach((element) {
        if (element.path.endsWith('.m4a') || element.path.endsWith('.wave')){
          element.deleteSync();
        }
      });
      result = Future.value(true);
    } catch (e) {
      log(e.toString());
      result = Future.value(false);
    } finally {
      _m4aFileName.value = '';
      messageController.whichIsPlaying.value = '';
      stt_string.value = '';
      return result;
    }
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
              width: 200,
              constraints: BoxConstraints(
                maxWidth: 200,
                minWidth: 200,
              ),
              decoration: BoxDecoration(
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
                padding: EdgeInsets.only(top: 30),
                children: <Widget>[
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(5),
                      alignment: AlignmentDirectional.center,
                      child: WordPipeLogo(context),
                    ),
                  ),
                  Divider(),
                  Container(
                    width: 100,
                    height: 100,
                    child: FutureBuilder<String>(
                      future: _getUserName(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return CachedNetworkImage(
                            imageUrl: "${HTTP_SERVER_HOST}/${AVATAR_FILE_DIR}/${snapshot.data}",
                            imageBuilder: (context, imageProvider) => Container(
                              width: 100,
                              height: 100,
                              // margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.scaleDown,
                                ),
                              ),
                            ),
                            placeholder: (context, url) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.black12,
                              // margin: const EdgeInsets.only(right: 8),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                          );
                        } else if (snapshot.hasError) {
                          return Text("${snapshot.error}");
                        }
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.black12,
                          // margin: const EdgeInsets.only(right: 8),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.account_circle),
                    title: Text('我的', style: TextStyle(fontSize: 16)),
                    minLeadingWidth: 0,
                    minVerticalPadding: 0,
                    onTap: () => Get.offAll(() => UserProfile()),
                  ),
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('功能设置', style: TextStyle(fontSize: 16)),
                    minLeadingWidth: 0,
                    minVerticalPadding: 0,
                    onTap: () => Get.offAll(() => Settings()),
                  ),
                  ListTile(
                    leading: Icon(Icons.info),
                    title: Text('关于WordPipe', style: TextStyle(fontSize: 16)),
                    minLeadingWidth: 0,
                    minVerticalPadding: 0,
                    onTap: () => Get.offAll(() => AboutUs()),
                  ),
                  FutureBuilder<String>(
                    future: c.getWordPipeAppVersion(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data! == '0.0.0')
                          return Container();
                        
                        return Padding(
                          padding: const EdgeInsets.only(left: 22, right: 22, top: 16, bottom: 16),
                          child: UpdatWidget(
                            getLatestVersion: () async {
                              // Github gives us a super useful latest endpoint, and we can use it to get the latest stable release
                              final data = await http.get(Uri.parse(
                                "https://api.github.com/repos/huozhong-in/word-pipe/releases/latest",
                              ));
                      
                              // Return the tag name, which is always a semantically versioned string.
                              return jsonDecode(data.body)["tag_name"];
                            },
                            getBinaryUrl: (version) async {
                              // Github also gives us a great way to download the binary for a certain release (as long as we use a consistent naming scheme)
                      
                              // Make sure that this link includes the platform extension with which to save your binary.
                              // If you use https://exapmle.com/latest/macos for instance then you need to create your own file using `getDownloadFileLocation`
                              String platformExt = "";
                              GetPlatform.isMacOS ? platformExt = "dmg" : platformExt = "exe";
                              return "https://github.com/huozhong-in/word-pipe/releases/download/$version/WordPipe-${Platform.operatingSystem}-$version.$platformExt";
                            },
                            appName: "WordPipe", // This is used to name the downloaded files.
                            getChangelog: (_, __) async {
                              // That same latest endpoint gives us access to a markdown-flavored release body. Perfect!
                              final data = await http.get(Uri.parse(
                                "https://api.github.com/repos/huozhong-in/word-pipe/releases/latest",
                              ));
                              return jsonDecode(data.body)["body"];
                            },
                            updateChipBuilder: defaultChip,
                            openOnDownload: true,
                            closeOnInstall: true,
                            currentVersion: snapshot.data!,
                            callback: (status) {
                              // print(status);
                              // print('currentVersion: ${snapshot.data!}');
                            },
                          )
                        );
                      // } else if (snapshot.hasError) {
                      //   return Text("${snapshot.error}");
                      }
                      return Center(child: CircularProgressIndicator());
                    },
                  ),
                  Divider(),
                  Obx(() {
                    return SwitchListTile(
                      activeColor: Colors.green[600],
                      activeTrackColor: Colors.green[100],
                      inactiveThumbColor: Colors.green[200],
                      inactiveTrackColor: Colors.green[100],
                      title: Text('英语打字助手', 
                      style: TextStyle(fontSize: 14)), 
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
                      title: Text('连续对话模式', style: TextStyle(fontSize: 14)), 
                      // subtitle: Text('会员专享', style: TextStyle(fontSize: 12, color: Colors.blue)),
                      value: settingsController.freeChatMode.value,
                      onChanged: ((bool value) async {
                        if (value==true){
                          int premiumType = await c.getPremium();
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
                              customSnackBar(title: "试用已结束", content: "请配置自己的OpenAI API key或升级为付费会员.");
                            }
                          }
                        }else{
                          // 重新加载非free-chat聊天记录
                          settingsController.toggleFreeChatMode(value);
                          messageController.messages.clear();
                          messageController.lastSegmentBeginId = 0;
                          messageController.messsage_view_first_build = true;
                          messageController.conversation_id.value = 0;
                          messageController.selectedConversationName.value = '';
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
                                        Text('Jasmine', style: TextStyle(fontFamily: 'Roboto', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.green[900])),
                                        Obx(() {
                                          return Text(
                                            messageController.selectedConversationName.value, 
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[900]),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          );                                          
                                        }),
                                        PopupMenuButton(
                                          icon: Icon(Icons.more_vert),
                                          iconSize: 24,
                                          tooltip: '当前话题',
                                          onSelected: (value) async {
                                            if (value == 'edit') {
                                              // show a dialog for modify messageControll.seletedConversationName
                                              conversationNameController.text = messageController.selectedConversationName.value;
                                              Get.defaultDialog(
                                                title: '编辑',
                                                content: TextField(
                                                  controller: conversationNameController,
                                                  decoration: InputDecoration(
                                                    border: OutlineInputBorder(),
                                                    labelText: '话题名称',
                                                  ),
                                                  maxLength: 50,
                                                ),
                                                textConfirm: '保存',
                                                textCancel: '取消',
                                                confirmTextColor: Colors.white,
                                                buttonColor: Colors.green,
                                                onConfirm: () async {
                                                  // update conversation name
                                                  if (await messageController.updateConversationName(messageController.conversation_id.value, conversationNameController.text)){
                                                    Get.back();
                                                  }else{
                                                    print('update error');
                                                  }
                                                },
                                              );
                                            } else if (value == 'delete') {
                                              // show a dialog for delete messageControll.radioListTile current item
                                              Get.defaultDialog(
                                                title: '删除话题',
                                                content: Text('你确定要删除当前话题记录吗?'),
                                                textConfirm: '删除',
                                                textCancel: '取消',
                                                confirmTextColor: Colors.white,
                                                buttonColor: Colors.red,
                                                onConfirm: () async {
                                                  // delete conversation
                                                  if (await messageController.deleteConversation(messageController.conversation_id.value)){
                                                    Get.back();
                                                  }else{
                                                    print('delete error');
                                                  }
                                                },
                                              );
                                            }
                                          },
                                          itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                                            PopupMenuItem(
                                              enabled: messageController.conversation_id.value > 0,
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, color: messageController.conversation_id.value > 0 ?Colors.black:Colors.grey,),
                                                  SizedBox(width: 10),
                                                  Text('修改名称', style: TextStyle(fontSize: 14, color: messageController.conversation_id.value > 0 ?Colors.black:Colors.grey)),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              enabled: messageController.conversation_id.value > 0,
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, color: messageController.conversation_id.value > 0 ?Colors.black:Colors.grey,),
                                                  SizedBox(width: 10),
                                                  Text('删除话题', style: TextStyle(fontSize: 14, color: messageController.conversation_id.value > 0 ?Colors.black:Colors.grey)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
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
                                  left: 30,
                                  right: 30,
                                  bottom: 0,
                                  child: Container(
                                    height: 420,
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
                                              '实时拼写提示',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            Text(
                                              '↑↓或鼠标点击选择单词\n⏎ 确认上屏',
                                              style: TextStyle(fontSize: 12),
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
                                                        customSnackBar(title: "选择条目", content: _matchWords[index].text);
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
                        Obx(() {
                          final String keyString = "[VOICEINPUT]";
                          
                          // 播放语音和暂停播放按钮的显示和控制逻辑
                          // print("whichIsPlaying: " + messageController.whichIsPlaying.value);
                          if (_m4aFileName.value!='' && _isRecording.value==false){
                            return IconButton(
                              iconSize: 35,
                              onPressed: () async {
                                // 判断已经是当前音频的播放状态，则点击暂停
                                if (messageController.whichIsPlaying.value == keyString) {
                                  if (messageController.buttonNotifier.value == ButtonState.playing) {
                                    messageController.buttonNotifier.value = ButtonState.paused;
                                    messageController.voicePlayer.pause();
                                  } else if (messageController.buttonNotifier.value == ButtonState.paused) {
                                    messageController.buttonNotifier.value = ButtonState.playing;
                                    messageController.voicePlayer.play();
                                  }
                                }else{
                                  // 如果是在播放其他音频，则先停止播放，重新设置正在播放的音频
                                  Directory temporaryDirectory = await getTemporaryDirectory();
                                  final String filePath = temporaryDirectory.path + '/' + _m4aFileName.value + '.m4a';
                                  messageController.playVoice(keyString, filePath, false);
                                }
                              },
                              icon:  Obx(() {
                                if (messageController.whichIsPlaying.value == keyString) {
                                  switch (messageController.buttonNotifier.value) {
                                    case ButtonState.paused:
                                      return Icon(Icons.play_arrow, color: Colors.grey);
                                    case ButtonState.playing:
                                      return Icon(Icons.pause, color: Colors.grey);
                                    default:
                                      return Icon(Icons.play_arrow, color: Colors.grey);
                                  }
                                } else {
                                  return Icon(Icons.play_arrow, color: Colors.grey);
                                }
                              }),
                            );
                          }

                          // 录音按钮的显示和控制逻辑
                          return Stack(
                            children: <Widget>[
                              Positioned.fill(
                                child: CircularProgressIndicator(
                                  value: _isRecording.value? 1 - recordProgress.value / 60 : 0,
                                  valueColor: AlwaysStoppedAnimation(Colors.redAccent[100]),
                                  strokeWidth: 5,
                                ),
                              ),
                              Center(
                                child: IconButton(
                                  hoverColor: Colors.greenAccent[100],
                                  tooltip: '录制语音',
                                  iconSize: 35,
                                  onPressed: () async {
                                    _hasMicPermission.value = await recorder.hasMicPermission();
                                    if(_hasMicPermission.value){
                                      Directory temporaryDirectory = await getTemporaryDirectory();
                                      
                                      if(_isRecording.value){
                                        if(await recorder.isRecording()){
                                          timer?.cancel();
                                          recorder.stop();
                                          recordProgress.value = 0;
                                        }
                                        _isRecording.value = false;
                                        final String filePath = temporaryDirectory.path + '/' + _m4aFileName.value + '.m4a';
                                        _showWaveforms(_m4aFileName.value).then((_) => messageController.playVoice(keyString, filePath, false));
                                      }else{
                                        _m4aFileName.value = DateTime.now().millisecondsSinceEpoch.toString();
                                        if (messageController.voicePlayer.playerState.playing){
                                          await messageController.voicePlayer.pause();
                                        }
                                        recorder.start(path: temporaryDirectory.path, fileName: _m4aFileName.value)
                                          .then((_) {
                                            _isRecording.value = true;
                                            timer = Timer.periodic(Duration(seconds: 1), (_) {
                                              if (recordProgress.value < 60) {
                                                recordProgress.value++;
                                              } else {
                                                timer?.cancel();
                                                recorder.stop();
                                                _isRecording.value = false;
                                                recordProgress.value = 0;
                                                final String filePath = temporaryDirectory.path + '/' + _m4aFileName.value + '.m4a';
                                                _showWaveforms(_m4aFileName.value).then((_) => messageController.playVoice(keyString, filePath, false));
                                              }
                                            });
                                          });
                                      }
                                    }else{
                                      customSnackBar(title: "没有麦克风权限", content: "请在设置中打开麦克风权限: \n设置->隐私与安全->麦克风->WordPipe");
                                      recorder.requestMicPermission();
                                    }
                                  }, 
                                  icon: Icon(Icons.mic_rounded, color: _isRecording.value? Colors.redAccent[100] : Colors.grey)
                                ),
                              )   
                            ],
                          );
                        },),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Obx(() {
                              if(_m4aFileName.value != ""){
                                return _myWaveformsBar(context);
                              }else{
                                return _myTextField(context);
                              }
                            },)
                          )
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                          // decoration: BoxDecoration(
                          //       borderRadius: BorderRadius.circular(25.0),
                          //       color: Colors.green[900],
                          // ),
                          child: Tooltip(
                            message: GetPlatform.isMacOS ? '⌘+Enter 发送' : 'Ctrl+Enter 发送',
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 1,
                                backgroundColor: Color.fromARGB(255, 59, 214, 157),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                ),
                                padding: const EdgeInsets.only(left: 5),
                              ),
                              onPressed: () {
                                _handleSubmitted(_textController.text);
                                _commentFocus.requestFocus();
                              },
                              child: const Icon(Icons.send_rounded, color: Colors.black54, size: 30),
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
        ));
      children.add(const TextSpan(text: ' '));
      }
      return TextSpan(children: children, style: const TextStyle(fontSize: 16,color: Colors.white, backgroundColor: Colors.teal));
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
      ));
      if(wordList.length>1){
        children.add(TextSpan(
          text: wordList[1],
        ));
      }
    children.add(const TextSpan(text: '\n'));
    }
    return TextSpan(children: children, style: const TextStyle(fontSize: 16,color: Colors.teal),);
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
          text: wordList[1]+"%"
        ));
      }
    children.add(const TextSpan(text: ' '));
    }
    return TextSpan(children: children, style: TextStyle(fontSize: 16,color: Colors.blue,),);
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
        fontSize: 16,
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


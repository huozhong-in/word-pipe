import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wordpipe/config.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/MessageController.dart';
import 'dart:math' as math;
import 'package:just_waveform/just_waveform.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Widget customRadioListTile(Map<String, dynamic> item) {
  final MessageController messageController = Get.find<MessageController>();
  final int pkConversation = item['pk_conversation'];


  return Obx(() {

    messageController.conversationNameMap[pkConversation] = item['conversation_name'].toString();
    
    return RadioListTile<int>(
      value: pkConversation,
      groupValue: messageController.conversation_id.value,
      key: Key(pkConversation.toString()),
      onChanged: (value) {
        messageController.messages.clear();
        messageController.lastSegmentBeginId = 0;
        messageController.messsage_view_first_build = true;
        messageController.conversation_id.value = value!;
        messageController.selectedConversationName.value = item['conversation_name'].toString().trim() == '' ? '未命名话题' : item['conversation_name'].toString();
        if (messageController.scaffoldKey.currentState != null && messageController.scaffoldKey.currentState!.hasDrawer && messageController.scaffoldKey.currentState!.isDrawerOpen){
          messageController.scaffoldKey.currentState!.closeDrawer();
        }
        messageController.commentFocus.requestFocus();
        // print(messageController.conversation_id.value);
      },
      title: Text(
        item['conversation_name'].toString().trim() == '' ? '未命名话题' : item['conversation_name'].toString(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: appThemeBright.textTheme.bodyMedium,
      ),
      activeColor: Colors.green[900],
      contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      selected: messageController.conversation_id.value == pkConversation,
      tileColor: Color.fromARGB(255, 94, 211, 168).withOpacity(0.5),
      selectedTileColor: Color.fromARGB(255, 94, 211, 168).withOpacity(0.5),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: messageController.conversation_id.value == pkConversation ? Colors.green[900]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
    );
    
  });
}


// ignore: must_be_immutable
class QuestionButtons extends StatelessWidget {
  final settingsController = Get.find<SettingsController>();
  
  final String answer;
  RxString iconA = 'help_outline'.obs;
  RxString iconB = 'help_outline'.obs;
  RxString iconC = 'help_outline'.obs;
  RxString iconD = 'help_outline'.obs;
  
  QuestionButtons({required this.answer});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Container(
          margin: EdgeInsetsDirectional.symmetric(horizontal: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              if(answer == 'A') {
                iconA.value = 'check'; 
              } else {
                iconA.value = 'close';
              }
            },
            icon: Obx(() => Icon(
              iconA.value == 'help_outline' ? Icons.help_outline :
              iconA.value == 'check' ? Icons.check : 
              Icons.close,
              color: Colors.blue[900],
            )),
            label: Text('A', style: TextStyle(fontSize: settingsController.fontSizeConfig.value, color: Colors.blue[900]),)   
          ),
        ),
        Container(
          margin: EdgeInsetsDirectional.symmetric(horizontal: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              if(answer == 'B') {
                iconB.value = 'check'; 
              } else {
                iconB.value = 'close';
              }
            },
            icon: Obx(() => Icon(
              iconB.value == 'help_outline' ? Icons.help_outline :
              iconB.value == 'check' ? Icons.check : 
              Icons.close,
              color: Colors.blue[900],
            )),
            label: Text('B', style: TextStyle(fontSize: settingsController.fontSizeConfig.value, color: Colors.blue[900]),)   
          ),
        ),
        Container(
          margin: EdgeInsetsDirectional.symmetric(horizontal: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              if(answer == 'C') {
                iconC.value = 'check'; 
              } else {
                iconC.value = 'close';
              }
            },
            icon: Obx(() => Icon(
              iconC.value == 'help_outline' ? Icons.help_outline :
              iconC.value == 'check' ? Icons.check : 
              Icons.close,
              color: Colors.blue[900],
            )),
            label: Text('C', style: TextStyle(fontSize: settingsController.fontSizeConfig.value, color: Colors.blue[900]),)   
          ),
        ),
        Container(
          margin: EdgeInsetsDirectional.symmetric(horizontal: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              if(answer == 'D') {
                iconD.value = 'check'; 
              } else {
                iconD.value = 'close';
              }
            },
            icon: Obx(() => Icon(
              iconD.value == 'help_outline' ? Icons.help_outline :
              iconD.value == 'check' ? Icons.check : 
              Icons.close,
              color: Colors.blue[900],
            )),
            label: Text('D', style: TextStyle(fontSize: settingsController.fontSizeConfig.value, color: Colors.blue[900]),)   
          ),
        )
      ],
    );
  }
}

SnackbarController customSnackBar({required String title, required String content}) {
  return Get.snackbar(title, content,
    snackPosition: SnackPosition.TOP,
    backgroundColor: Colors.black54,
    colorText: Colors.white,
    margin: const EdgeInsets.all(1),
    borderRadius: 8,
    duration: const Duration(seconds: 2),
    icon: const Icon(Icons.error, color: Colors.white),
    maxWidth: 375,
  );
}

// enum ActivityType {
//   running(1, 'Running'),
//   climbing(2, 'Climbing'),
//   hiking(5, 'Hiking'),
//   cycling(7, 'Cycling'),
//   ski(10, 'Skiing');

//   const ActivityType(this.number, this.value);
  
//   final int number;
//   final String value;
//   static ActivityType getTypeByTitle(String title) =>
//     ActivityType.values.firstWhere((activity) => activity.name == title);
//   static ActivityType getType(int number) => ActivityType.values.firstWhere((activity) => activity.number == number);

//   static String getValue(int number) => ActivityType.values.firstWhere((activity) => activity.number == number).value;
// }

class Utilities {
  static Future<String> getVoiceFilePath() async {
    // Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    Directory temporaryDirectory = await getTemporaryDirectory();
    return temporaryDirectory.path;
  }
}

class AudioWaveformWidget extends StatefulWidget {
  final Color waveColor;
  final double scale;
  final double strokeWidth;
  final double pixelsPerStep;
  final Waveform waveform;
  final Duration start;
  final Duration duration;

  const AudioWaveformWidget({
    Key? key,
    required this.waveform,
    required this.start,
    required this.duration,
    this.waveColor = Colors.blue,
    this.scale = 1.0,
    this.strokeWidth = 5.0,
    this.pixelsPerStep = 8.0,
  }) : super(key: key);

  @override
  _AudioWaveformState createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveformWidget> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, 100.0),
      painter: AudioWaveformPainter(
        waveColor: widget.waveColor,
        waveform: widget.waveform,
        start: widget.start,
        duration: widget.duration,
        scale: widget.scale,
        strokeWidth: widget.strokeWidth,
        pixelsPerStep: widget.pixelsPerStep,
      ),
    );
  }
}

class AudioWaveformPainter extends CustomPainter {
  final double scale;
  final double strokeWidth;
  final double pixelsPerStep;
  final Paint wavePaint;
  final Waveform waveform;
  final Duration start;
  final Duration duration;

  AudioWaveformPainter({
    required this.waveform,
    required this.start,
    required this.duration,
    Color waveColor = Colors.blue,
    this.scale = 1.0,
    this.strokeWidth = 5.0,
    this.pixelsPerStep = 8.0,
  }) : wavePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = waveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (duration == Duration.zero) return;

    double width = size.width;
    double height = size.height;

    final waveformPixelsPerWindow = waveform.positionToPixel(duration).toInt();
    final waveformPixelsPerDevicePixel = waveformPixelsPerWindow / width;
    final waveformPixelsPerStep = waveformPixelsPerDevicePixel * pixelsPerStep;
    final sampleOffset = waveform.positionToPixel(start);
    final sampleStart = -sampleOffset % waveformPixelsPerStep;
    for (var i = sampleStart.toDouble();
        i <= waveformPixelsPerWindow + 1.0;
        i += waveformPixelsPerStep) {
      final sampleIdx = (sampleOffset + i).toInt();
      final x = i / waveformPixelsPerDevicePixel;
      final minY = normalise(waveform.getPixelMin(sampleIdx), height);
      final maxY = normalise(waveform.getPixelMax(sampleIdx), height);
      canvas.drawLine(
        Offset(x + strokeWidth / 2, math.max(strokeWidth * 0.75, minY)),
        Offset(x + strokeWidth / 2, math.min(height - strokeWidth * 0.75, maxY)),
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AudioWaveformPainter oldDelegate) {
    return false;
  }

  double normalise(int s, double height) {
    if (waveform.flags == 0) {
      final y = 32768 + (scale * s).clamp(-32768.0, 32767.0).toDouble();
      return height - 1 - y * height / 65536;
    } else {
      final y = 128 + (scale * s).clamp(-128.0, 127.0).toDouble();
      return height - 1 - y * height / 256;
    }
  }
}

Widget WordPipeLogo(BuildContext context){
  final Controller c = Get.find();
  return FutureBuilder<String>(
    future: c.getWordPipeAppVersion(), 
    builder: (context, snapshot){
      if (snapshot.hasData) {
        return RichText(
          text: TextSpan(
            text: 'WordPipe',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.black54,
              fontSize: 26,
              fontFamily: 'SofadiOne'
            ),
            children: <TextSpan>[
              TextSpan(
                text: '  ' + snapshot.data!,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.blue,
                  fontSize: 12
                ),
              ),
            ],
          )
        );
      } else if (snapshot.hasError) {
        return Text("${snapshot.error}");
      }
      return RichText(
        text: TextSpan(
          text: 'WordPipe',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.black54,
            fontSize: 26,
            fontFamily: 'SofadiOne'
          )
        )
      );
    },
  );
}
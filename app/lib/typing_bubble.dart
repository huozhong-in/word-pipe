import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TypingBubble extends StatelessWidget{
  final String sender;
  final List<dynamic> dataList;
  final Key key;

  const TypingBubble({required this.sender, required this.dataList, required this.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: const TextStyle(
              fontSize: 12.0,
              color: Colors.black54,
            ),
          ),
          const SizedBox(
            height: 2.0,
          ),
          Lottie.network('https://assets6.lottiefiles.com/packages/lf20_nZBVpi.json', width: 30, height: 20, repeat: true, animate: true),

          // Material(
          //   elevation: 5.0,
          //   borderRadius: BorderRadius.circular(5.0),
          //   color: Colors.blueAccent,
          //   child: Padding(
          //     padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
          //     child: Text(
          //       '${dataList[0]}',
          //       style: const TextStyle(
          //         color: Colors.white,
          //         fontSize: 15.0,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
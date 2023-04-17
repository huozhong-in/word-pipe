import 'package:flutter/material.dart';
import 'package:wordpipe/responsive/mobile_sign_in.dart';
import 'package:wordpipe/config.dart';

class DesktopSignIn extends StatelessWidget {
  const DesktopSignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
                gradient: new LinearGradient(
                  colors: [
                    Color.fromARGB(255, 118, 232, 169),
                    Color.fromARGB(255, 32, 220, 161),
                  ],
                                ),
              ),
            ),
          ),
          Container(
            width: 600,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: MobileSignIn(),
            ),
          )
        ],
      )
    );
  }
}
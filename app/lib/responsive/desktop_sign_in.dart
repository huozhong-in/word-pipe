import 'package:flutter/material.dart';
import 'package:wordpipe/responsive/mobile_sign_in.dart';

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
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
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
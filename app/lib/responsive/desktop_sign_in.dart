import 'package:flutter/material.dart';
import 'package:wordpipe/responsive/mobile_sign_in.dart';
import 'package:get/get.dart';
import 'package:gif_view/gif_view.dart';

// ignore: must_be_immutable
class DesktopSignIn extends StatelessWidget {
  DesktopSignIn({super.key});

  RxBool showText = false.obs;

  @override
  Widget build(BuildContext context) {

    return Center(
      child: Container(
        color: const Color(0xFFF5F7FD),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: MouseRegion(
                onEnter: (_) {
                  showText.value = true; 
                },
                onExit: (_) {
                  showText.value = false;  
                },
                child: Container(
                  margin: EdgeInsets.all(8),
                  height: double.infinity,
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: GifView.asset(
                    'assets/Learning languages.gif',
                    height: 400,
                    width: 400,
                    frameRate: 30, // default is 15 FPS
                  )
                ),
              ),
            ),
            Container(
              width: 600,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.transparent,
                // borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: MobileSignIn(),
              ),
            )
          ],
        ),
      )
    );
  }
}
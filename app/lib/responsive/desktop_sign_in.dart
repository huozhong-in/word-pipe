import 'package:flutter/material.dart';
import 'package:wordpipe/responsive/mobile_sign_in.dart';
import 'package:wordpipe/config.dart';
import 'package:get/get.dart';

// ignore: must_be_immutable
class DesktopSignIn extends StatelessWidget {
  DesktopSignIn({super.key});

  RxBool showText = false.obs;

  @override
  Widget build(BuildContext context) {
    return Center(
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
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                  gradient: new LinearGradient(
                    colors: [
                      CustomColors.splashEnd,
                      CustomColors.splashStart,
                    ],
                  ),
                ),
                child: Obx(() {
                  return AnimatedOpacity(
                    opacity: showText.value ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 200),
                    child: Text('留白是为了给设计小伙伴可以发挥的画布，赶紧加入我们，还有不少大事要干！', style: TextStyle(fontSize: 18, color: Colors.black38),)
                  );
                },),
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
      )
    );
  }
}
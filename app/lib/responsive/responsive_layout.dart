import 'package:flutter/material.dart';
import 'package:wordpipe/config.dart';
import 'package:wordpipe/controller.dart';
import 'package:get/get.dart';
import 'package:wordpipe/responsive/desktop_home.dart';
import 'package:wordpipe/responsive/desktop_sign_in.dart';
import 'package:wordpipe/responsive/mobile_home.dart';
import 'package:wordpipe/responsive/mobile_sign_in.dart';

// ignore: must_be_immutable
class ResponsiveLayout extends StatelessWidget {
  
  ResponsiveLayout({super.key});

  Controller c = Get.put(Controller());
  String user_name = "";

  Widget builder(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= MOBILE_LAYOUT_WIDTH) {
            if (user_name == ""){
              return DesktopSignIn();
            }
            return DesktopHome();
          } else {
            if (user_name == ""){
              return MobileSignIn();
            }
            return MobileHome();
          }
        },
      );
    } else {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.tealAccent,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(builder: builder, future: c.getUserName().then((value) => user_name=value));
  }
}
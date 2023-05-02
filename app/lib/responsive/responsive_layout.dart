import 'package:flutter/material.dart';
import 'package:wordpipe/config.dart';
import 'package:wordpipe/controller.dart';
import 'package:wordpipe/MessageController.dart';
import 'package:get/get.dart';
import 'package:wordpipe/responsive/desktop_home.dart';
import 'package:wordpipe/responsive/desktop_sign_in.dart';
import 'package:wordpipe/responsive/mobile_home.dart';
import 'package:wordpipe/responsive/mobile_sign_in.dart';

// ignore: must_be_immutable
class ResponsiveLayout extends StatelessWidget {
  
  ResponsiveLayout({super.key});

  Controller c = Get.put(Controller());
  final MessageController messageController = Get.put(MessageController());
  final SettingsController settingsController = Get.put(SettingsController());
  String _username = "";

  Future<String> _getUserName() async {
    _username = await c.getUserName();
    if (_username != "")
      messageController.handleSSE(_username);
    return _username;
  }

  Widget builder(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= MOBILE_LAYOUT_WIDTH) {
            if (_username == ""){
              return DesktopSignIn();
            }
            return DesktopHome();
          } else {
            if (_username == ""){
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
    return FutureBuilder(builder: builder, future: _getUserName());
  }
}
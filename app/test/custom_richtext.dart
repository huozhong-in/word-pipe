import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:app/config.dart';

class CustomRichText extends StatelessWidget {
  final String message;

  const CustomRichText({
    Key? key,
    required this.message
    }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: <InlineSpan>[
          TextSpan(text: message),
          TextSpan(
            text: "link",
            style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                Uri url = Uri.parse('');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  Get.snackbar("Error", "无法打开链接",
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.black54,
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(8),
                    borderRadius: 8,
                    duration: const Duration(seconds: 2),
                    icon: const Icon(Icons.error, color: Colors.white),
                  );
                }
              },
          ),
          const TextSpan(text: '查看更多信息。'),
        ],
      ),
    );
  }
}

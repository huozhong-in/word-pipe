import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wordpipe/MessageController.dart';


Widget customRadioListTile(Map<String, dynamic> item) {
  final MessageController messageController = Get.find<MessageController>();
  int pkConversation = item['pk_conversation'];


  return Obx(() {
    return RadioListTile<int>(
      value: pkConversation,
      groupValue: messageController.conversation_id.value,
      onChanged: (value) {
        messageController.messages.clear();
        messageController.lastSegmentBeginId = 0;
        messageController.messsage_view_first_build = true;
        messageController.conversation_id.value = value!;
        messageController.selectedConversationName.value = item['conversation_name'].toString().trim() == '' ? '未命名话题' : item['conversation_name'].toString();
        messageController.commentFocus.requestFocus();
        print(messageController.conversation_id.value);
      },
      title: Text(
        item['conversation_name'].toString().trim() == '' ? '未命名话题' : item['conversation_name'].toString(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 14),
      ),
      activeColor: Colors.green[900],
      contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      selected: messageController.conversation_id.value == pkConversation,
      tileColor: messageController.conversation_id.value == pkConversation ? Colors.green[100] : Colors.white,
      // secondary: messageController.conversation_id.value == pkConversation ? Icon(Icons.edit, color: Colors.grey, size: 14,): null,
      shape: RoundedRectangleBorder(
        // borderRadius: BorderRadius.circular(5),
        side: BorderSide(
          color: messageController.conversation_id.value == pkConversation ? Colors.green[900]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
    );
  });
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
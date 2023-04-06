import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dart_openai/openai.dart';

class Message {
  final RxString text;
  Message(String text) : text = text.obs;
}

class MessageController extends GetxController {
  final messages = <Message>[].obs;
  late String username = "dio";

  // @override
  // void onInit() {
  //   super.onInit();
  //   messages.add(Message("Message 1"));
  //   Timer.periodic(Duration(milliseconds: 200), (timer) {
  //     final Message firstMessage = messages[0];
  //     final updatedText = firstMessage.text + "a";
  //     messages[0] = Message(updatedText);
  //   });
  // }

  int addMessage(String message) {
    final rxMessage = Message(message);
    messages.add(rxMessage);
    return messages.length - 1;
  }
  void updateMessage(int index, String newMessage,) {
    final rxMessage = Message(newMessage);
    messages[index] = rxMessage;
    update();
  }
  
  void direct_to_openai(String prompt){
    OpenAI.apiKey = "sk-xxx";
    OpenAI.baseUrl = 'https://rewardhunter.net';
    Stream<OpenAIStreamChatCompletionModel> chatStream = OpenAI.instance.chat.createStream(
      model: "gpt-3.5-turbo",
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: prompt,
          role: OpenAIChatMessageRole.user,
        )
      ],
    );
    int needUpdate = addMessage("Jarvis is typing...");
    chatStream.listen((chatStreamEvent) {
      // print(chatStreamEvent);
      OpenAIStreamChatCompletionChoiceModel choice = chatStreamEvent.choices[0];
      final content = choice.delta.content;
      if(content != null){
        // print(content);
        final message = messages[needUpdate];
        message.text.value += content;
            updateMessage(
              needUpdate,
              message.text.value,
            );
      }
    });
  }
}


class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final messageController = Get.put(MessageController());
    final TextEditingController _textController = TextEditingController();

    return Obx(() {
      final messages = messageController.messages;
      _textController.text = "give me a 30-word paragraph.";

      return Column(
        children: [
          Expanded(
            child: Material(
              color: Colors.black45,
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return ListTile(
                    title: Text(message.text.value),
                  );
                },
                shrinkWrap: true,
              ),
            ),
          ),
          Container(
            child: Material(
              child: TextFormField(
                controller: _textController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '',
                  fillColor: Colors.black26,
                ),
              ),
            )
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: Colors.green,
            ),
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white)
              ),
              onPressed: () async {
                messageController.direct_to_openai(_textController.text);
                _textController.clear();
              },
              child: Text("Get Completion"),
            ),
          )
        ],
      );
    });
  }
}


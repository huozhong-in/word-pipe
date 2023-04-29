import 'package:get/get.dart';
import 'package:dart_openai/openai.dart';
import 'package:wordpipe/controller.dart';

List<OpenAIChatCompletionChoiceMessageModel> prompt_template_freechat(String prompt){
  List<OpenAIChatCompletionChoiceMessageModel> modelList = [];
  // var r_system = OpenAIChatCompletionChoiceMessageModel(
  //   role: OpenAIChatMessageRole.system,
  //   content: "",
  // );
  // var r_user1 = OpenAIChatCompletionChoiceMessageModel(
  //   role: OpenAIChatMessageRole.user, 
  //   content: ""
  // );
  // var r_assistant1 =  OpenAIChatCompletionChoiceMessageModel(
  //   role: OpenAIChatMessageRole.assistant,
  //   content: ""
  // );
  var r_user2 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user,
    content: prompt,
  );

  // modelList.add(r_system);
  // modelList.add(r_user1);
  // modelList.add(r_assistant1);
  modelList.add(r_user2);
  return modelList;
}


List<OpenAIChatCompletionChoiceMessageModel> prompt_template_summary_previous_text(List<String> messageList){
  List<OpenAIChatCompletionChoiceMessageModel> modelList = [];
  var r_system = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.system,
    content: "你是一位逻辑严密的语言专家，擅长将大段的文字进行概括，用简洁的语言表达出来。",
  );
  var r_user1 = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user, 
    content: "Q: 什么是光合作用？\n"
      "A: 光合作用是植物、藻类和某些微生物通过太阳能将二氧化碳和水转化为葡萄糖和氧气的过程。\n"
      "Q: 如何煮意大利面？\n"
      "A: 煮意大利面需要将面条放入大量沸水中，加入盐，煮至软硬适中，然后将面条捞出，沥干水分，与酱汁混合。\n"
      "Q: 什么是机器学习？\n"
      "A: 机器学习是一种人工智能技术，通过对数据进行训练和分析，使计算机系统能够自动地学习和改进性能。\n"
      "Q: 神经网络是什么？\n"
      "A: 神经网络是一种模仿生物神经系统的计算模型，由多个相互连接的神经元组成，可以用于处理复杂的数据模式。\n"
      "Q: 请将上文的多个\"QA对\"进行概况，即进行信息的“语义层面的压缩”，按照压缩比约50%保留一定的信息细节。"
  );
  var r_assistant1 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.assistant,
    content: "A: 刚才我们讨论了光合作用是植物利用太阳能的过程，以及煮意大利面的方法是先用沸水煮后再混合酱汁，然后还说道一些机器学习及神经网络的入门概念。"
  );
  String conversation_history = '';
  // 将messageList中每个元素的内容拼接到conversation_history中，奇数行前加“Q: ”，偶数行前加“A: ”，并且每个元素后面加上换行符“\n”
  for (int i = 0; i < messageList.length; i++) {
    if (i % 2 == 0) {
      conversation_history += "Q: " + messageList[i] + "\n";
    } else {
      conversation_history += "A: " + messageList[i] + "\n";
    }
  }
  conversation_history += "Q: 请将上文的多个\"QA对\"进行概况，即进行信息的“语义层面的压缩”，按照压缩比约50%保留一定的信息细节。\n";
  var r_user2 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user,
    content: conversation_history,
  );

  modelList.add(r_system);
  modelList.add(r_user1);
  modelList.add(r_assistant1);
  modelList.add(r_user2);
  return modelList;
}

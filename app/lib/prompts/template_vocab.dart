import 'package:get/get.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:wordpipe/controller.dart';

List<OpenAIChatCompletionChoiceMessageModel> prompt_template_word(String oneWord){
  List<OpenAIChatCompletionChoiceMessageModel> modelList = [];

  var r_system = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.system,
    content: "你是我的英语词汇老师",
  );
  var r_user1 = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user, 
    content: "我不认识这个单词：`suspense`，请你简单明了的分别用中文和英文解释单词的意思，给出这个单词的词根词缀信息。并附上几个英文例句，带中文翻译。"
  );
  var r_assistant1 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.assistant,
    content: "单词`suspense`\n"
      "中文解释：悬念，紧张感，悬疑\n"
      "英文解释：a feeling of excitement or anxiety when you do not know what will happen next\n"
      "词根词缀信息：词根是“suspens-”，意为“悬挂、悬浮”，后缀是“-e”，表示名词。\n"
      "例句：\n"
      "- The suspense was killing me as I waited for the results.（我等待结果时，紧张感让我快要崩溃了。）\n"
      "- The movie was full of suspense and kept me on the edge of my seat.（这部电影充满了悬念，让我坐立不安。）\n"
      "- The author is a master of suspense and always keeps readers guessing until the very end.（这位作者是悬疑小说的大师，总是让读者猜到最后才揭晓真相。）"
  );
  var r_user2 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user,
    content: "我不认识这个单词：`" + oneWord + "`，请你简单明了的分别用中文和英文解释单词的意思，给出这个单词的词根词缀信息。并附上几个英文例句，带中文翻译。",
  );

  modelList.add(r_system);
  modelList.add(r_user1);
  modelList.add(r_assistant1);
  modelList.add(r_user2);
  return modelList;
}

List<OpenAIChatCompletionChoiceMessageModel> prompt_template_word_example_sentence(String oneWord){
  List<OpenAIChatCompletionChoiceMessageModel> modelList = [];

  var r_system = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.system,
    content: "请你扮演我的英语词汇老师",
  );
  final SettingsController settingsController = Get.find<SettingsController>();
  String insertion = "";
  if (settingsController.useOtherWordForms.value){
    insertion = "，可以使用这个单词的其他词性形式";
  }
  var r_user1 = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user, 
    content: "我们来玩一个猜词游戏：对于单词：`plagiarsim`，请不要直接告诉我它的意思，而是造几个相对简单英文例句（注意不要中文翻译），我来猜猜它的意思。这样我能更好的理解它，学习到它在不同语境的细微差别。注意正确答案选项（单项选择）放在最后的位置，前面放三个大于号，以确保我能用程序正确解析它。"
  );
  var r_assistant1 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.assistant,
    content: "Here are a few sentences containing `plagiarism`:\n"
      "- Copying someone else's writing without crediting the source is plagiarism. \n"
      "- She was accused of plagiarism when her essay seemed to copy whole paragraphs from a published article.\n"
      "- The student committed plagiarism by downloading a paper from the Internet and claiming he wrote it himself.\n"
      "- The university takes plagiarism very seriously and students can face suspension or expulsion for it.\n"
      "Now please choose the correct meaning of plagiarism: \n"
      "A. 篡改;伪造\n"
      "B. 抄袭;剽窃\n"
      "C. 误导;欺诈\n"
      "D. 侵犯;侵害\n"
      ">>>B"
  );
  var r_user2 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user,
    content: "我们来玩一个猜词游戏：对于单词：`" + oneWord + "`，请不要直接告诉我它的意思，而是造几个相对简单的英文例句（注意不要中文翻译）$insertion，我来猜猜它的意思。这样我能更好的理解它，学习到它在不同语境的细微差别。注意正确答案选项（单项选择）放在最后的位置，前面放三个大于号，以确保我能用程序正确解析它。",
  );

  modelList.add(r_system);
  modelList.add(r_user1);
  modelList.add(r_assistant1);
  modelList.add(r_user2);
  return modelList;
}

List<OpenAIChatCompletionChoiceMessageModel> prompt_template_translate_sentence(String sentence){
  List<OpenAIChatCompletionChoiceMessageModel> modelList = [];
  var r_system = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.system,
    content: "你是我的英语翻译专家。",
  );
  var r_user1 = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user, 
    content: "我输入一些英文，请你帮我翻译成中文 ，并解释其中的语法知识：`\"AI companies that make product claims about identifying or supporting mental health, or that are designed to influence your emotional state, or mental well-being, should be classified as health products, and subject to quality and safety standards accordingly,\" she says.`"
  );
  var  r_assistant1 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.assistant,
    content: "翻译成中文为: 她说:“声称可以识别或支持心理健康,或者被设计来影响你的情感状态或心理健康的AI公司,应该被归类为健康产品,并根据此受到质量和安全标准的约束。”\n"
      "语法解释:\n"
      "1. `AI companies that make product claims`  做产品声明的AI公司。that make product claims修饰AI companies。\n"
      "2. `about identifying or supporting mental health`  关于识别或支持心理健康。about为介词,identifying或supporting mental health作宾语。\n"
      "3. `or that are designed to influence`  或者被设计来影响。or连接两个并列句。that are designed 修饰companies。\n"
      "4. `your emotional state, or mental well-being`   你的情感状态或心理健康。your emotional state和mental well-being并列,作designed的宾语。\n"
      "5. `should be classified as`    应该被归类为。should被归类为虚拟语气,表示“应该”。\n"
      "6. `health products, and subject to`   健康产品,并受......约束。health products作后置定语,修饰be classified as的宾语。subject to 表示“受......约束”。\n"
      "7. `quality and safety standards accordingly`   相应的质量和安全标准。修饰subject to。\n"
      "8. `she says`   她说。she作主语,says为谓语动词。引导直接引语。"
  );
  var  r_user2 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user,
    content: "我输入一些英文，请你帮我翻译成中文，并解释其中的语法知识：`" + sentence + "`",
  );

  modelList.add(r_system);
  modelList.add(r_user1);
  modelList.add(r_assistant1);
  modelList.add(r_user2);
  return modelList;
}

List<OpenAIChatCompletionChoiceMessageModel> prompt_template_answer_question(String sentence){
  List<OpenAIChatCompletionChoiceMessageModel> modelList = [];
  var r_system = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.system,
    content: "你是我的知识百科全书。",
  );
  // var r_user1 = OpenAIChatCompletionChoiceMessageModel(
  //   role: OpenAIChatMessageRole.user, 
  //   content: "我有一些问题，如果你知道，就请你依次有条理的、简洁明了的回答。如果你不知道，就回复`抱歉，这个问题我暂时不知道。`：``"
  // );
  // var  r_assistant1 =  OpenAIChatCompletionChoiceMessageModel(
  //   role: OpenAIChatMessageRole.assistant,
  //   content: "``",
  // );
  final SettingsController settingsController = Get.find<SettingsController>();
  String insertion = "";
  if (settingsController.aiAssistantLanguage.value == 1){
    insertion = "用中文";
  }else{
    insertion = "用英文";
  }
  var  r_user2 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user,
    content: "我有一些问题，如果你知道就请你依次有条理的、简洁明了的$insertion回答。如果你不知道，就回复\"抱歉，这个问题我暂时不知道。\"：`" + sentence + "`",
  );

  modelList.add(r_system);
  // modelList.add(r_user1);
  // modelList.add(r_assistant1);
  modelList.add(r_user2);
  return modelList;
}

List<OpenAIChatCompletionChoiceMessageModel> prompt_template_translate_sentence_zh_en(String sentence){
  List<OpenAIChatCompletionChoiceMessageModel> modelList = [];
  var r_system = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.system,
    content: "你是我的英语翻译专家。",
  );
  // var r_user1 = OpenAIChatCompletionChoiceMessageModel(
  //   role: OpenAIChatMessageRole.user, 
  //   content: "我输入一些中文，请你帮我翻译成英文 ，并用中文解释译文涉及的语法知识：``"
  // );
  // var  r_assistant1 =  OpenAIChatCompletionChoiceMessageModel(
  //   role: OpenAIChatMessageRole.assistant,
  //   content: "翻译成英文为:"
  // );
  var  r_user2 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user,
    content: "我输入一些中文，请你帮我翻译成英文 ，并用中文解释译文涉及的语法知识：`" + sentence + "`",
  );

  modelList.add(r_system);
  // modelList.add(r_user1);
  // modelList.add(r_assistant1);
  modelList.add(r_user2);
  return modelList;
}

List<OpenAIChatCompletionChoiceMessageModel> prompt_template_guess_word_from_sentence(String sentence){
  List<OpenAIChatCompletionChoiceMessageModel> modelList = [];
  // 从英文句子中猜用户生词
  // TODO 根据我的生词本、职业资料，猜测我已经熟悉某些行业单词，就把这些单词权重调低

  var r_system = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.system,
    content: "你是我的英语老师。你会根据COCA(Corpus of Contemporary American English)词频来猜测当我遇到一个英文句子时，其中的哪些会是我的生词。",
  );
  var r_user1 = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user, 
    content: "我输入一些英文，你根据COCA(Corpus of Contemporary American English)词频来猜猜其中哪些可能是我的生词：`That is, after all, the whole purpose of the scraping process.`"
  );
  var  r_assistant1 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.assistant,
    content: "`scraping`|`process`",
  );
  var  r_user2 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user,
    content: "我输入一些英文，你根据COCA(Corpus of Contemporary American English)词频来猜猜其中哪些可能是我的生词：`" + sentence + "`",
  );

  modelList.add(r_system);
  modelList.add(r_user1);
  modelList.add(r_assistant1);
  modelList.add(r_user2);
  return modelList;
}
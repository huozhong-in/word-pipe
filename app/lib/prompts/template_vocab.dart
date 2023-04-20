import 'package:dart_openai/openai.dart';

List<OpenAIChatCompletionChoiceMessageModel> prompt_template_word(String oneWord){
  List<OpenAIChatCompletionChoiceMessageModel> modelList = [];

  var r_system = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.system,
    content: "你是我的英语词汇老师",
  );
  // var r_user1 = OpenAIChatCompletionChoiceMessageModel(
  //   role: OpenAIChatMessageRole.user, 
  //   content: "我不认识这个单词：`purpose`，请你简单明了的分别用中英文解释单词的意思，给出这个单词的词根词缀信息，最后附上几个常见的例句。"
  // );
  // var r_assistant1 =  OpenAIChatCompletionChoiceMessageModel(
  //   role: OpenAIChatMessageRole.assistant,
  //   content: "对于单词`purpose`，",
  // );
  var r_user2 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user,
    content: "我不认识这个单词：`" + oneWord + "`，请你简单明了的分别用中文和英文解释单词的意思，给出这个单词的词根词缀信息。并附上几个英文例句，带中文翻译。",
  );

  modelList.add(r_system);
  // modelList.add(r_user1);
  // modelList.add(r_assistant1);
  modelList.add(r_user2);
  return modelList;
}

List<OpenAIChatCompletionChoiceMessageModel> prompt_template_word_example_sentence(String oneWord, {bool lemma=false}){
  List<OpenAIChatCompletionChoiceMessageModel> modelList = [];

  var r_system = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.system,
    content: "请你扮演我的英语词汇老师",
  );
  String insertion = "";
  if (lemma){
    insertion = "，可以使用这个单词的其他词性形式";
  }
  var r_user1 = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user, 
    content: "我们来玩一个猜词游戏：对于单词：`plagiarsim`，请不要直接告诉我它的意思，而是造几个相对简单英文例句（注意不要中文翻译），我来猜猜它的意思。这样我能更好的理解它，学习到它在不同语境的细微差别。"
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
"The correct answer is: B",
  );
  var r_user2 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user,
    content: "我们来玩一个猜词游戏：对于单词：`" + oneWord + "`，请不要直接告诉我它的意思，而是造几个相对简单的英文例句（注意不要中文翻译）$insertion，我来猜猜它的意思。这样我能更好的理解它，学习到它在不同语境的细微差别。",
  );

  modelList.add(r_system);
  modelList.add(r_user1);
  modelList.add(r_assistant1);
  modelList.add(r_user2);
  return modelList;
}

List<OpenAIChatCompletionChoiceMessageModel> prompt_template_sentence(String sentence){
  List<OpenAIChatCompletionChoiceMessageModel> modelList = [];

  var r_system = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.system,
    content: "你是我的英语老师。你会根据BN词频来猜测当我遇到一个英文句子时，其中的哪些会是我的生词。",
    // TODO 根据我的职业资料，猜测我已经熟悉某些行业单词，就把这些单词权重调低
  );
  var r_user1 = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user, 
    content: "我输入一些英文，你根据BN词频来猜猜其中哪些可能是我的生词：`That is, after all, the whole purpose of the scraping process.`"
  );
  var  r_assistant1 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.assistant,
    content: "`scraping`|`process`",
  );
  var  r_user2 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user,
    content: "我输入一些英文，你根据BN词频来猜猜其中哪些可能是我的生词：`" + sentence + "`",
  );

  modelList.add(r_system);
  modelList.add(r_user1);
  modelList.add(r_assistant1);
  modelList.add(r_user2);
  return modelList;
}
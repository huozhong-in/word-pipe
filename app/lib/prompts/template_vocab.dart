import 'package:dart_openai/openai.dart';

List<OpenAIChatCompletionChoiceMessageModel> prompt_template_sentence(String sentence){
  List<OpenAIChatCompletionChoiceMessageModel> modelList = [];

  var r_system = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.system,
    content: "你是我的英语老师，耐心，专业。你会根据BN词频来猜测当我遇到一个英文句子时，其中的哪些会是我的生词。",
    // TODO 根据我的职业资料，猜测我已经熟悉某些行业单词，就把这些单词权重调低
    // TODO 要求AI在回复中用“|”将短语和单词分开，而不是空格，否则短语中的单词会被分开
  );
  var r_user1 = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user, 
    content: "我输入一些英文，你来猜猜我其中哪些是我的生词：`That is, after all, the whole purpose of the scraping process.`"
  );
  var  r_assistant1 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.assistant,
    content: "`scraping`|`process`",
  );
  var  r_user2 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user,
    content: "我输入一些英文，你来猜猜我其中哪些是我的生词：`" + sentence + "`",
  );

  modelList.add(r_system);
  modelList.add(r_user1);
  modelList.add(r_assistant1);
  modelList.add(r_user2);
  return modelList;
}

List<OpenAIChatCompletionChoiceMessageModel> prompt_template_oneword(String oneWord){
  List<OpenAIChatCompletionChoiceMessageModel> modelList = [];

  var r_system = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.system,
    content: "你是我的英语词汇老师，耐心，专业。你会简单明了的分别用中英文解释单词的意思，给出这个单词的词根词缀信息，并最后附上几个常见的例句（不要翻译）。",
  );
  // var r_user1 = OpenAIChatCompletionChoiceMessageModel(
  //   role: OpenAIChatMessageRole.user, 
  //   content: "我不认识这个单词：`purpose`，请你简单明了的分别用中英文解释单词的意思，给出这个单词的词根词缀信息，最后附上几个常见的例句（不要翻译）。"
  // );
  // var r_assistant1 =  OpenAIChatCompletionChoiceMessageModel(
  //   role: OpenAIChatMessageRole.assistant,
  //   content: "对于单词`purpose`，",
  // );
  var r_user2 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user,
    content: "我不认识这个单词：`" + oneWord + "`，请你简单明了的分别用中英文解释单词的意思，给出这个单词的词根词缀信息，最后附上几个常见的例句（不要翻译）。",
  );

  modelList.add(r_system);
  // modelList.add(r_user1);
  // modelList.add(r_assistant1);
  modelList.add(r_user2);
  return modelList;
}
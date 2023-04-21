import 'package:dart_openai/openai.dart';

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
      "The correct answer is: B"
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

List<OpenAIChatCompletionChoiceMessageModel> prompt_template_translate_sentence(String sentence){
  List<OpenAIChatCompletionChoiceMessageModel> modelList = [];
  var r_system = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.system,
    content: "你是我的英语翻译专家。",
  );
  var r_user1 = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user, 
    content: "我输入一些英文，请你帮我翻译成中文 ，并解释其中的语法知识：`Imagine if your face had been digitally edited into a porn video without your consent and then shared on the internet. One woman reveals the horror of it happening to her.`"
  );
  var  r_assistant1 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.assistant,
    content: "翻译成中文为:想象一下,如果你的脸被人未经允许地数字编辑到色情视频中,然后在互联网上分享。一位女性揭示这种恐怖事件发生在她身上。\n"
      "这句话中的语法知识点:\n"
      "1. `Imagine if...`表示假设,相当于如果...那么...的意思。\n"
      "2. `your face had been` 使用了虚拟语气,表示事情并没有真的发生,只是假设的情况。had been是过去完成时态,表示过去发生的动作对现在造成的影响。\n"
      "3. `digitally edited into` 使用了过去分词(edited)作定语,修饰前面的face。into表示面部被编辑进色情视频里。\n"
      "4. `without your consent` 是独立主格结构,your consent在句中作状语,表示未经你允许。\n"
      "5. `One woman reveals` 主语为One woman,reveals是动词,女性揭示、揭发的意思。\n"
      "6. `the horror of it happening to her it happening to her`是主语从句,作the horror的定语,说明女性遭遇的恐怖情况。\n"
      "7. 整个句子可以理解为一位女性描述了这样一个恐怖的假设情况:如果你的脸被未经允许地编辑到色情视频中,然后发布到互联网,她揭露这种事情发生在她自己身上,这究竟有多可怕。"
  );
  var  r_user2 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user,
    content: "我输入一段英文，请你帮我翻译成中文，并解释其中的语法知识：`" + sentence + "`",
  );

  modelList.add(r_system);
  modelList.add(r_user1);
  modelList.add(r_assistant1);
  modelList.add(r_user2);
  return modelList;
}

List<OpenAIChatCompletionChoiceMessageModel> prompt_template_answer_question(String sentence, {bool useEnglish=false}){
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
  String insertion = "";
  if (useEnglish){
    insertion = "用英文";
  }
  var  r_user2 =  OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.user,
    content: "我有一些问题，如果你知道就请你依次有条理的、简洁明了的$insertion回答。如果你不知道，就回复`抱歉，这个问题我暂时不知道。`：`" + sentence + "`",
  );

  modelList.add(r_system);
  // modelList.add(r_user1);
  // modelList.add(r_assistant1);
  modelList.add(r_user2);
  return modelList;
}

List<OpenAIChatCompletionChoiceMessageModel> prompt_template_guess_word_from_sentence(String sentence){
  List<OpenAIChatCompletionChoiceMessageModel> modelList = [];
  // 从英文句子中猜测生词
  // TODO 根据我的职业资料，猜测我已经熟悉某些行业单词，就把这些单词权重调低

  var r_system = OpenAIChatCompletionChoiceMessageModel(
    role: OpenAIChatMessageRole.system,
    content: "你是我的英语老师。你会根据BN词频来猜测当我遇到一个英文句子时，其中的哪些会是我的生词。",
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
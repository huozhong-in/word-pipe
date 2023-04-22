

List<int> get_word_index_range_in_text(String text){
    RegExp reg = RegExp(r'\b[a-zA-Z]{3,}(?:-[a-zA-Z]{3,})*\b');
  
    var matches = reg.allMatches(text);
    String result = '';
    int lastIndex = 0;
    
    for (Match match in matches) {
      result += text.substring(lastIndex, match.start);
      result += '/${match.group(0)}/';
      lastIndex = match.end;
    }
    result += text.substring(lastIndex);
    print(result);
    return [0, 0];
  }

void main() {
  String text = '''单词 `hallucinate`
中文解释：产生幻觉，幻想
英文解释：to see, hear, or feel things that are not really there because of a mental illness or drug
词根词缀信息：词根是“hallucin-”，意为“幻觉”，后缀是“-ate”，表示动词。
例句：
- The patient was hallucinating after taking the medication.（这位病人在服药后产生了幻觉。）
- He claimed to have seen a ghost, but we suspected he was hallucinating.（他声称看到了鬼，但我们怀疑他是在产生幻觉。）
- The drug can cause users to hallucinate and experience vivid, unrealistic sensations.（这种药物会导致使用者产生幻觉，体验到生动而不真实的感觉。）''';
  String text2 = '''Hello啊，饭已OK，下来mixi吧''';
  List<int> range = get_word_index_range_in_text(text);
  print(range);
}

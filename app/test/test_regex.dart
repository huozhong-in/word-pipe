

List<int> get_word_index_range_in_text(String text){
    RegExp reg = RegExp(r'\b[a-zA-Z]{3,}(?:-[a-zA-Z]{3,})*\b');
  
    var matches = reg.allMatches(text);
    String result = '';
    int lastIndex = 0;
    
    for (Match match in matches) {
      result += text.substring(lastIndex, match.start);
      result += '`${match.group(0)}`';
      lastIndex = match.end;
    }
    result += text.substring(lastIndex);
    print(result);
    return [0, 0];
  }

void main() {
  String text = '''soggy 的意思是“湿透的，泡软的”。它的词根是 sogg-，表示“湿润的”。它的后缀是 -y，表示“具有……的性质”。

以下是几个常见的例句：

- The ground was so soggy that our shoes sank into the mud.（地面太湿透了，我们的鞋子陷进了泥里。）
- The bread was left out too-long and became soggy.（面包放得太久，变得泡软了。）
- The weather was so rainy that everything outside was soggy.（天气太雨了，外面的一切都湿透了。）''';
  String text2 = '''Hello啊，饭已OK，下来mixi吧''';
  List<int> range = get_word_index_range_in_text(text);
  print(range);
}

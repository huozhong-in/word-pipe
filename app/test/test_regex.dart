import 'dart:core';


bool isEnglishAndSymbols(String text) {
  for (int i = 0; i < text.length; i++) {
    int codeUnit = text.codeUnitAt(i);
    if (!((codeUnit >= 32 && codeUnit <= 126) || (codeUnit >= 9 && codeUnit <= 13) || codeUnit == 133)) {
      return false;
    }
  }
  return true;
}



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
  String text = '''Sure, here are a few sentences containing `flavor`:
- This soup has a strong tomato flavor.
- I love the flavor of cinnamon in my coffee.
- The ice cream parlor has a wide variety of flavors to choose from.
- The restaurant offers different flavors of wings, from mild to spicy. 
Now please choose the correct meaning of flavor:
A. 香气;气味
B. 食欲;胃口
C. 口味;味道
D. 营养;成分
>>>C''';
  String pureEnglishText = "When feeling down, what should one do? \n\nThere are several things one can do when feeling down or low in mood. Some suggestions include:\n\n1. Engage in physical activity, such as going for a walk or doing some light exercise.\n2. Practice relaxation techniques, such as deep breathing or meditation.\n3. Connect with others, whether it be talking to a friend or joining a support group.\n4. Do something enjoyable or rewarding, such as reading a book or listening to music.\n5. Seek professional help if the low mood persists or interferes with daily functioning.\n\nRemember that it's okay to not feel okay and seeking help is a sign of strength.";

  print(isEnglishAndSymbols(pureEnglishText));  
  print(isEnglishAndSymbols(text));
}

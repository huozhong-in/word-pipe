

void main() {
  String input = 'This is a long-time example with hyphenated-words.';
  RegExp exp = RegExp(r'\b[a-zA-Z]+(?:-[a-zA-Z]+)*\b');

  Iterable<RegExpMatch> matches = exp.allMatches(input);

  for (RegExpMatch match in matches) {
    String? word = match.group(0);
    int startIndex = match.start;
    int endIndex = match.end;
    print('Found "$word" at position $startIndex-$endIndex');
  }
}

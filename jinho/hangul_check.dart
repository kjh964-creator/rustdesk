// Local check for the Hangul composer: `dart run jinho/hangul_check.dart`
import '../flutter/lib/mobile/widgets/hangul_composer.dart';

String type(List<String> keys) {
  final c = HangulComposer();
  var remote = '';
  for (final k in keys) {
    final HangulEdit e;
    if (k == '<') {
      e = c.backspace();
    } else if (k == ' ') {
      c.commit();
      e = const HangulEdit(0, ' ');
    } else {
      e = c.input(k);
    }
    remote = remote.substring(0, remote.length - e.backspaces) + e.insert;
  }
  return remote;
}

void main() {
  final cases = <List<String>, String>{
    ['ㅎ', 'ㅏ', 'ㄴ', 'ㄱ', 'ㅡ', 'ㄹ']: '한글',
    ['ㄱ', 'ㅏ', 'ㅂ', 'ㅅ']: '값',
    ['ㄱ', 'ㅏ', 'ㅂ', 'ㅅ', 'ㅣ']: '갑시',
    ['ㄷ', 'ㅏ', 'ㄹ', 'ㄱ', 'ㅏ']: '달가',
    ['ㅇ', 'ㅗ', 'ㅏ', 'ㅆ', 'ㅇ', 'ㅓ']: '왔어',
    ['ㅇ', 'ㅜ', 'ㅣ']: '위',
    ['ㄸ', 'ㅏ', 'ㄸ', 'ㅏ']: '따따',
    ['ㄱ', 'ㅏ', 'ㄴ', '<']: '가',
    ['ㄱ', 'ㅏ', '<', '<']: '',
    ['ㄱ', 'ㅏ', ' ', '<']: '가',
    ['ㅏ', 'ㄱ']: 'ㅏㄱ',
    ['ㄱ', 'ㄱ']: 'ㄱㄱ',
    ['ㅈ', 'ㅣ', 'ㄴ', 'ㅎ', 'ㅗ']: '진호',
    ['ㄷ', 'ㅔ', 'ㅅ', 'ㅡ', 'ㅋ', 'ㅡ']: '데스크',
    ['ㅇ', 'ㅏ', 'ㄴ', 'ㅎ', 'ㅇ', 'ㅏ']: '않아',
  };
  var fails = 0;
  cases.forEach((keys, want) {
    final got = type(keys);
    if (got != want) {
      fails++;
      print('FAIL ${keys.join()} -> "$got" (want "$want")');
    }
  });
  // Phone keyboard field -> remote text (softKeyboardEdit)
  final fieldCases = <List<String>, String>{
    // Samsung/Gboard Korean: last syllable rewritten in place
    ['1', '1ㅇ', '1어', '1언', '1언ㅈ', '1언제', '1언제ㄴ', '1언제나']: '언제나',
    ['1', '1ㄲ', '1꾸', '1꿈', '1꿈ㄱ', '1꿈고', '1꿈과']: '꿈과',
    // batchim moves to the next syllable
    ['1', '1ㄷ', '1다', '1달', '1달ㄱ', '1달가']: '달가',
    ['1', '1ㄷ', '1다', '1달', '1달가', '1다르']: '다르',
    // english, autocorrect, delete, emoji
    ['1', '1h', '1he', '1hel', '1helo', '1hello']: 'hello',
    ['1', '1teh', '1the ']: 'the ',
    ['1', '1ab', '1a']: 'a',
    ['1', '1a\u{1F600}', '1a']: 'a',
  };
  fieldCases.forEach((steps, want) {
    var remote = '';
    for (var i = 1; i < steps.length; i++) {
      final e = softKeyboardEdit(steps[i - 1], steps[i]);
      final r = remote.runes.toList();
      remote = String.fromCharCodes(r.sublist(0, r.length - e.backspaces)) + e.insert;
    }
    if (remote != want) {
      fails++;
      print('FAIL field ${steps.join(" > ")} -> "$remote" (want "$want")');
    }
  });
  print(fails == 0 ? 'all ${cases.length + fieldCases.length} passed' : '$fails failed');
  if (fails > 0) throw Exception('hangul check failed');
}

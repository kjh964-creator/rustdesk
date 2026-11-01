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
  print(fails == 0 ? 'all ${cases.length} passed' : '$fails failed');
  if (fails > 0) throw Exception('hangul check failed');
}

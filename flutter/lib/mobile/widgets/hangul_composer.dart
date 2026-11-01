// Hangul 2-beolsik composer for the JinhoDesk on-screen keyboard.
//
// Pure Dart (no Flutter imports) so it can be unit tested on its own.
// The remote side only receives plain text, so every keystroke is turned
// into an edit: "erase N characters, then type this text".

class HangulEdit {
  final int backspaces;
  final String insert;
  const HangulEdit(this.backspaces, this.insert);

  @override
  String toString() => 'HangulEdit($backspaces, "$insert")';
}

const List<String> _cho = [
  'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', //
  'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
];
const List<String> _jung = [
  'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', //
  'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ',
];
const List<String> _jong = [
  '', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', //
  'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ',
  'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
];
const Map<String, String> _vowelPairs = {
  'ㅗㅏ': 'ㅘ', 'ㅗㅐ': 'ㅙ', 'ㅗㅣ': 'ㅚ', //
  'ㅜㅓ': 'ㅝ', 'ㅜㅔ': 'ㅞ', 'ㅜㅣ': 'ㅟ', 'ㅡㅣ': 'ㅢ',
};
const Map<String, String> _finalPairs = {
  'ㄱㅅ': 'ㄳ', 'ㄴㅈ': 'ㄵ', 'ㄴㅎ': 'ㄶ', 'ㄹㄱ': 'ㄺ', //
  'ㄹㅁ': 'ㄻ', 'ㄹㅂ': 'ㄼ', 'ㄹㅅ': 'ㄽ', 'ㄹㅌ': 'ㄾ',
  'ㄹㅍ': 'ㄿ', 'ㄹㅎ': 'ㅀ', 'ㅂㅅ': 'ㅄ',
};

bool isHangulJamo(String s) => _cho.contains(s) || _jung.contains(s);
bool _isVowel(String s) => _jung.contains(s);

/// Renders a key sequence as one syllable (or one lone jamo).
/// Returns null when the keys cannot form a single syllable.
String? _render(List<String> keys) {
  if (keys.isEmpty) return '';
  var i = 0;
  String? cho;
  if (!_isVowel(keys[0])) {
    if (!_cho.contains(keys[0])) return null;
    cho = keys[0];
    i = 1;
  }
  String? jung;
  if (i < keys.length && _isVowel(keys[i])) {
    jung = keys[i];
    i++;
    if (i < keys.length && _isVowel(keys[i])) {
      final pair = _vowelPairs[jung + keys[i]];
      if (pair != null) {
        jung = pair;
        i++;
      }
    }
  }
  if (cho == null) {
    // A lone vowel never takes a final consonant.
    return i == keys.length ? jung : null;
  }
  if (jung == null) {
    return i == keys.length ? cho : null;
  }
  var jong = '';
  if (i < keys.length && !_isVowel(keys[i])) {
    if (!_jong.contains(keys[i])) return null;
    jong = keys[i];
    i++;
    if (i < keys.length && !_isVowel(keys[i])) {
      final pair = _finalPairs[jong + keys[i]];
      if (pair != null) {
        jong = pair;
        i++;
      }
    }
  }
  if (i != keys.length) return null;
  final code = 0xAC00 +
      (_cho.indexOf(cho) * 21 + _jung.indexOf(jung)) * 28 +
      _jong.indexOf(jong);
  return String.fromCharCode(code);
}

class HangulComposer {
  final List<String> _keys = [];

  String get composing => _render(_keys) ?? '';
  bool get isComposing => _keys.isNotEmpty;

  /// Ends the current syllable; nothing needs to be sent.
  void commit() => _keys.clear();

  HangulEdit input(String jamo) {
    final before = composing;
    final erase = before.isEmpty ? 0 : 1;
    final next = _render([..._keys, jamo]);
    if (next != null) {
      _keys.add(jamo);
      return HangulEdit(erase, next);
    }
    // A vowel after a final consonant steals that consonant: 갑 + ㅏ -> 가바
    if (_isVowel(jamo) && _keys.length >= 2 && !_isVowel(_keys.last)) {
      final moved = _keys.last;
      final rest = _render(_keys.sublist(0, _keys.length - 1));
      final fresh = _render([moved, jamo]);
      if (rest != null && fresh != null) {
        _keys
          ..clear()
          ..addAll([moved, jamo]);
        return HangulEdit(erase, rest + fresh);
      }
    }
    _keys
      ..clear()
      ..add(jamo);
    return HangulEdit(0, jamo);
  }

  /// Removes the last jamo of the syllable being composed, or, when nothing
  /// is being composed, one character on the remote side.
  HangulEdit backspace() {
    if (_keys.isEmpty) return const HangulEdit(1, '');
    _keys.removeLast();
    return HangulEdit(1, composing);
  }
}

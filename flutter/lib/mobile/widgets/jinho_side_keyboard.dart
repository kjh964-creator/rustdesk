// JinhoDesk side keyboard: an in-app keyboard docked at the right edge in
// landscape so the remote screen stays fully visible on the left.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../../models/input_model.dart';
import '../../models/platform_model.dart';
import 'hangul_composer.dart';

class JinhoSideKeyboard {
  static const optionKey = 'jinho-landscape-keyboard';
  static const widthFraction = 0.38;

  // Saved values. Empty = not chosen yet (ask on first use).
  static const phone = 'phone';
  static const right = 'right';
  static const left = 'left';

  /// Panel currently shown (only drawn in landscape).
  static final RxBool visible = false.obs;

  /// The user's saved landscape keyboard choice; kept across connections.
  static String get choice => bind.mainGetLocalOption(key: optionKey);

  static Future<void> setChoice(String value) =>
      bind.mainSetLocalOption(key: optionKey, value: value);

  static bool get onLeft => choice == left;

  static bool isLandscape() {
    final s = MediaQueryData.fromView(
            WidgetsBinding.instance.platformDispatcher.views.first)
        .size;
    return s.width > s.height;
  }

  /// Width the canvas must give up while the panel is shown.
  static double reservedWidth(Size screen) =>
      visible.value && screen.width > screen.height
          ? screen.width * widthFraction
          : 0;

  /// Lets the user pick how the keyboard works in landscape.
  static Future<String?> choose(BuildContext context) async {
    final current = choice;
    Widget item(String value, IconData icon, String title, String sub) =>
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(sub),
          trailing: current == value ? const Icon(Icons.check) : null,
          onTap: () => Navigator.of(context).pop(value),
        );
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('가로 화면 키보드'),
        children: [
          item(right, Icons.border_right, 'JinDesk 키보드 · 오른쪽',
              '화면은 왼쪽, 키보드는 오른쪽'),
          item(left, Icons.border_left, 'JinDesk 키보드 · 왼쪽',
              '키보드는 왼쪽, 화면은 오른쪽'),
          item(phone, Icons.keyboard, '휴대폰 키보드', '평소 쓰는 키보드'),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text('한 번 고르면 다음 연결에도 그대로 씁니다.\n'
                '키보드 버튼을 길게 누르면 다시 고를 수 있습니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
    if (picked != null) await setChoice(picked);
    return picked;
  }
}

const _letters = [
  ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
  ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
  ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
];
const _jamo = [
  ['ㅂ', 'ㅈ', 'ㄷ', 'ㄱ', 'ㅅ', 'ㅛ', 'ㅕ', 'ㅑ', 'ㅐ', 'ㅔ'],
  ['ㅁ', 'ㄴ', 'ㅇ', 'ㄹ', 'ㅎ', 'ㅗ', 'ㅓ', 'ㅏ', 'ㅣ'],
  ['ㅋ', 'ㅌ', 'ㅊ', 'ㅍ', 'ㅠ', 'ㅜ', 'ㅡ'],
];
const _jamoShift = {
  'ㅂ': 'ㅃ', 'ㅈ': 'ㅉ', 'ㄷ': 'ㄸ', 'ㄱ': 'ㄲ', 'ㅅ': 'ㅆ', //
  'ㅐ': 'ㅒ', 'ㅔ': 'ㅖ',
};
const _symbols = [
  ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
  ['@', '#', '%', '&', '*', '-', '+', '=', '(', ')'],
  [',', '!', '"', "'", ':', ';', '/', '?'],
];
const _symbolsShift = [
  ['[', ']', '{', '}', '<', '>', '\\', '|', '~', '`'],
  ['\$', '_', '^', '₩', '€', '£', '¥', '·', '°', '…'],
  [',', '!', '"', "'", ':', ';', '/', '?'],
];

enum _Mode { ko, en, sym }

const _bg = Color(0xFF1C2127);
const _keyBg = Color(0xFF2D343C);
const _keyFn = Color(0xFF3A434D);
const _teal = Color(0xFF0F6B5C);
const _tealOn = Color(0xFF15937E);

class JinhoSideKeyboardPanel extends StatefulWidget {
  final VoidCallback onHide;
  final VoidCallback onUsePhoneKeyboard;
  final VoidCallback onSwapSide;

  const JinhoSideKeyboardPanel(
      {Key? key,
      required this.onHide,
      required this.onUsePhoneKeyboard,
      required this.onSwapSide})
      : super(key: key);

  @override
  State<JinhoSideKeyboardPanel> createState() => _JinhoSideKeyboardPanelState();
}

class _JinhoSideKeyboardPanelState extends State<JinhoSideKeyboardPanel> {
  final _composer = HangulComposer();
  _Mode _mode = _Mode.ko;
  bool _shift = false;
  bool _ctrl = false;
  bool _alt = false;
  bool _win = false;
  Timer? _repeat;

  InputModel get _input => gFFI.inputModel;
  bool get _hasMods => _ctrl || _alt || _win;

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  bool get _allowed => _input.keyboardInputAllowed && _input.keyboardPerm;

  void _key(String name) {
    if (!_allowed) return;
    final ctrl = _input.ctrl, alt = _input.alt, command = _input.command;
    _input.ctrl = _ctrl;
    _input.alt = _alt;
    _input.command = _win;
    _input.inputKey(name);
    _input.ctrl = ctrl;
    _input.alt = alt;
    _input.command = command;
    if (_hasMods) setState(() => _ctrl = _alt = _win = false);
  }

  void _apply(HangulEdit edit) {
    if (!_allowed) return;
    for (var i = 0; i < edit.backspaces; i++) {
      _input.inputKey('VK_BACK');
    }
    if (edit.insert.isNotEmpty) {
      bind.sessionInputString(sessionId: gFFI.sessionId, value: edit.insert);
    }
  }

  void _special(String vk) {
    _composer.commit();
    _key(vk);
  }

  void _letter(int row, int col) {
    final latin = _letters[row][col];
    if (_hasMods) {
      _composer.commit();
      _key(latin);
      return;
    }
    if (_mode == _Mode.ko) {
      var j = _jamo[row][col];
      if (_shift) j = _jamoShift[j] ?? j;
      _apply(_composer.input(j));
    } else {
      _composer.commit();
      _key(_shift ? latin.toUpperCase() : latin);
    }
    if (_shift) setState(() => _shift = false);
  }

  void _symbol(String s) {
    _composer.commit();
    _key(s);
    if (_shift) setState(() => _shift = false);
  }

  void _backspace() {
    if (_hasMods) {
      _special('VK_BACK');
      return;
    }
    _apply(_composer.backspace());
  }

  void _startRepeat() {
    _repeat?.cancel();
    _repeat = Timer.periodic(
        const Duration(milliseconds: 90), (_) => _backspace());
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
  }

  Widget _cap(String label,
      {required VoidCallback onTap,
      double flex = 1,
      Color color = _keyBg,
      bool active = false,
      double fontSize = 17,
      IconData? icon,
      VoidCallback? onHoldStart,
      VoidCallback? onHoldEnd}) {
    final child = Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: active ? _tealOn : color,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, color: Colors.white, size: fontSize + 3)
          : Text(label,
              maxLines: 1,
              style: TextStyle(color: Colors.white, fontSize: fontSize)),
    );
    return Expanded(
      flex: (flex * 10).round(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPressStart: onHoldStart == null ? null : (_) => onHoldStart(),
        onLongPressEnd: onHoldEnd == null ? null : (_) => onHoldEnd(),
        child: child,
      ),
    );
  }

  Widget _row(List<Widget> keys, {double flex = 1}) => Expanded(
        flex: (flex * 10).round(),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: keys),
      );

  List<Widget> _charKeys(int row) {
    if (_mode == _Mode.sym) {
      final set = _shift ? _symbolsShift : _symbols;
      return set[row].map((s) => _cap(s, onTap: () => _symbol(s))).toList();
    }
    final out = <Widget>[];
    for (var c = 0; c < _letters[row].length; c++) {
      String label;
      if (_mode == _Mode.ko) {
        label = _jamo[row][c];
        if (_shift) label = _jamoShift[label] ?? label;
      } else {
        label = _shift ? _letters[row][c].toUpperCase() : _letters[row][c];
      }
      out.add(_cap(label, onTap: () => _letter(row, c)));
    }
    return out;
  }

  Widget _menuKey() {
    return Expanded(
      flex: 12,
      child: PopupMenuButton<int>(
        padding: EdgeInsets.zero,
        tooltip: '',
        onSelected: (v) {
          _composer.commit();
          if (v == 0) {
            widget.onHide();
          } else if (v == 1) {
            widget.onSwapSide();
          } else {
            widget.onUsePhoneKeyboard();
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 0, child: Text('키보드 숨기기')),
          PopupMenuItem(
              value: 1,
              child: Text(JinhoSideKeyboard.onLeft
                  ? '키보드를 오른쪽으로'
                  : '키보드를 왼쪽으로')),
          const PopupMenuItem(value: 2, child: Text('휴대폰 키보드로 바꾸기')),
        ],
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
              color: _keyFn, borderRadius: BorderRadius.circular(6)),
          alignment: Alignment.center,
          child: const Icon(Icons.keyboard_hide, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const fn = 12.0;
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row([
            _cap('Esc', onTap: () => _special('VK_ESCAPE'), color: _keyFn, fontSize: fn),
            _cap('Tab', onTap: () => _special('VK_TAB'), color: _keyFn, fontSize: fn),
            _cap('Ctrl',
                onTap: () => setState(() => _ctrl = !_ctrl),
                color: _keyFn, fontSize: fn, active: _ctrl),
            _cap('Alt',
                onTap: () => setState(() => _alt = !_alt),
                color: _keyFn, fontSize: fn, active: _alt),
            _cap('Win',
                onTap: () => setState(() => _win = !_win),
                color: _keyFn, fontSize: fn, active: _win),
            _cap('Del', onTap: () => _special('VK_DELETE'), color: _keyFn, fontSize: fn),
            _cap('', icon: Icons.arrow_back, onTap: () => _special('VK_LEFT'), color: _keyFn, fontSize: fn),
            _cap('', icon: Icons.arrow_upward, onTap: () => _special('VK_UP'), color: _keyFn, fontSize: fn),
            _cap('', icon: Icons.arrow_downward, onTap: () => _special('VK_DOWN'), color: _keyFn, fontSize: fn),
            _cap('', icon: Icons.arrow_forward, onTap: () => _special('VK_RIGHT'), color: _keyFn, fontSize: fn),
          ], flex: 0.8),
          _row(_charKeys(0)),
          _row([
            if (_mode != _Mode.sym) const Spacer(flex: 5),
            ..._charKeys(1),
            if (_mode != _Mode.sym) const Spacer(flex: 5),
          ]),
          _row([
            _cap('', icon: Icons.arrow_upward_rounded,
                onTap: () => setState(() => _shift = !_shift),
                flex: 1.5, color: _keyFn, active: _shift),
            ..._charKeys(2),
            _cap('', icon: Icons.backspace_outlined,
                onTap: _backspace,
                onHoldStart: _startRepeat,
                onHoldEnd: _stopRepeat,
                flex: 1.5, color: _keyFn),
          ]),
          _row([
            _menuKey(),
            _cap(_mode == _Mode.ko ? '한' : 'A',
                onTap: () => setState(() {
                      _composer.commit();
                      _shift = false;
                      _mode = _mode == _Mode.ko ? _Mode.en : _Mode.ko;
                    }),
                flex: 1.2, color: _keyFn, fontSize: 15),
            _cap(_mode == _Mode.sym ? '가A' : '123',
                onTap: () => setState(() {
                      _composer.commit();
                      _shift = false;
                      _mode = _mode == _Mode.sym ? _Mode.ko : _Mode.sym;
                    }),
                flex: 1.2, color: _keyFn, fontSize: 14),
            _cap('', icon: Icons.space_bar,
                onTap: () => _special('VK_SPACE'), flex: 3.6),
            _cap('.', onTap: () => _symbol('.')),
            _cap('', icon: Icons.keyboard_return,
                onTap: () => _special('VK_RETURN'), flex: 1.8, color: _teal),
          ]),
        ],
      ),
    );
  }
}

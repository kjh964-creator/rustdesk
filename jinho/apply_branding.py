"""Turns the stock RustDesk tree into JinhoDesk (run once after checkout, before building)."""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
SERVER_KEY = "mYP5xgXB6Hd5AhZGBN5hPUgP8d5AW62VQrqW+LuPTaY="

EDITS = {
    "libs/hbb_common/src/config.rs": [
        ('&["rs-ny.rustdesk.com"]', '&["imist.co.kr"]'),
        ('"OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw="', f'"{SERVER_KEY}"'),
        ('APP_NAME: RwLock<String> = RwLock::new("RustDesk".to_owned());',
         'APP_NAME: RwLock<String> = RwLock::new("JinhoDesk".to_owned());'),
        ('DEFAULT_DISPLAY_SETTINGS: RwLock<HashMap<String, String>> = Default::default();',
         'DEFAULT_DISPLAY_SETTINGS: RwLock<HashMap<String, String>> = RwLock::new(HashMap::from([("show_monitors_toolbar".to_owned(), "Y".to_owned())]));'),
        ('DEFAULT_SETTINGS: RwLock<HashMap<String, String>> = Default::default();',
         'DEFAULT_SETTINGS: RwLock<HashMap<String, String>> = RwLock::new(HashMap::from([("allow-auto-update".to_owned(), "Y".to_owned()), ("api-server".to_owned(), "https://imist.co.kr/desk".to_owned())]));'),
        ('BUILTIN_SETTINGS: RwLock<HashMap<String, String>> = Default::default();',
         'BUILTIN_SETTINGS: RwLock<HashMap<String, String>> = RwLock::new(HashMap::from([("hide-powered-by-me".to_owned(), "Y".to_owned())]));'),
    ],
    "flutter/android/app/build.gradle": [
        ('applicationId "com.carriez.flutter_hbb"', 'applicationId "com.jinho.desk"'),
    ],
    "flutter/android/app/src/main/AndroidManifest.xml": [
        (('android:label="RustDesk"', 'android:label="진호 데스크"'), 'android:label="JinDesk"'),
        (('android:label="RustDesk Input"', 'android:label="진호 데스크 입력"'), 'android:label="JinDesk 입력"'),
    ],
    "flutter/android/app/src/main/res/values/strings.xml": [
        (('<string name="app_name">RustDesk</string>', '<string name="app_name">진호 데스크</string>'), '<string name="app_name">JinDesk</string>'),
    ],
    "Cargo.toml": [
        (('ProductName = "RustDesk"', 'ProductName = "JinhoDesk"'), 'ProductName = "JinDesk"'),
        (('FileDescription = "RustDesk Remote Desktop"', 'FileDescription = "JinhoDesk Remote Desktop"'), 'FileDescription = "JinDesk Remote Desktop"'),
    ],
    "flutter/windows/runner/Runner.rc": [
        (('VALUE "ProductName", "RustDesk" "\\0"', 'VALUE "ProductName", "JinhoDesk" "\\0"'), 'VALUE "ProductName", "JinDesk" "\\0"'),
        (('VALUE "FileDescription", "RustDesk Remote Desktop" "\\0"', 'VALUE "FileDescription", "JinhoDesk Remote Desktop" "\\0"'),
         'VALUE "FileDescription", "JinDesk Remote Desktop" "\\0"'),
    ],
}

for rel, pairs in EDITS.items():
    path = ROOT / rel
    raw = path.read_bytes()
    text = raw.decode("utf-8")
    for olds, new in pairs:
        olds = olds if isinstance(olds, tuple) else (olds,)
        if new in text and not any(o in text for o in olds):
            continue
        hits = [o for o in olds if text.count(o) == 1]
        if len(hits) != 1:
            raise SystemExit(f"{rel}: expected 1 match for {olds!r}")
        text = text.replace(hits[0], new)
    path.write_bytes(text.encode("utf-8"))
    print(f"patched {rel}")

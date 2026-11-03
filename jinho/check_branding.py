"""Checks that apply_branding.py turned the stock RustDesk tree into JinhoDesk."""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SERVER_KEY = "mYP5xgXB6Hd5AhZGBN5hPUgP8d5AW62VQrqW+LuPTaY="

EXPECT = {
    "libs/hbb_common/src/config.rs": [
        'pub const RENDEZVOUS_SERVERS: &[&str] = &["imist.co.kr"];',
        f'pub const RS_PUB_KEY: &str = "{SERVER_KEY}";',
        'APP_NAME: RwLock<String> = RwLock::new("JinhoDesk".to_owned());',
        'DEFAULT_DISPLAY_SETTINGS: RwLock<HashMap<String, String>> = RwLock::new(HashMap::from([("show_monitors_toolbar".to_owned(), "Y".to_owned())]));',
        'DEFAULT_SETTINGS: RwLock<HashMap<String, String>> = RwLock::new(HashMap::from([("allow-auto-update".to_owned(), "Y".to_owned()), ("api-server".to_owned(), "https://imist.co.kr/desk".to_owned())]));',
        'BUILTIN_SETTINGS: RwLock<HashMap<String, String>> = RwLock::new(HashMap::from([("hide-powered-by-me".to_owned(), "Y".to_owned())]));',
    ],
    "flutter/android/app/build.gradle": ['applicationId "com.jinho.desk"'],
    "flutter/android/app/src/main/AndroidManifest.xml": [
        'android:label="진호 데스크"',
        'android:label="진호 데스크 입력"',
    ],
    "flutter/android/app/src/main/res/values/strings.xml": [
        '<string name="app_name">진호 데스크</string>'
    ],
    "Cargo.toml": ['ProductName = "JinhoDesk"'],
    "flutter/windows/runner/Runner.rc": ['VALUE "ProductName", "JinhoDesk" "\\0"'],
}
FORBID = {
    "libs/hbb_common/src/config.rs": ["rs-ny.rustdesk.com", "OeVuKk5nlHiXp"],
    "flutter/android/app/build.gradle": ['applicationId "com.carriez.flutter_hbb"'],
}

failures = []
for rel, needles in EXPECT.items():
    text = (ROOT / rel).read_text(encoding="utf-8")
    failures += [f"{rel}: missing {n}" for n in needles if n not in text]
for rel, needles in FORBID.items():
    text = (ROOT / rel).read_text(encoding="utf-8")
    failures += [f"{rel}: still has {n}" for n in needles if n in text]

print("\n".join(failures) or "branding OK")
sys.exit(1 if failures else 0)

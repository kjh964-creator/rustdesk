"""Set the JinhoDesk version everywhere it matters.

Usage: python jinho/set_version.py 1.5.2

- Cargo.toml `version` -> crate::VERSION, compared by the updater
- flutter/pubspec.yaml `version: X.Y.Z+CODE` -> Windows file version and the
  Android versionCode, which must grow for an APK to install over the old one
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def version_code(v: str) -> int:
    major, minor, patch = (int(x) for x in v.split("."))
    return major * 10000 + minor * 100 + patch


def sub_once(path: Path, pattern: str, repl: str) -> None:
    text = path.read_text(encoding="utf-8")
    new, n = re.subn(pattern, repl, text, count=1, flags=re.M)
    if n != 1:
        sys.exit(f"{path}: version line not found")
    path.write_text(new, encoding="utf-8", newline="")
    print(f"{path.relative_to(ROOT)}: {repl}")


def main() -> None:
    if len(sys.argv) != 2 or not re.fullmatch(r"\d+\.\d+\.\d+", sys.argv[1]):
        sys.exit("usage: set_version.py X.Y.Z")
    v = sys.argv[1]
    sub_once(ROOT / "Cargo.toml", r'^version = "[^"]+"', f'version = "{v}"')
    sub_once(ROOT / "flutter/pubspec.yaml", r"^version: .+$",
             f"version: {v}+{version_code(v)}")


if __name__ == "__main__":
    main()

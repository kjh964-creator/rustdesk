"""Build and sign jinhodesk-update.json for a GitHub release.

Usage:
  JINHO_UPDATE_KEY=<base64 raw ed25519 private key> \
  python jinho/make_update_metadata.py <version> <out_dir> <exe> [<apk>]

Writes, in out_dir: JinhoDesk-<v>-x86_64.exe, JinhoDesk-<v>-arm64.apk,
jinhodesk-update.json and jinhodesk-update.json.sig. The installed app
(src/update_metadata.rs) verifies the signature over
CONTEXT + exact json bytes with its built-in public key, then the SHA-256
of the downloaded file.
"""
import base64
import datetime
import hashlib
import json
import os
import shutil
import sys
from pathlib import Path

from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

REPO = "kjh964-creator/rustdesk"
CONTEXT = b"JinhoDesk update metadata v1\n"
KEY_ID = "jinhodesk-2026-ed25519"
EXPECTED_PUBLIC_KEY = bytes([
    215, 38, 104, 203, 112, 248, 237, 127, 199, 108, 196, 140, 187, 176, 91, 123,
    73, 125, 5, 34, 106, 5, 223, 108, 75, 59, 173, 197, 157, 170, 95, 117,
])


def artifact(path: Path, platform: str, arch: str, fmt: str, release_id: str):
    data = path.read_bytes()
    return {
        "platform": platform,
        "arch": arch,
        "format": fmt,
        "url": f"https://github.com/{REPO}/releases/download/{release_id}/{path.name}",
        "file_name": path.name,
        "size": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
    }


def main() -> None:
    if len(sys.argv) not in (4, 5):
        sys.exit(__doc__)
    version, out = sys.argv[1], Path(sys.argv[2])
    release_id = f"v{version}"
    out.mkdir(parents=True, exist_ok=True)

    key = Ed25519PrivateKey.from_private_bytes(
        base64.b64decode(os.environ["JINHO_UPDATE_KEY"]))
    from cryptography.hazmat.primitives import serialization as s
    pub = key.public_key().public_bytes(s.Encoding.Raw, s.PublicFormat.Raw)
    if pub != EXPECTED_PUBLIC_KEY:
        sys.exit("JINHO_UPDATE_KEY does not match the public key built into the app")

    exe = out / f"JinhoDesk-{version}-x86_64.exe"
    shutil.copyfile(sys.argv[3], exe)
    artifacts = [artifact(exe, "windows", "x86_64", "exe", release_id)]
    if len(sys.argv) == 5:
        apk = out / f"JinhoDesk-{version}-arm64.apk"
        shutil.copyfile(sys.argv[4], apk)
        artifacts.append(artifact(apk, "android", "aarch64", "apk", release_id))

    metadata = {
        "schema_version": 1,
        "app": "jinhodesk",
        "package_id": "jinhodesk",
        "version": version,
        "release_id": release_id,
        "published_at": datetime.datetime.now(datetime.timezone.utc)
        .strftime("%Y-%m-%dT%H:%M:%SZ"),
        "signature_key_id": KEY_ID,
        "artifacts": artifacts,
    }
    meta_bytes = json.dumps(metadata, indent=2).encode()
    sig = key.sign(CONTEXT + meta_bytes)
    (out / "jinhodesk-update.json").write_bytes(meta_bytes)
    (out / "jinhodesk-update.json.sig").write_text(json.dumps({
        "schema_version": 1,
        "algorithm": "ed25519",
        "key_id": KEY_ID,
        "signature": base64.b64encode(sig).decode(),
    }))
    key.public_key().verify(sig, CONTEXT + meta_bytes)
    print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    main()

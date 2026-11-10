#!/usr/bin/env python3
"""Bundle the three SHA-verified original H55 PC580 GLBs in an UNSIGNED IPA.

Do not use on signed apps: changing app resources invalidates their signature.
The compiled iOS binary and all other original game assets remain unchanged.
"""
import argparse
import hashlib
import json
import struct
import sys
import zipfile
from pathlib import Path

MODELS = {
    "gloves_parted.glb": (4968356, "8a494bbd9a3dd6eb70cb5e22a7db4da7ec33b069dc1b0bab36f6a1c5b4c257ca"),
    "gloves_combined.glb": (4144252, "643bfa2799535852362103fa4d24b84d712637d686e773403214400a31ae4516"),
    "EXP01_SOURCE_v601.glb": (4504600, "07403302f23cb81ce6c26501ca7361c646550c6f91e0a949ce81566553139762"),
}

def check(name, raw):
    size, expected = MODELS[name]
    assert len(raw) == size, f"{name}: wrong size"
    assert hashlib.sha256(raw).hexdigest() == expected, f"{name}: wrong SHA256"
    assert raw[:4] == b"glTF" and struct.unpack_from("<I", raw, 4)[0] == 2, f"{name}: not GLB2"
    assert struct.unpack_from("<I", raw, 8)[0] == len(raw), f"{name}: bad GLB length"

def pack(ipa_path, models_path, output):
    assert ipa_path.resolve() != output.resolve(), "Never overwrite the original IPA"
    with zipfile.ZipFile(models_path) as archive:
        assert archive.testzip() is None
        models = {name: archive.read(name) for name in MODELS}
    for name, payload in models.items():
        check(name, payload)
    with zipfile.ZipFile(ipa_path) as ipa:
        assert ipa.testzip() is None
        originals = ipa.namelist()
        roots = {x.split(".app/", 1)[0] + ".app/" for x in originals
                 if x.startswith("Payload/") and ".app/" in x}
        assert len(roots) == 1, f"Ambiguous IPA application roots: {roots}"
        root = roots.pop()
        assert root + "Info.plist" in originals, "Info.plist is missing"
        assert not any(x.startswith(root + "_CodeSignature/") for x in originals), (
            "This IPA is signed: app bundle cannot be changed safely"
        )
        assert all(root + name not in originals for name in MODELS), (
            "Source IPA already embeds one or more H55 GLBs"
        )
        with zipfile.ZipFile(output, "w") as assembled:
            for info in ipa.infolist():
                assembled.writestr(info, ipa.read(info))
            for name, payload in models.items():
                assembled.writestr(root + name, payload,
                                   compress_type=zipfile.ZIP_DEFLATED,
                                   compresslevel=6)
    with zipfile.ZipFile(ipa_path) as original, zipfile.ZipFile(output) as assembled:
        assert assembled.testzip() is None, "Final IPA CRC error"
        assert len(assembled.namelist()) == len(originals) + len(models)
        for name in MODELS:
            check(name, assembled.read(root + name))
        for name in originals:
            if not name.endswith("/"):
                assert assembled.read(name) == original.read(name), (
                    "An original application resource changed unexpectedly: " + name
                )
    print(json.dumps({"status":"PASS", "output":str(output),
                      "source_ipa":str(ipa_path), "model_package":str(models_path),
                      "original_models":list(MODELS),
                      "sha256":hashlib.sha256(output.read_bytes()).hexdigest()},
                     indent=2, ensure_ascii=False))

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--ipa", required=True, type=Path)
    parser.add_argument("--models", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    opts=parser.parse_args()
    pack(opts.ipa,opts.models,opts.output)

if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)

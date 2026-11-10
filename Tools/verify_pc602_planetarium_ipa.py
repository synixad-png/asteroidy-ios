#!/usr/bin/env python3
"""Release gate: the IPA itself MUST contain original PC v602 planetarium GLB.

A successful xcodebuild is not enough: the expected exact file must exist
at the root of the compiled app, survive ZIP packaging, and be SHA-equivalent
to the versioned source. No post-CI local patching is permitted.
"""
from pathlib import Path
import hashlib
import plistlib
import sys
import zipfile

from stage_pc602_planetarium import SHA256, SIZE, verified_bytes

def verify(ipa: Path) -> None:
    source=verified_bytes()
    if not ipa.is_file():
        raise RuntimeError(f"Missing IPA: {ipa}")
    with zipfile.ZipFile(ipa) as archive:
        if archive.testzip() is not None:
            raise RuntimeError("IPA ZIP CRC failed")
        app_plists=[name for name in archive.namelist()
                    if name.startswith("Payload/") and name.endswith(".app/Info.plist")
                    and name.count("/")==2]
        if len(app_plists)!=1:
            raise RuntimeError("Expected one native .app in IPA")
        app=app_plists[0].removesuffix("Info.plist")
        expected=app+"planetarium.glb"
        matches=[name for name in archive.namelist()
                 if name.endswith("/planetarium.glb")]
        if matches != [expected]:
            raise RuntimeError(f"Missing/duplicated original planetarium at app root: {matches}")
        bundled=archive.read(expected)
        if len(bundled)!=SIZE or hashlib.sha256(bundled).hexdigest()!=SHA256:
            raise RuntimeError("IPA planetarium differs from PC v602 original")
        if bundled != source:
            raise RuntimeError("IPA model not byte-identical to GitHub versioned source")
        info=plistlib.loads(archive.read(app+"Info.plist"))
        if set(info.get("UIDeviceFamily", []))!={1,2}:
            raise RuntimeError("IPA must support iPhone and iPad")
    print(f"PASS FINAL IPA contains exact original PC v602 planetarium.glb "
          f"({SIZE} bytes; SHA256 {SHA256}; no substitutions)")


if __name__=="__main__":
    try:
        if len(sys.argv)!=2:
            raise RuntimeError("Usage: python3 Tools/verify_pc602_planetarium_ipa.py final.ipa")
        verify(Path(sys.argv[1]))
    except (RuntimeError, OSError, zipfile.BadZipFile, ValueError) as exc:
        print(f"FAIL FINAL IPA planetarium: {exc}", file=sys.stderr)
        sys.exit(1)

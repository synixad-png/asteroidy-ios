#!/usr/bin/env python3
"""Verify the REAL compiled iPhone+iPad .app contains authentic Vanguard431.

This is an Apple-build output validation, not a gameplay/GPU visual test.
Fail if Xcode silently omits either original source binary even though
the GitHub checkout contains it. No IPA is created by this script.
"""
import argparse
import pathlib
import plistlib
import struct
import sys

from verify_original_vanguard_resources import EXPECTED, inspect_assets


def inspect_app(app: pathlib.Path) -> dict:
    if not app.is_dir() or app.suffix != ".app":
        raise ValueError(f"Expected built native iOS .app: {app}")
    info_path = app / "Info.plist"
    if not info_path.is_file():
        raise ValueError("The built app has no Info.plist")
    with info_path.open("rb") as f:
        info = plistlib.load(f)
    if info.get("CFBundlePackageType") != "APPL":
        raise ValueError("Compiled bundle is not an application")
    if set(info.get("UIDeviceFamily", [])) != {1, 2}:
        raise ValueError("Compiled app does not target BOTH iPhone and iPad")
    if info.get("MinimumOSVersion") != "17.0":
        raise ValueError("Unexpected minimum iOS version")
    if info.get("CFBundleSupportedPlatforms") != ["iPhoneOS"]:
        raise ValueError("Compiled bundle is not a physical iOS target")
    exe = app / info.get("CFBundleExecutable", "")
    if not exe.is_file():
        raise ValueError("Compiled iOS arm64 executable is absent")
    with exe.open("rb") as f:
        mach = f.read(32)
    if len(mach) < 32 or struct.unpack_from("<II", mach) != (
            0xfeedfacf, 0x0100000c):
        raise ValueError("Compiled executable is not native arm64 Mach-O")
    metallibs = [p for p in app.rglob("default.metallib") if p.is_file()]
    if len(metallibs) != 1 or metallibs[0].stat().st_size <= 1024:
        raise ValueError("Original Metal shader library is not bundled exactly once")

    verified = {}
    paths = {}
    for name in EXPECTED:
        matches = [p for p in app.rglob(name) if p.is_file()]
        if len(matches) != 1:
            raise ValueError(
                f"Expected ONE original {name} in compiled .app, found {len(matches)}"
            )
        verified[name] = matches[0].read_bytes()
        paths[name] = str(matches[0].relative_to(app))
    inspect_assets(verified)
    print("PASS: the actual Xcode-compiled .app has BOTH original source assets")
    for name, path in paths.items():
        print(f"      {name}: {len(verified[name]):,} bytes at {path}")
    print("PASS: native arm64 Mach-O, iPhone + iPad, iOS 17+ and compiled Metal library")
    print("LIMIT: native Apple compile and resource packaging, not GPU pixels or Sideloadly")
    return paths


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=pathlib.Path, required=True)
    args = parser.parse_args()
    inspect_app(args.app)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"FAIL: built original Vanguard431 iPhone+iPad app: {exc}",
              file=sys.stderr)
        sys.exit(1)

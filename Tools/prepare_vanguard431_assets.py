#!/usr/bin/env python3
"""Install the already-verified ORIGINAL user Vanguard asset pair.

When the user-supplied 3.53 MB bundle is present in the repo at
AssetsCompressed/Vanguard431_ORYGINALNE_UV_TEKSTURA_ZASOBY.zip,
extract only the two exact, source-verified members into the Xcode
bundle resources. No Internet, guessed source GLB, alternate ship,
colour palette, or model conversion. Does NOT produce IPA.

Run before XcodeGen and build:
  python3 Tools/prepare_vanguard431_assets.py
Run locally with source pack from conversation:
  python3 Tools/prepare_vanguard431_assets.py --archive PATH/TO/ZIP

On absent archive this command prints an explicit message and exits
successfully; the separate strict release gate rejects missing assets
unless an explicitly selected old-AS3D compatibility build is requested.
"""
import argparse
import pathlib
import sys
import zipfile
from verify_original_vanguard_resources import EXPECTED,inspect_assets

ROOT=pathlib.Path(__file__).resolve().parents[1]
DEFAULT_ARCHIVE=(ROOT/"AssetsCompressed"/
    "Vanguard431_ORYGINALNE_UV_TEKSTURA_ZASOBY.zip")
DEFAULT_ASSETS=ROOT/"ASTEROIDYiOS"/"Assets"

def install(archive_path,assets_dir):
    if not archive_path.is_file():
        # Source files are now directly uploaded by the user to GitHub.
        # Do not require the old intermediary ZIP or report a false
        # fallback warning; still verify both bytes before returning.
        direct={name:(assets_dir/name).read_bytes()
                for name in EXPECTED if (assets_dir/name).is_file()}
        if len(direct)==len(EXPECTED):
            inspect_assets(direct)
            print("PASS: original Vanguard431 source pair uploaded directly"
                  " to ASTEROIDYiOS/Assets; ZIP extraction not required")
            return True
        if direct:
            raise ValueError(
                "Incomplete direct Vanguard431 upload: both source mesh"
                " and source BaseColor JPEG are required")
        print("Vanguard source assets are absent; retaining previous AS3D"
              " compatibility path. NEW textured IPA release gate will FAIL.")
        return False
    with zipfile.ZipFile(archive_path) as archive:
        damaged=archive.testzip()
        if damaged:
            raise ValueError("Original Vanguard source pack ZIP CRC failed: "+damaged)
        members={}
        for n in EXPECTED:
            name="ASTEROIDYiOS/Assets/"+n
            found=[p for p in archive.namelist() if p==name]
            if len(found)!=1:
                raise ValueError("Original pack is missing exact member: "+name)
            members[n]=archive.read(name)
        # Fully verify before writing any bytes into Xcode assets.
        inspect_assets(members)
    assets_dir.mkdir(parents=True,exist_ok=True)
    for name,blob in members.items():
        path=assets_dir/name
        if path.exists() and path.read_bytes()!=blob:
            raise ValueError("Refusing to overwrite non-original asset "+str(path))
        path.write_bytes(blob)
        print(f"INSTALLED: {path} ({len(blob):,} exact source bytes)")
    return True

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive",type=pathlib.Path,default=DEFAULT_ARCHIVE)
    parser.add_argument("--assets",type=pathlib.Path,default=DEFAULT_ASSETS)
    a=parser.parse_args()
    install(a.archive,a.assets)

if __name__=="__main__":
    try:main()
    except Exception as exc:
        print(f"FAIL: authentic Vanguard431 packaging: {exc}",file=sys.stderr)
        sys.exit(1)

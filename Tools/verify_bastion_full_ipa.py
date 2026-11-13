#!/usr/bin/env python3
"""Gate BASTION test IPA against original v609 Release asset manifest.

The SHA-256 values come from the complete PC609 iPhone/iPad IPA build.
This complements (does not replace) verify_ipa.py's arm64/CRC checks.
BASTION_PC609.bastion must be an original SHA-256-verified bundled iOS resource.
"""
from hashlib import sha256
from pathlib import Path
import plistlib
import sys
import zipfile

# Source-identical game assets unintentionally omitted by the first H290
# debug-build IPA. All must be present and byte-identical to the v609 Release.
REQUIRED = {
    "PlayerShip363Base.jpg": "9ed4fe25c25566f40b0ca401185c6280aa219e2ecb186d160ed3254d14eeb111",
    "PlayerShip367OriginalGPU.bin": "932b0a9028404562cfd28db4174f51ded5977e23a90c15580566c69f9c41819a",
    "PlayerShip367Source.json": "33cc2f7ab8a15463ca653e498535bb5566d0d747cfe34c1da20aaca32e487266",
    "Sector01CarbonisBase.dat": "8a9d5d2ad53d1c5bc8681f9ff17b83a3375fb7e16f58a3ed083a9157bcc58424",
    "Sector01CarbonisEmissive.dat": "cc32669e8e31dbf0942fa0db54fd04582af9bfbd02e7248932a04e7eb78646b3",
    "Sector01CarbonisHeightMap.dat": "3ce9a0456d23a5b88de718e7fd8fe6560cb53cd112a31ecc876e6200a762cb39",
    "Sector01CarbonisIndices.bin": "e542a65a0ddf0767d982b573da037becea7872cc8a6e0d5d1e1851cd90730bef",
    "Sector01CarbonisIrradiance.dat": "b1cc566768c655e643c450b1eba73cf718765b918e54d7f7a1ac30ac6045d685",
    "Sector01CarbonisSource.json": "33e185225271d614d74a15a93c44c5d11d1a0761bdcddc7bfe63ec2a37563a1c",
    "Sector01CarbonisVertices.bin": "b35318d059b9c4f180d03f36e52a6c4eea1225a484e339d3f117e5df9d7634bd",
    "W3Background568Original.dat": "a8aa28883084657f0c38900dbb011de09e2b0fd461704d370a68858be0178145",
    "W3Logo568Original.dat": "cab4198b953640c787975c5a8436a0fdeaa82502b40e000077ff055cc0709e09",
}

def audit(ipa:Path)->None:
    with zipfile.ZipFile(ipa) as archive:
        assert archive.testzip() is None, "Bad IPA CRC"
        plists = [x for x in archive.namelist() if x.startswith("Payload/")
                  and x.count("/") == 2 and x.endswith(".app/Info.plist")]
        assert len(plists) == 1, f"Expected one iOS application: {plists}"
        root = plists[0].rsplit("/",1)[0]
        info = plistlib.loads(archive.read(plists[0]))
        binary = f'{root}/{info["CFBundleExecutable"]}'
        assert binary in archive.namelist(), "Executable missing"
        # Xcode Debug links a tiny launcher and a debug dylib; it is not
        # the full standalone Release build used by v609.
        assert archive.getinfo(binary).file_size > 1_000_000, "Debug launcher, not Release application"
        assert f'{root}/{info["CFBundleExecutable"]}.debug.dylib' not in archive.namelist(), "Debug dylib packaged instead of Release"
        for name, expected in REQUIRED.items():
            path = f"{root}/{name}"
            assert path in archive.namelist(), f"Missing original game resource: {name}"
            digest = sha256(archive.read(path)).hexdigest()
            assert digest == expected, f"Original resource changed: {name} ({digest})"
        bastion=f"{root}/BASTION_PC609.bastion"
        assert bastion in archive.namelist(), "BASTION missing: IPA is not standalone"
        packed=archive.read(bastion)
        assert len(packed)==2_472_062, "BASTION size mismatch"
        assert sha256(packed).hexdigest()=="d18d651aab74bebdb2215940c0774c8aa3f0aff9101c0b7122c336110b3f5e7c", "BASTION SHA mismatch"
        assert packed[:8]==b"BST60901", "BASTION transport magic mismatch"
        print(f"PASS full v609 Release game: {len(REQUIRED)} original assets and bundled BASTION SHA256, no Debug launcher, IPA CRC")
        print(f"IPA: {ipa.name} / {ipa.stat().st_size:,} bytes")
        print("BASTION is included inside IPA and is accessible via Bundle.main; no import required")

if __name__ == "__main__":
    audit(Path(sys.argv[1]))

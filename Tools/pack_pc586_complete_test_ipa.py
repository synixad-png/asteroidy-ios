#!/usr/bin/env python3
"""Create ONE complete unsigned iOS test IPA with all verified original models.

Input: freshly built unsigned arm64 app IPA, the three original PC580
H55 first-person GLBs in the original H55 ZIP, and twelve original
PC586 pickup resources (4 GLB + 4 Metal meshes + 4 JPEGs).

This composes the existing canonical packers. It NEVER modifies a signed
IPA, the application executable, pre-existing assets, HUD, or game code.
"""
import argparse
import hashlib
import json
import os
import tempfile
import zipfile
from pathlib import Path

from pack_h55_original_models_ipa import MODELS as FPS_MODELS
from pack_h55_original_models_ipa import pack as pack_fps
from pack_pc586_unsigned_ipa import ORIGINALS as PICKUP_MODELS
from pack_pc586_unsigned_ipa import pack as pack_pickups
from prepare_pc586_runtime_resources import stage as stage_pickup_resources


def checksum(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for fragment in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(fragment)
    return digest.hexdigest()


def complete(source, fps, pickups, output, pickup_archive=None):
    for path in (source, fps):
        if not path.is_file():
            raise FileNotFoundError(path)
    if pickup_archive is None:
        if pickups is None or not pickups.is_dir():
            raise NotADirectoryError(pickups)
    elif not pickup_archive.is_file():
        raise FileNotFoundError(pickup_archive)
    if output.resolve() == source.resolve():
        raise ValueError("The input IPA must never be overwritten")
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="pc586_packer_", dir=output.parent) as scratch:
        scratch = Path(scratch)
        stage_h55 = scratch / "with_h55_unsigned.ipa"
        stage_all = scratch / "with_h55_and_pc586_unsigned.ipa"
        if pickup_archive is not None:
            # Build all 12 resources from the user's original PC586 ZIP
            # inside this one invocation; never substitute other models.
            pickups = scratch / "source_verified_pc586_pickups"
            stage_pickup_resources(pickup_archive, pickups)
        fps_receipt = pack_fps(source, fps, stage_h55)
        if fps_receipt.get("status") != "PASS":
            raise RuntimeError("H55 packer did not confirm integrity")
        pack_pickups(stage_h55, pickups, stage_all)
        with zipfile.ZipFile(stage_all) as archive:
            if archive.testzip() is not None:
                raise ValueError("Final ZIP CRC mismatch")
            roots = {name.split(".app/", 1)[0] + ".app/"
                     for name in archive.namelist()
                     if name.startswith("Payload/") and ".app/" in name}
            if len(roots) != 1:
                raise ValueError("Ambiguous IPA application")
            root = roots.pop()
            expected = set(FPS_MODELS)
            expected.update(model + "." + ext for model in PICKUP_MODELS
                            for ext in ("glb", "mesh", "jpg"))
            for name in expected:
                if root + name not in archive.namelist():
                    raise ValueError("Missing verified model in IPA: " + name)
            if len(expected) != 15:
                raise RuntimeError("Unexpected asset count")
        os.replace(stage_all, output)
    result = {
        "status": "PASS",
        "source_ipa_sha256": checksum(source),
        "result_ipa_sha256": checksum(output),
        "result_bytes": output.stat().st_size,
        "verified_embedded_model_assets": 15,
        "model_names": sorted(expected),
        "output": str(output)
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ipa", type=Path, required=True,
                        help="Fresh iOS ARM64 unsigned app IPA")
    parser.add_argument("--h55-models", type=Path, required=True,
                        help="Original H55 TRIPO/MONOLIT/EXP01 source ZIP")
    selection = parser.add_mutually_exclusive_group(required=True)
    selection.add_argument("--pc586-resources", type=Path,
                           help="Existing SHA-verified 12-resource directory")
    selection.add_argument("--pc586-archive", type=Path,
                           help="Original v586 PC reference ZIP or original four-model ZIP")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    complete(args.ipa, args.h55_models, args.pc586_resources,
             args.output, pickup_archive=args.pc586_archive)


if __name__ == "__main__":
    main()

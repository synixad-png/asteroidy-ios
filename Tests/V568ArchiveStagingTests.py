#!/usr/bin/env python3
"""Regression for audited ASTEROIDY v568 resource intake, never builds an IPA."""
import importlib.util
from pathlib import Path
import tempfile

ROOT=Path(__file__).resolve().parents[1]
SCRIPT=ROOT/"Tools/stage_v568_resources.py"
spec=importlib.util.spec_from_file_location("v568_archive_staging",SCRIPT)
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
for unsafe in ("../evil.glb","/absolute.glb","PortingResources//missing.glb",
               "PortingResources/../wrong.glb","PortingResources\\bad.glb",
               "C:/drive.glb","PortingResources/./bad.glb",
               "PortingResources/a/../../b.glb"):
    try:
        module.safe_member(unsafe)
    except module.VerificationError:
        pass
    else:
        raise AssertionError("Unsafe archive path accepted: "+unsafe)
assert str(module.safe_member("PortingResources/v568/Shared/assets/real.glb")) == (
    "PortingResources/v568/Shared/assets/real.glb")
assert len(module.PARTS)==4 and module.EXPECTED_FILES==90
archives=[]
try:
    archives,entries,hashes,total=module.verify_archive_set(ROOT)
    assert len(entries)==90 and len(hashes)==89 and total==74038695
    with tempfile.TemporaryDirectory() as temp:
        destination=Path(temp)/"v568-staged"
        module.stage(entries,destination)
        assert len([p for p in destination.rglob("*") if p.is_file()])==90
        assert (destination/"PortingReferenceCode/v568/Windows/src/PlanetMesh.cs").is_file()
        assert (destination/"PortingResources/v568/Shared/assets/planets/boreas_ferrofluid.glb").is_file()
        try:
            module.stage(entries,destination)
        except module.VerificationError:
            pass
        else:
            raise AssertionError("Source staging overwrote existing directory")
finally:
    for z in archives:
        z.close()
print("PASS: original v568 SHA256, four ZIPs, 90 files, 89 manifest entries, secure atomic staging")
print("LIMIT: no Xcode renderer integration or 26-planet gameplay parity claimed")

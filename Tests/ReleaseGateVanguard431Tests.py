#!/usr/bin/env python3
"""Offline adversarial tests of the real-vs-fallback release boundary.

The two verified original PC asset binaries are now in GitHub as
ASTEROIDYiOS/Assets/Vanguard431Source.mesh and Vanguard431Base.jpg.
This test proves missing/substituted assets are blocked; positive byte
validation is handled by OriginalVanguard431InstalledAssetsTests.py.
The user's full PC source ZIP is not stored in this repository.
"""
import importlib.util
import pathlib
import sys
import tempfile
import zipfile

root=pathlib.Path(__file__).resolve().parents[1]


def job_block(workflow_file, job):
    """Text of one job in a merged workflow file: its id line up to the next job id."""
    import re
    lines = (root/".github/workflows"/workflow_file).read_text().split("\n")
    start = lines.index(f"  {job}:")
    end = next((i for i in range(start + 1, len(lines))
                if re.match(r"^  [A-Za-z0-9_-]+:\s*$", lines[i])), len(lines))
    return "\n".join(lines[start:end])


def job_rule(workflow_file, job):
    """When a merged job runs: .github/ci-jobs.json (read by Tools/ci_select_jobs.py)."""
    import json
    return json.loads((root/".github/ci-jobs.json").read_text())[workflow_file][job]


def dispatch_input(workflow_file, name):
    """One workflow_dispatch input block of a workflow file."""
    lines = (root/".github/workflows"/workflow_file).read_text().split("\n")
    start = lines.index(f"      {name}:")
    end = next(i for i in range(start + 1, len(lines))
               if not lines[i].startswith("        "))
    return "\n".join(lines[start:end])


script=root/"Tools/verify_original_vanguard_resources.py"
spec=importlib.util.spec_from_file_location("vanguard_source_gate",script)
assert spec is not None and spec.loader is not None
gate=importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)

def rejects(callback,word):
    try:
        callback()
    except (ValueError,FileNotFoundError):
        return
    raise AssertionError("Release gate accepted invalid "+word)

for name,(size,sha) in gate.EXPECTED.items():
    assert len(sha)==64
    assert int(sha,16)>0
    assert size>1000000

rejects(lambda:gate.inspect_assets({}),"missing originals")
rejects(lambda:gate.inspect_assets({
    "Vanguard431Source.mesh":b"fake mesh",
    "Vanguard431Base.jpg":b"fake image",
}),"fake source")
rejects(lambda:gate.jpeg_dimensions(b"not a JPEG"),"invalid jpeg")
rejects(lambda:gate.jpeg_dimensions(b"\xff\xd8\xff\xd9"),
        "jpeg with no dimensions")

with tempfile.TemporaryDirectory() as tmp:
    path=pathlib.Path(tmp)/"not-fully-textured.ipa"
    with zipfile.ZipFile(path,"w") as z:
        z.writestr("Payload/ASTEROIDY iOS.app/Info.plist",b"plist")
        z.writestr("Payload/ASTEROIDY iOS.app/Vanguard431Base.jpg",
                   b"not original")
    rejects(lambda:gate.read_app_ipa(path),
            "IPA missing original mesh (fallback-only IPA)")

manual=job_block("build-ipa.yml","device-universal")
manual_rule=job_rule("build-ipa.yml","device-universal")
compat_input=dispatch_input("build-ipa.yml","compatibility_old_ship")
ipa=(root/"Tools/verify_ipa.py").read_text()
assert "        default: false" in compat_input, "original asset gate bypass must not be default"
assert "python3 Tools/verify_original_vanguard_resources.py --assets ASTEROIDYiOS/Assets" in manual
assert "--require-vanguard-original" in manual
assert "--require-vanguard-original" in ipa
assert "compatibility_old_ship" in manual
assert "if: inputs.compatibility_old_ship == true" in manual
assert "rm -f ASTEROIDYiOS/Assets/Vanguard431Source.mesh" in manual
assert "rm -f ASTEROIDYiOS/Assets/Vanguard431Base.jpg" in manual
assert manual.index("rm -f ASTEROIDYiOS/Assets/Vanguard431Source.mesh") < manual.index(
    "Generate original iOS Xcode project"
), "Legacy compatibility must remove assets BEFORE XcodeGen bundles them"
assert "TARGETED_DEVICE_FAMILY=1,2" in manual
assert manual_rule["manual"] and manual_rule["push"] is None and manual_rule["pull_request"] is None
print("PASS: original Vanguard source material is mandatory for textured")
print("      releases; old AS3D fallback requires explicit compatibility")
print("      switch. Missing/malformed/renamed JPEG/mesh IPA rejected.")
print("      legacy mode really removes both sources in runner checkout")
print("POSITIVE: exact original source binaries are in GitHub;")
print("          separate source and native compiled-app tests verify them")

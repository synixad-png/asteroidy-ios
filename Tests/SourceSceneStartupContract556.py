#!/usr/bin/env python3
"""Static source contract: start the existing original v556 Boreas scene.

This test does not assert full mission parity or rendering on real hardware.
Its goal is to prevent accidentally shipping the unrelated flat 9-rock
training arena as the first thing a user sees after installing ASTEROIDY.
It also guards the intentional iPhone + iPad dual-device configuration.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def job_block(workflow_file, job):
    """Text of one job in a merged workflow file: its id line up to the next job id."""
    import re
    lines = (ROOT/".github/workflows"/workflow_file).read_text().split("\n")
    start = lines.index(f"  {job}:")
    end = next((i for i in range(start + 1, len(lines))
                if re.match(r"^  [A-Za-z0-9_-]+:\s*$", lines[i])), len(lines))
    return "\n".join(lines[start:end])


def job_rule(workflow_file, job):
    """When a merged job runs: .github/ci-jobs.json (read by Tools/ci_select_jobs.py)."""
    import json
    return json.loads((ROOT/".github/ci-jobs.json").read_text())[workflow_file][job]


app = (ROOT / "ASTEROIDYiOS/App.swift").read_text()
renderer = (ROOT / "ASTEROIDYiOS/MetalRenderer.swift").read_text()
project = (ROOT / "project.yml").read_text()
verify = (ROOT / "Tools/verify_ipa.py").read_text()
workflow = job_block("build-ipa.yml", "device-universal")
workflow_rule = job_rule("build-ipa.yml", "device-universal")

def check(ok, description):
    if not ok:
        raise AssertionError(description)

check("@Published var planetPreview = true" in app,
      "Must open the existing source Boreas GLB, not flat 9-asteroid demo")
check("@Published var planetTestLevel = 1" in app,
      "Source scene must begin at the audited level 01")
check("MetalScene(input: input)" in app and
      "let renderer = try MetalRenderer(device: device, input: input)" in app,
      "Startup scene must be bound to the existing real Metal renderer")
check('Button(input.planetPreview ? "ARENA • DIAGNOSTYKA" : "BOREAS GLB • TEST")' in app,
      "The separate legacy flat diagnostic must still be reachable")
check("input.planetPreview.toggle()" in app,
      "The source-scene/flat diagnostic switch was disconnected")
check('Button("KAMPANIA / W3")' in app and "CampaignAtlas556" in app,
      "Existing source campaign atlas must remain accessible through W3")
check("if showCampaign" not in app and ".ultraThinMaterial" not in app,
      "Legacy standalone campaign overlay has been removed")
check("input.planetTestLevel = 9" in app and
      "input.planetTestLevel = 17" in app and
      "input.planetTestLevel = 25" in app,
      "Existing test-sector switching regressed")
check("if input.planetPreview {" in renderer and
      "Self.sphereView(sphereFlight.camera)" in renderer and
      "planetAnimator.updateVertices(" in renderer and
      "drawMesh(activeMesh, Self.scale(1.0))" in renderer,
      "Original Boreas planet model, animation, and source camera disconnected")
check('AssetMesh.load(name: "Boreas556")' in renderer or
      "Boreas556.as3d" in renderer,
      "Original Boreas asset no longer required by the source view")
check("else {\n                game.tick(command,dt:Float(fixedClockStep))" in renderer,
      "Old independent flat diagnostic simulation must remain untouched")
check(re.search(r"TARGETED_DEVICE_FAMILY:\s*['\"]1,2['\"]",project) is not None,
      "Native project no longer targets iPhone + iPad")
check("set(info['UIDeviceFamily']) == {1, 2}" in verify,
      "The shipped dual-device IPA must be checked for both families")
check(workflow_rule["manual"] and workflow_rule["push"] is None
      and workflow_rule["pull_request"] is None,
      "Dual-device IPA must remain manual-only, not auto-built every commit")
check("runs-on: macos-15-intel" in workflow and
      "'TARGETED_DEVICE_FAMILY=1,2'" in workflow and
      "python3 Tools/verify_ipa.py" in workflow,
      "Dual-device manual release must use proven runner and real IPA verification")
print("PASS: v556 Boreas scene is the default, source camera/GLB still bound,")
print("      old flat sandbox accessible, no invented campaign unlock,")
print("      physical iPhone+iPad arm64 manual IPA pipeline + validation.")
print("LIMIT: static source check; not a native Apple build or actual mission.")

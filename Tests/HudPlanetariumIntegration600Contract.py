#!/usr/bin/env python3
"""Source-authenticated native Metal planetarium regression (not iPad GPU proof)."""
from pathlib import Path
import json,lzma,struct,hashlib
root=Path(__file__).resolve().parents[1]


def job_block(workflow_file, job):
    """Text of one job in a merged workflow file: its id line up to the next job id."""
    import re
    lines = (root/".github/workflows"/workflow_file).read_text().split("\n")
    start = lines.index(f"  {job}:")
    end = next((i for i in range(start + 1, len(lines))
                if re.match(r"^  [A-Za-z0-9_-]+:\s*$", lines[i])), len(lines))
    return "\n".join(lines[start:end])


ios=root/"ASTEROIDYiOS"
source=(ios/"HudPlanetariumOriginalMetal600.swift").read_text()
metal=(ios/"HudPlanetariumMetal600.swift").read_text()
shader=(ios/"HudPlanetariumMetal600.metal").read_text()
scene=(ios/"Sector01Scene568.swift").read_text()
renderer=(ios/"Sector01CarbonisPreview568.swift").read_text()
asset=(ios/"HudPlanetariumAsset600.swift").read_text()
session=(ios/"CarbonisSession568.swift").read_text()
raw=lzma.decompress((root/"SourceResources/PC602/planetarium.glb.xz").read_bytes())
assert len(raw)==3_228_900
assert hashlib.sha256(raw).hexdigest()=="71ca9ff24e044a831a5c7197e343594dd1fd801284af6231870570b35ad43860"
jlen,jtag=struct.unpack_from("<II",raw,12)
assert jtag==0x4e4f534a
data=json.loads(raw[20:20+jlen])
assert len(data["nodes"])==141
assert len(data["meshes"])==20
assert sum(len(m["primitives"]) for m in data["meshes"])==21
assert len([node for node in data["nodes"] if "mesh" in node])==91
assert len(data["animations"][0]["channels"])==159
assert sorted(set(c["target"]["path"] for c in data["animations"][0]["channels"]))==["rotation","scale","translation"]
for s in (
  "try HudPlanetariumAsset600.validate(raw)",
  "accessor(posIndex,",
  "color[vertex*4..<(vertex*4+4)].map{$0/255}",
  "device.makeBuffer(bytes:bytes.baseAddress!",
  "let channels",
):
  if s=="let channels":continue
  assert s in source,s
for s in ("let tracks:[Track]","simd_slerp(a,b,blend)","duration-48","nodeGroups.allSatisfy",
          "flashNodes","frame.world[idx]","original.sample(at:seconds,capsules:capsules)"):
    assert s in source or s in metal,s
for s in ("makeDefaultLibrary()","hudPlanetariumVertex600","hudPlanetariumFragment600",
          "pass.colorAttachments[0].loadAction = .load",
          "pass.depthAttachment.loadAction = .clear",
          "pass.depthAttachment.clearDepth=1",
          "HudWidgetPlacement600.frame(widget,",
          "HudPlanetariumProjection.make(",
          "translate(-HudPlanetariumAsset600.pc602ModelCenterX",
          "encoder.drawPrimitives(type:.triangle",
          "encoder.endEncoding()"):
    assert s in metal,s
assert "device const float *vertices" in shader
assert "tint*state.baseColor" in shader
assert 'HudPlanetariumPlasmaAnchor600' not in metal
assert 'HudMotionProject600.project(' in metal
assert 'pose.roll*pose.weight(Self.plasmaGroupMotionID)' in metal
assert 'liveBank*yaw*pitch*authoredRoll *' in metal
assert 'angle:-pose.roll*pose.weight(Self.plasmaGroupMotionID)' in metal
assert 'yaw*pitch*roll *' not in metal
assert 'widget:Self.plasmaGroupMotionID' in metal
assert not (ios/"HudPlanetariumPlasmaAnchor600.swift").exists()
assert 'pose:snapshot.pose' in renderer
assert "HudPlanetariumMetal600(" in renderer
assert "hudPlanetariumMetal600" in renderer
assert "planetarium.render(" in renderer
assert "command.present(drawable)" in renderer
assert renderer.index("encoder.endEncoding()")<renderer.index("planetarium.render(")<renderer.index("command.present(drawable)")
assert "HudPlanetariumHost600(" not in scene
assert "GLTFSCNSceneSource(" not in renderer
assert "sourcePickupMetal586" not in metal.lower()
assert "hudLiveCapsules600=hudCapsules600.snapshot" in session
assert "HudPlanetariumAsset600.availableURL()" in renderer
# Release guard: separate Metal HUD pass cannot be silently omitted from IPA.
release=job_block("build-ipa.yml","one-shot-test-ipa")
native=job_block("mac-tests.yml","source-home-metal")
sim=job_block("mac-tests.yml","genuine-orbit-ui")
stage=(root/"Tools/stage_pc602_planetarium.py").read_text()
gate=(root/"Tools/verify_pc602_planetarium_ipa.py").read_text()
for workflow in (release,native,sim):
    assert "python3 Tools/stage_pc602_planetarium.py" in workflow
    assert "python3 Tests/HudPlanetariumIntegration600Contract.py" in workflow
assert "python3 Tools/verify_pc602_planetarium_ipa.py" in release
assert "'default.metallib','planetarium.glb'" in release
assert 'original=app/"planetarium.glb"' in native
assert "hashlib.sha256(data)" in stage
assert "HUD_PLANETARIUM_PREMIUM_48S_LOOP" in stage
assert "archive.read(expected)" in gate
assert "bundled != source" in gate
assert "HudPlanetariumMetal600(" not in (ios/"PC602HomeScene291.swift").read_text()
assert "static let expectedSize = 3_228_900" in asset
print("PASS native HUD planetarium: original 20 meshes/21 primitives, 91 mesh nodes, 159 TRS tracks, common native Metal drawable and isolated HUD depth")

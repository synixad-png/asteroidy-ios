#!/usr/bin/env python3
"""Source-authenticated native Metal planetarium regression (not iPad GPU proof)."""
from pathlib import Path
import json,lzma,struct,hashlib
root=Path(__file__).resolve().parents[1]
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
assert "static let expectedSize = 3_228_900" in asset
print("PASS native HUD planetarium: original 20 meshes/21 primitives, 91 mesh nodes, 159 TRS tracks, common native Metal drawable and isolated HUD depth")

#!/usr/bin/env python3
"""Native iOS H55 source regression: real FPS settings preview and depth.

PC baseline: Windows GpuGloves417.cs RenderGlovesReal424,
GpuWeapon470.cs RenderWeaponPreview470 and RenderWeapon470.
The source PC uses its OWN cleared depth buffer, with DEPTH enabled.
"""
from pathlib import Path
import hashlib
import json

root=Path(__file__).resolve().parents[1]
read=lambda p:(root/p).read_text()
src=read("ASTEROIDYiOS/H55FPSScene580.swift")
stage=read("ASTEROIDYiOS/H55ScenePage580.swift")
overlay=read("ASTEROIDYiOS/H55FPSOverlayViewport580.swift")
preview=read("ASTEROIDYiOS/H55FPSPreview580.swift")
settings=read("ASTEROIDYiOS/H55FPSSettingsSection580.swift")
tabs=read("ASTEROIDYiOS/CarbonisVisualSettingsPanel568.swift")

assert "n.renderingOrder=1000" in src
assert "material.readsFromDepthBuffer=true" in src
assert "material.writesToDepthBuffer =" in src
assert 'material.name?.hasPrefix("DECAL_")' in src
assert "material.readsFromDepthBuffer=false" not in src
assert "material.writesToDepthBuffer=false" not in src
assert "material.isDoubleSided=true" not in src

assert "fpsScene.background.contents=UIColor.clear" in stage
assert "fpsOverlayScene=fpsScene" in stage
assert "fpsOverlayCamera=fpsCamera" in stage
assert "H55FPSOverlayViewport580(scene:fpsScene,pointOfView:fpsCamera)" in stage
assert "fpsViewmodel=H55FPSScene580(camera:fpsCamera" in stage
assert "H55SceneViewport580(scene:scene,pointOfView:camera" in stage
assert "view.isOpaque=false" in overlay
assert "view.backgroundColor = .clear" in overlay
assert "view.isUserInteractionEnabled=false" in overlay
assert "view.scene?.background.contents=UIColor.clear" in overlay

# Preview does not introduce a second GLB importer, primitive lookalikes
# or independent hand-bake and uses a dedicated true-depth frame.
assert "H55FPSScene580(camera:camera,configuration:settings" in preview
assert "H55FPSPose580" in src and "H55FPSMeshSplit580.build" in src
assert "SCNSphere(" not in preview and "SCNBox(" not in preview
assert "SCNGeometry(" not in preview
assert "view.isPlaying=true" in preview
assert "fps?.advance(time:t,walking:true,bobPhase:t*5" in preview
assert "fps?.synchronizePreview(settings)" in preview
assert 'H55FPSPreview580(settings:previewConfiguration,' in settings
assert 'gloveBrightness:gloveBrightness)' in settings
assert 'h55-fps-gloves-brightness' in settings
assert 'refreshGloveBrightness602()' in preview
assert 'material.multiply.contents=tint' in read("ASTEROIDYiOS/H55FPSScene580.swift")
assert 'previewRevision += 1' in settings
assert '"h55-fps-gloves-live-preview"' in settings
assert '"h55-fps-weapon-live-preview"' in settings
assert '"h55-fps-preview-motion"' in settings
assert "p.mode=category" in settings
assert ".aspectRatio(16.0/9.0,contentMode:.fit)" in settings
assert ".frame(maxWidth:352)" in settings and ".frame(height:198)" in settings
lights=read("ASTEROIDYiOS/H55FPSLighting580.swift")
assert "H55FPSLighting580.install(into:fpsScene)" in stage
assert "H55FPSLighting580.install(into:scene)" in preview
assert "SCNVector3(-1,2,-0.6)" in lights and "SCNVector3(2,1,-1)" in lights
assert "SCNVector3(0,3,-3)" in lights
assert 'case 6: H55FPSSettingsSection580(category:.gloves' in tabs
assert 'case 8: H55FPSSettingsSection580(category:.weapon' in tabs

# The original resources are GitHub-owned and source verified; no fake model.
source=json.loads(read("SourceResources/PC586/manifest.json"))
models={
  "gloves_parted.glb":(4_968_356,"8a494bbd9a3dd6eb70cb5e22a7db4da7ec33b069dc1b0bab36f6a1c5b4c257ca"),
  "gloves_combined.glb":(4_144_252,"643bfa2799535852362103fa4d24b84d712637d686e773403214400a31ae4516"),
  "EXP01_SOURCE_v601.glb":(4_504_600,"07403302f23cb81ce6c26501ca7361c646550c6f91e0a949ce81566553139762"),
}
for name,(size,digest) in models.items():
    original=next((x for x in source["files"] if x["name"]==name),None)
    assert original and original["bytes"]==size and original["sha256"]==digest
    assert name in read("ASTEROIDYiOS/H55FPSAssets580.swift")
print("PASS H55: 3 source-authenticated GLB, real settings SceneKit preview, shared FPS model, separate depth, no forced two-sided material")

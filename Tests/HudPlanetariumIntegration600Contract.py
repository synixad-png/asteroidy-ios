#!/usr/bin/env python3
"""HUD v600 planetarium connection regression; static, NOT an Apple GPU test."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
asset=(root/"ASTEROIDYiOS/HudPlanetariumAsset600.swift").read_text()
tracks=(root/"ASTEROIDYiOS/HudPlanetariumTracks600.swift").read_text()
view=(root/"ASTEROIDYiOS/HudPlanetariumScene600.swift").read_text()
scene=(root/"ASTEROIDYiOS/Sector01Scene568.swift").read_text()
host=(root/"ASTEROIDYiOS/HudPlanetariumHost600.swift").read_text()
session=(root/"ASTEROIDYiOS/CarbonisSession568.swift").read_text()
for snippet in ('static let expectedSize = 3_228_900',
                '71ca9ff24e044a831a5c7197e343594dd1fd801284af6231870570b35ad43860',
                'HUD_PLANETARIUM_PREMIUM_48S_LOOP', 'static let channels = 159',
                'static func install(from original:URL) throws -> URL',
                'startAccessingSecurityScopedResource'):
    assert snippet in asset, "missing strict original asset validation: "+snippet
for snippet in ('channels.count==HudPlanetariumAsset600.channels',
                'extents.count==72',
                'target["path"] as? String == "translation"',
                'UInt32(bytes.count)'):
    assert snippet in tracks or snippet in asset, "missing original glTF accessor gate: "+snippet
for snippet in ('GLTFAsset.load(with:url,options:[:])',
                'GLTFSCNSceneSource(asset:asset)',
                'clip.animationPlayer', 'didApplyAnimationsAtTime',
                'node.presentation.position.x','HudCapsuleBinding600',
                'view.isUserInteractionEnabled=false'):
    assert snippet in view, "missing genuine SceneKit animated layer: "+snippet
for snippet in ('HudPlanetariumAsset600.availableURL()',
                'HudPlanetariumAsset600.install(from:source)',
                '.allowsHitTesting(false)', 'HudPlanetariumHost600('):
    assert snippet in scene, "missing live combat HUD wiring: "+snippet
for snippet in ('HudPlanetariumScene600(', 'liveCapsules:{ [weak session] in',
                '.position(x:CGFloat(placement.centerX)',
                'session?.currentHudVisual600().capsules'):
    assert snippet in host, "missing live 3D HUD host wiring: "+snippet
assert 'let frameCapsules=liveCapsules?() ?? capsule' in view
assert 'playing:active' in host
assert 'if view.isPlaying != playing {view.isPlaying=playing}' in view
assert 'view.isPlaying=playing' in view
assert 'hudLiveCapsules600=hudCapsules600.snapshot' in session
assert 'snapshot.capsuleLevels=hudCapsules600.snapshot' in session
assert 'session.game.step(' not in view
assert 'Data(contentsOf:' not in view.split('func renderer(')[-1]
assert 'SourcePickupMetal586' not in view
print("PASS static HUD v600: verified original 159 tracks, 72 nodes, scene attachment, no live IO/touch intercept")

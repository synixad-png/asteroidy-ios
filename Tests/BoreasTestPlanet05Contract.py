#!/usr/bin/env python3
"""BOREAS sector-05 visual-only source contract.

This is a temporary animated planet slot and NOT a fifth playable mission.
Protect source-authenticated v556 geometry, 5s morph animation, existing
three-buffer GPU upload, HUD/mission routing and all PC609 progress rules.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def read(name):return (root/name).read_text(encoding="utf-8")
catalog=read("ASTEROIDYiOS/MissionCatalog568.swift")
slot=read("ASTEROIDYiOS/AnimatedPlanetTestSlot556.swift")
renderer=read("ASTEROIDYiOS/MetalRenderer.swift")
app=read("ASTEROIDYiOS/App.swift")
w3=read("ASTEROIDYiOS/W3MainMenu568.swift")
page=read("ASTEROIDYiOS/AnimatedPlanetTestPage556.swift")
progress=read("ASTEROIDYiOS/CampaignProgress556.swift")
sources=read("SOURCES_SHA256SUMS.txt")
for source in ("ASTEROIDYiOS/Assets/Boreas556.as3d",
               "ASTEROIDYiOS/Assets/Boreas556.asmo",
               "ASTEROIDYiOS/Assets/BoreasMorphBinding556.json"):
    assert (root/source).is_file(),source
    assert source in sources,source
assert '"BOREAS / LODOWCE"' in catalog
assert 'static let sector=5' in slot
assert 'static let duration:Double=5' in slot
assert 'static let nodeTracksName="Boreas556"' in slot
assert 'bdf22733cfe6a1314517537e2400019a97c3a83507b8f654fd1307dbf9809edc' in slot
for sha in ("0a18d88a734906811fc6421d79d68a56a2ae4bd7dd7a622fc89c46a4cd5fbf9b",
            "33c7bec0a53fe8a63e0c351658155ee74fc364cddef8ec261af15d6675a103a6",
            "f5f099707a1e63582934dc2bd26155e739225db26f3d358fd4a100fff9e50593"):
    assert sha in slot and sha in sources
assert 'sourceAssetsVerified' in slot and 'SHA256.hash(data:bytes)' in slot
assert 'AnimatedPlanetTestSlot556.meshName' in renderer
assert 'AnimatedPlanetTestSlot556.animationName' in renderer
assert 'AnimatedPlanetTestSlot556.bindingName' in renderer
assert 'AnimatedPlanetTestSlot556.sourceAssetsVerified' in renderer
assert 'BoreasNodeTracks556' in renderer
assert 'planetNodeTracks.updateVertices(seconds:seconds,' in renderer
assert 'let nodeBytes = nodes.count * strideBytes' in renderer
assert 'p.advanced(by:nodeStartByte),nodeBytes)' in renderer
assert 'planetNodeTracks=try BoreasNodeTracks556(' in renderer
nodeSource=read("ASTEROIDYiOS/BoreasNodeTracks556.swift")
assert '48 translation and 48 scale tracks' in nodeSource
assert 'abs(keys.last!.time-5)' in nodeSource
assert 'AnimatedPlanetTestSlot556.sector,9,17,25' in renderer
assert 'planetAnimator.updateVertices(seconds: seconds, into: &planetMorphScratch)' in renderer
assert 'planetBufferSlots.reserveWrite()' in renderer
assert 'planetBufferSlots.publish(slot)' in renderer
assert 'input.planetTestLevel=AnimatedPlanetTestSlot556.sector' in app
assert 'input.introPreview41=false' in app
assert 'input.planetPreview=true' in app
assert 'input.missionIntroSector=0' in app
assert 'showingBoreasTest05=true' in app
assert 'onBoreasTest:openBoreasTest' in w3
assert 'onBoreasTest()' in app
assert 'campaign-boreas05-animated-test' in app
assert 'w3-boreas05-test-direct' in w3
assert 'Button("BOREAS 05 · TEST PLANETY")' in w3
assert '.disabled(!AnimatedPlanetTestSlot556.sourceAssetsVerified)' in w3
assert app.index('campaign-boreas05-animated-test') < app.index('if progress.selectedSector == 1 {')
# The original W3 menu has seven production actions. This temporary
# explicit test must not become another production menu page or unlock.
assert 'case campaign = "KAMPANIA"' in w3
assert 'case boreas' not in w3
assert 'returnFromBoreasTest05' in app
assert 'reopenAtlasAfterCarbonis=true' in app
assert 'boreas-test-return-atlas' in page
assert 'TYLKO TEST MODELU 3D' in page
assert 'static let missionCount = 26' in progress
assert 'guard level==1,sourceSector01==nil' in app
assert 'Sector01MissionSettlement568.commit' in app
preview=app.split('private func enterBoreasTest05() {',1)[1].split('private func returnFromBoreasTest05()',1)[0]
for prohibited in ("CampaignStore556.save(", "finishMission(", "Sector01MissionSettlement568.commit(",
                   "Sector01Shop568.save(", "onMissionCompleted", "PC602OrbitSave61.store("):
    assert prohibited not in preview,prohibited
assert 'sourceSector01==nil, !showingHomeWorld291' in preview
assert 'sourceAssetsVerified else{return}' in preview
print("PASS: authenticated Boreas sector-05 morph test, 5s loop, 3-buffer GPU")
print("PASS: W3 atlas entry, no mission unlock, progress, reward or save changes")
print("PASS: original PC v609 GLB node translation and scale clips, 96/96 channels")

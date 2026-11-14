#!/usr/bin/env python3
"""BOREAS 05: protect the unchanged W3 GLB diagnostic AND the separate
source-backed campaign combat integration. The diagnostic cannot award or
unlock. The live mission must not claim a clear while RobotSnake AI is absent.
Protect 97 source animation channels, three-buffer GPU uploads and CARBONIS 01.
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
# The approved campaign binding is separate from the W3 diagnostic:
# sector 05 must be selected, unlocked by source progress, and verified.
orbit=read("ASTEROIDYiOS/PC602HomeWorldPage291.swift")
assert 'if progress.selectedSector==AnimatedPlanetTestSlot556.sector &&' in app
assert 'progress.unlocked(AnimatedPlanetTestSlot556.sector)' in app
assert 'campaign-enter-boreas05-planet' in app
assert 'onInspect(AnimatedPlanetTestSlot556.sector)' in app
assert 'if sector==AnimatedPlanetTestSlot556.sector {' in app
assert 'enterCampaignBoreas05()' in app
assert 'if level==AnimatedPlanetTestSlot556.sector {' in app
assert 'enterCampaignBoreas05(fromOrbit:true)' in app
assert 'guard level==1,sourceSector01==nil' in app
assert 'pc602-orbit-enter-boreas05-planet' in orbit
assert 'driver.hud.selectedUnlocked' in orbit
assert 'onEnterMission(AnimatedPlanetTestSlot556.sector)' in orbit
entry=app.split('private func enterCampaignBoreas05(fromOrbit:Bool=false) {',1)[1].split('private func returnFromBoreasTest05()',1)[0]
for gate in ('progress.selectedSector==AnimatedPlanetTestSlot556.sector',
             'progress.unlocked(AnimatedPlanetTestSlot556.sector)',
             'AnimatedPlanetTestSlot556.sourceAssetsVerified',
             'homeWorld291.hud.target==AnimatedPlanetTestSlot556.sector',
             'homeWorld291.setSuspended(true)',
             'enterBoreasTest05()'):
    assert gate in entry,gate
for forbidden in ("CampaignStore556.save(", "finishMission(",
                  "Sector01MissionSettlement568.commit(",
                  "Sector01Shop568.save(", "PC602OrbitSave61.store("):
    assert forbidden not in entry,forbidden
returnPath=app.split('private func returnFromBoreasTest05() {',1)[1].split('private func enterOrbitMission291(',1)[0]
assert 'if wasOrbit {' in returnPath
assert 'showingHomeWorld291=true' in returnPath
assert 'audio.enterOrbit602()' in returnPath
assert 'reopenAtlasAfterCarbonis=true' in returnPath
assert 'campaignSector05:boreasCampaignSector05' in app
assert 'returnToOrbit:returnHomeWorldAfterBoreas05' in app
assert 'PLANETA 05 · MISJA W OPRACOWANIU · BEZ ZMIAN POSTĘPU' in page
assert 'Button(returnToOrbit ? "WRÓĆ DO ORBITY" : "WRÓĆ DO ATLASU")' in page
assert 'campaign-boreas05-animated-planet' in page
assert 'static let missionCount = 26' in progress
print("PASS: BOREAS 05 is wired into selected/unlocked campaign and orbit")
print("PASS: existing W3 test, sector-01 combat, rewards, saves and locks untouched")
print("PASS: authenticated Boreas sector-05 morph test, 5s loop, 3-buffer GPU")
print("PASS: W3 atlas entry, no mission unlock, progress, reward or save changes")
print("PASS: original PC v609 GLB node translation and scale clips, 96/96 channels")

# Source-authenticated native mission 05 is independent of the W3 preview.
boreasSource=read("ASTEROIDYiOS/BoreasMission05Source.swift")
boreasScene=read("ASTEROIDYiOS/BoreasMission05Scene.swift")
boreasSettlement=read("ASTEROIDYiOS/BoreasMission05Settlement.swift")
combat=read("ASTEROIDYiOS/CarbonisCombat568.swift")
session=read("ASTEROIDYiOS/CarbonisSession568.swift")
hud=read("ASTEROIDYiOS/SourceCombatHUD331.swift")
for anchor in ('campaign.selectedSector == sector',
               'campaign.unlocked(sector)',
               'MissionWave568.generate(',
               'encounter.objective == .defend',
               'MissionStart261.prepare(',
               '!prepared.encounter.robots.isEmpty'):
    assert anchor in boreasSource,anchor
assert 'BoreasMission05Source.prepare(' in app
assert 'boreasMission05Prepared=prepared05' in app
assert 'if let prepared05=boreasMission05Prepared' in app
assert 'BoreasMission05Scene(prepared:prepared05' in app
assert 'MetalScene(input:input,combatSession05:session)' in boreasScene
assert 'SourceCombatTouchZones568(' in boreasScene
assert 'SourceCombatHUD331(' in boreasScene
assert 'HudPlasmaLayer600(' in boreasScene
assert 'BoreasMission05Settlement.commit(' in app
assert 'campaign.finishMission(report.sector)' in boreasSettlement
assert 'report.elapsedSeconds>=50' in boreasSettlement
assert 'report.sector==BoreasMission05Source.sector' in boreasSettlement
assert 'robots=prepared.encounter.robots' in combat
assert 'shooters.isEmpty && robots.isEmpty' in combat
assert 'case .defend: requiredTime=50' in combat
assert 'level=prepared.reset.level' in combat
assert 'level:level,type:fighter.core.type' in combat
assert 'sector=game.level' in session
assert 'SEKTOR 01 / 26' in hud
assert 'sourceShooterModels05[kind]' in renderer
assert 'sourceRockModels05[shape]' in renderer
assert 'CarbonisRockGeometry568.vertices(shape:shape)' in renderer
assert 'CarbonisRockGeometry568.shape(for:asteroid)' in renderer
assert 'makeSourceTriangles05(' in renderer
assert 'combatCraft05' in renderer
assert 'SourceKestrel603.load()' in renderer
assert 'SourceBastion606.load()' in renderer
assert 'Wybrany statek nie ma zweryfikowanego modelu PC609' in renderer
assert 'CarbonisShooterMesh71.typeOne()' in renderer
assert 'combatSession05.frame(at:now)' in renderer
assert 'if combatSession05 == nil && selected != activePlanetTestLevel' in renderer
assert 'WERSJA ROBOCZA' in boreasScene
# Critical: dedicated CARBONIS 01 view and its approved touch editor untouched.
assert 'struct Sector01Scene568' in read("ASTEROIDYiOS/Sector01Scene568.swift")
print("PASS: sector 05 uses one real battle state and authentic level-5 wave")
print("PASS: no mission-05 clear while RobotSnake actors remain unimplemented")
print("PASS: W3 diagnostic still never grants unlocks or source rewards")

#!/usr/bin/env python3
"""Genuine Windows v568 Intro41 -> C279 -> Sector01 mission integration.
Source oracle: Intro41.cs, GpuIntro41.cs, RendererW3Transitions319.cs,
GpuPlanetGltf463.cs, PlanetBiomes.cs, MusicAudio.cs; all verified in PC v568.
This is a source wiring regression, NOT a physical iPhone GPU screenshot.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def read(path):
    return (root/path).read_text(encoding="utf-8")
app=read("ASTEROIDYiOS/App.swift")
intro=read("ASTEROIDYiOS/MissionCinematic568.swift")
timeline=read("ASTEROIDYiOS/IntroOrbit41.swift")
renderer=read("ASTEROIDYiOS/MetalRenderer.swift")
planet=read("ASTEROIDYiOS/CarbonisIntroPlanet568.swift")
audio=read("ASTEROIDYiOS/OriginalAudioAV568.swift")
catalog=read("ASTEROIDYiOS/MissionCatalog568.swift")
assert 'static let duration: Float = 16' in timeline
assert 'static let approachStart: Float = 8.4' in timeline
assert 'static let arrivalTime: Float = 15.2' in timeline
assert 'static let beltStoneCount=820' in timeline
assert 'IntroOrbit41.frame(introTime41)' in renderer
assert 'IntroOrbit41.craftOrientationColumns(introTime41)' in renderer
assert 'IntroEnginePlasma491.vertexCount' in renderer
assert 'introTime41=min(IntroOrbit41.duration,' in renderer
assert 'input.missionIntroSector == 1' in renderer
assert 'carbonisIntroPlanet568=try CarbonisIntroPlanet568(' in renderer
assert 'carbonis.draw(encoder:encoder,mvp:vp,' in renderer
assert 'IntroOrbit41.planetRotationDegrees(\n                            level:1' in renderer
assert 'carbonisAtmosphereMesh568' in renderer
for source_sha in (
    "b35318d059b9c4f180d03f36e52a6c4eea1225a484e339d3f117e5df9d7634bd",
    "e542a65a0ddf0767d982b573da037becea7872cc8a6e0d5d1e1851cd90730bef",
    "8a9d5d2ad53d1c5bc8681f9ff17b83a3375fb7e16f58a3ed083a9157bcc58424",
):
    assert source_sha in planet
assert 'CarbonisMissionPlanet523' in planet
assert 'IntroOrbit41.introPlanetScale/sourceOuterRadius' in planet
assert 'sector01SourceCarbonisBake469' in planet
assert 'sector01CarbonisVertex568' in planet
assert 'sector01CarbonisFragment568' in planet
assert '803712' in planet and '7035' in planet
assert '236.0/255.0' in renderer and '78.0/255.0' in renderer
assert '25.0/255.0' in renderer
assert 'missionIntroInput568.missionIntroSector=sector' in app
assert 'beginMissionIntro568(sector:sector)' in app
# PC602 NEW GAME leads to H290; entering a fresh mission uses the
# orbital gate. The separately validated O09 LoadSlot61(Mode.Intro)
# legitimately invokes BeginLevelIntro AFTER preparing the real Wave.
checkpoint_loader=app.split('private func loadIntroCheckpoint61(')[1].split(
    'private func loadManualSave61(')[0]
assert app.count('beginMissionIntro568(sector:1)')==1
assert checkpoint_loader.index('Sector01PreparedWave568.prepare(') < checkpoint_loader.index(
    'beginMissionIntro568(sector:1)')
assert checkpoint_loader.index('SourceNewGame568.restoreOrbitProfile61(') < checkpoint_loader.index(
    'beginMissionIntro568(sector:1)')
assert 'inspectSourceSector(1)' in app
assert 'guard level==1,sourceSector01==nil' in app
assert 'SourceNewGame568.create(choice)' in app
assert 'audio.enterOrbit602()' in app
assert 'showingMissionIntro568=true' in app
assert 'if showingMissionIntro568 {' in app
assert app.index('MissionCinematic568(sector:sourceEntry.sector,') < app.index(
    'Sector01Scene568(entry:sourceEntry,')
assert 'sourceSector01Setup=retry' in app
assert 'beginMissionIntro568(sector:sourceEntry.sector)' in app
assert 'campaign.completed(sourceEntry.sector)' in app
assert 'audio.finishMissionIntro568(sector:sector)' in app
assert 'sourceSector01=nil' in app and 'sourceSector01Setup=nil' in app
for text in ('ROZPOCZĘCIE MISJI','PRZELOT ORBITALNY','CEL OPERACJI',
             'PRZELOT /','POMIŃ / ENTER','RZECZYWISTA SCENA 3D'):
    assert text in intro,text
assert 'MetalScene(input:input)' in intro
assert 'IntroOrbit41.duration' in intro
assert '.onKeyPress(.return)' in intro
assert 'pad.start(onConfirm:skip)' in intro
assert 'input.introProgress41>=0.6' in intro
assert 'guard !committed' in intro
assert 'if value>=IntroOrbit41.duration-0.00001 {finish()}' in intro
assert 'MissionCatalog568.title(for:sector)' in intro
assert '"CARBONIS / PBR"' in catalog
assert 'OriginalAudioCatalog568.resource("Intro43")' in audio
assert 'player.numberOfLoops=0' in audio
assert 'introMissionSector568=sector' in audio
assert 'audio.beginMissionIntro568(sector:sector)' in app
assert 'audio.beginMissionIntro568(sector:1)' not in app  # centralized call
assert 'introMissionSector568=nil' in audio
assert 'finishMissionIntro568(sector:Int)' in audio
assert 'enterMission(sector)' in audio
assert 'guard introMissionSector568 == nil, startupComplete,' in audio
assert 'intro43Player?.pause()' in audio
assert 'audio.returnToMenu()' in app
# Never route unavailable 25 sectors into a fake debug arena.
assert 'selectedSector == 1' in read("ASTEROIDYiOS/Sector01Entry568.swift")
# Cinematic has its own audio and no code that grants campaign rewards.
assert 'CampaignStore556.save(' not in intro
assert 'Sector01MissionSettlement568.commit(' not in intro
print('PASS Intro41 source scene, actual sector-01 C279, W3 overlay, 16s, skip,')
print('PASS Intro43 audio, pause, retry, no early simulation or fake unlock')
print('LIMIT: physical Apple GPU visual parity and FPS remain unmeasured')

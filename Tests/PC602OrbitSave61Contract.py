#!/usr/bin/env python3
"""Native iOS PC602 H290 save and source visual invariant check.
Source structure only; executable Swift source flight restore is exercised
separately on Linux and full Swift/Metal compiled by Xcode on Apple.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
read=lambda name:(root/"ASTEROIDYiOS"/name).read_text()
save=read("PC602OrbitSave61.swift")
flight=read("PC602HomeFlight291.swift")
session=read("PC602HomeWorldSession291.swift")
driver=read("PC602HomeWorldDriver291.swift")
app=read("App.swift")
page=read("PC602HomeWorldPage291.swift")
slots=read("PC602SaveSlots61View.swift")
w3=read("W3MainMenu568.swift")
source=read("SourceNewGame568.swift")
atmosphere=read("PC602HomeAtmosphere47.swift")
signal=read("PC602HomeMissionSignal58.swift")
lights=read("PC602HomeProjectileLights296.swift")
world=read("PC602HomeScene291.swift")
assert 'case unavailable,invalid,unsupported,io' in save
assert 'static let validMask=(1<<26)-1' in save
assert 'shipType==1' in save
assert 'mechanics.selectedShip==1' in save
assert 'PC602HomeFlight291.unlocked(target,mask:completedMask)' in save
assert 'UUID(uuidString:runID)' in save
assert '(position+forward+right).allSatisfy' in save
assert 'struct Envelope:Codable' in save
assert 'checksum==digest(env.payload)' in save or 'env.checksum==digest(env.payload)' in save
assert 'try bytes.write(to:url,options:.atomic)' in save
assert 'return support.appendingPathComponent("ASTEROIDY/saves61"' in save
assert 'slot.map{"slot\($0).json"} ?? "resume.json"' in save
assert '(0...2).contains(slot)' in save
assert 'static func clearResume()' in save
assert 'func restoreOrbit61(' in flight
assert 'flight.velocity' in flight
assert 'flight.flight.configuration=equipment.flightConfiguration' in flight
assert 'flight.camera=SphereCamera67(at:flight.position)' in flight
assert 'orbitSpeed=0' in flight
assert 'weapons=PC602HomeWeaponTest292(settings:weapon)' in session
assert 'steppedFrames=0' in session
assert 'paused=true' in session
assert 'SourceNewGame568.restoreOrbitProfile61(' in driver
assert 'saveOrbitSlot61(_ slot:Int)' in driver
assert 'loadOrbitSlot61(_ slot:Int?)' in driver
assert 'captureResume61()->Bool' in driver
assert 'if phase != .active {' in page
assert '_=driver.captureResume61()' in page
assert 'driver.setSuspended(phase != .active)' in page
assert 'return try?' not in save
assert 'func currentRunID' in source
assert 'archiveActive(defaults:defaults,directory:$0)' in source
assert '(!archiveExisting || archiveDirectory(nil).map' in source
assert 'PC602OrbitSave61.clearResume()' in app
assert 'continueOrbit:{' in app
assert '"KONTYNUUJ OSTATNI LOT"' in w3
assert 'accessibilityIdentifier("pc602-orbit-three-slot-saves61")' in page
assert 'accessibilityIdentifier("pc602-orbit-save61")' in page
assert 'accessibilityIdentifier("pc602-orbit-load61")' in page
assert r'ForEach(0..<3,id:\.self)' in slots
assert 'PC602SaveSlots61View(' in page
assert 'PC602SaveSlots61View(' in w3
assert 'archiveExisting:slot != nil' in driver
assert 'archiveExisting:Bool=true' in source
assert 'static func deleteSlot(_ slot:Int)->Bool' in save
assert 'static func slotFileExists(_ slot:Int)->Bool' in save
assert 'static var hasManualSave:Bool' in save
assert 'pending=action' in slots
assert 'confirmText(action)' in slots
assert '"USZKODZONY ZAPIS"' in slots
assert 'onLoad(selected)' in slots
assert 'onSave(selected)' in slots
assert 'PC602OrbitSave61.deleteSlot(selected)' in slots
assert 'let loadManualOrbit:(Int)->Bool' in w3
assert 'loadManualOrbit:{ slot in' in app
assert 'PC602OrbitSave61.hasManualSave' in w3
assert 'static func canContinueActive358(' in source
assert 'Sector01Shop568.validate(shop)' in source
assert 'state.valid,state.selectedShip==1' in source
assert 'SourceNewGame568.canContinueActive358()' in app
assert 'try homeWorld291.start(progress:CampaignStore556.load())' in app
assert 'SourceNewGame568.canContinueActive358()' in w3
assert 'if let rawVitals=defaults.object(forKey:vitalsKey)' in source
assert 'if let rawMechanics=defaults.object(forKey:mechanicsKey)' in source
assert 'rawVitals as? Data' in source
assert 'state.valid,state.selectedShip==1' in source
assert '"pc602-orbit-compact-26-atlas330"' in page
assert 'ForEach(0..<4,id:\.self)' in page
assert 'ForEach(0..<8,id:\.self)' in page
assert 'driver.hud.completedMask' in page
assert 'SourceCombatTouchZones568(' in page
assert 'SourceCombatTouchZones568(' in read("Sector01Scene568.swift")
assert 'HudPlanetariumMetal600(' not in world
assert 'SourcePlanetAtmosphere568.atmosphere(' in atmosphere
assert 'originalAtmosphere.draw(encoder:encoder,' in world
assert 'PC602HomeMissionSignal58' in signal
assert 'originalSignal.draw(encoder:encoder,' in world
assert 'PC602HomeProjectileLights296' in lights
assert 'projectileLights.draw(encoder:encoder,command:command,' in world
assert 'sourceLightEye:sunEye' in world
assert 'sourceKeyEye:sunEye' in world
assert world.count('onProjectiles?() ?? []')==1
assert 'if sector==1 {onEnterMission(sector)}' in page
assert 'guard level==1,sourceSector01==nil' in app
# The only authorized craft remains Vanguard; the PC602 original
# Campaign37/Modules97 ranks now come from the canonical H55 source state.
assert 'private static func vanguardEquipment291(' in driver
assert 'craft:.vanguard,' in driver
assert 'engineLevel:state.engine' in driver
assert 'thrusterRank:state.thruster' in driver
assert 'stabilizerLevel:state.stabilizer' in driver
assert 'let equipment=Self.vanguardEquipment291(state.mechanics)' in driver
assert 'state.adoptVanguardEquipment(equipment)' in driver
assert 'func enterOrbit602()' in read("OriginalAudioAV568.swift")
assert "planetarium.glb" in (root/".github/workflows/build-ios-pc602-h290-user-test-ipa-20261112.yml").read_text()
print("PASS O09 PC602: shared 3-slot UI, manual W3 load, overwrite/delete confirmation, corrupt-slot distinction and resume safety")

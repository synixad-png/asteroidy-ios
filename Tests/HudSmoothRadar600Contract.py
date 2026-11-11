#!/usr/bin/env python3
"""Source-contract for smooth 2D radar/text without rebuilding the game HUD.

The native Metal simulation owns the original PC radar calculation. SwiftUI
receives an immutable radar+pose snapshot every successful display frame; the
existing @Published text, counters and layout remain slower. This checks
dataflow and thread-safety markers; it is not a claim of iPad 60 FPS.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]/"ASTEROIDYiOS"
session=(root/"CarbonisSession568.swift").read_text()
canvas=(root/"SourceCombatHUD331.swift").read_text()
scene=(root/"Sector01Scene568.swift").read_text()
metal=(root/"Sector01CarbonisPreview568.swift").read_text()
plasma=(root/"HudPlasmaLayer600.swift").read_text()

# Reuse the original radar projector: same hemisphere culling, camera
# basis and original three object classes in HUD and render snapshots.
assert session.count("func contact(_ point:Vec2,_ kind:Int)->RadarContact?")==1
assert "static func radarContacts(for game:CarbonisCombat568)->[RadarContact]" in session
assert "radarContacts=Self.radarContacts(for:game)" in session
for s in ("Sphere67.normal(point)",
          "SphereVector3.dot(n,camera.focus) < -0.06",
          "SphereVector3.dot(n,camera.right)",
          "-SphereVector3.dot(n,camera.up)",
          "game.rocks.compactMap {contact($0.position,0)}",
          "game.shooters.compactMap {contact($0.core.position,1)}",
          "game.tokenPickups.compactMap {contact($0.position,2)}"):
    assert s in session,s
assert "struct RadarFrame600" in session
assert "let contacts:[HUD.RadarContact]" in session
assert "private var hudLiveRadar600=[HUD.RadarContact]()" in session
assert "hudLiveRadar600=hud.radarContacts" in session
assert "hudLiveRadar600=HUD.radarContacts(for:restarted)" in session
assert "func currentHudRadarFrame600()->RadarFrame600 {" in session
assert "return RadarFrame600(pose:hudLivePose600,contacts:hudLiveRadar600)" in session

frame=session[session.index("func frame(at now:TimeInterval)"):]
assert frame.index("let radarContacts600=HUD.radarContacts(for:game)") < frame.index("hudLayoutLock600.lock()")
assert frame.index("hudLivePose600=hudPose600") < frame.index("hudLiveRadar600=radarContacts600") < frame.index("hudLayoutLock600.unlock()")
assert frame.index("hudLiveRadar600=radarContacts600") < frame.index("if now-lastHUD > 0.10 {")
assert "self?.hud=snapshot" in frame
assert "DispatchQueue.main.async { [weak self] in" in frame
assert session.count("@Published private(set) var hud:HUD")==1
assert "@Published private(set) var hudLiveRadar600" not in session
assert "game.step(move:effectiveMove,aim:effectiveAim," in frame
assert "let dt=min(1.0/120.0,remaining)" in frame

# Timeline must be a genuine Canvas drawing dependency, not a discarded
# tick read outside Canvas (the root cause of stale rasterized text).
assert "TimelineView(.animation(minimumInterval:1.0/60.0,paused:!active))" in canvas
start=canvas.index("Canvas(opaque:false, rendersAsynchronously:false)")
inside=canvas[start:canvas.index(".frame(maxWidth:",start)]
assert "guard tick.date.timeIntervalSinceReferenceDate.isFinite else{return}" in inside
assert "let _ = tick.date" not in canvas
assert "let live:CarbonisSession568.RadarFrame600?=active ? liveRadar() : nil" in inside
assert "hud.motion=live?.pose ?? HudMotion600.Pose()" in inside
assert "Self.radar(radarContext,live?.contacts ?? hud.radarContacts)" in inside
assert "for contact in contacts {radarDot(c,center,contact)}" in canvas
assert "hud.radarContacts" not in inside.replace("live?.contacts ?? hud.radarContacts","")
# Preserve 46 original widget placements, radar ring and text rendering.
for marker in ("Self.top(topLeft,topRight,hud,layout600)",
               'id:"radar",baseX:2,baseY:516',
               'let cx:CGFloat=91,cy:CGFloat=612,r:CGFloat=69',
               "Self.gauge(",
               "Self.ability(",
               "Self.applyMotion(&context,pose:pose,widget:id)"):
    assert marker in canvas,marker

# The iOS scene takes the most recent radar+pose without modifying F6,
# screen hit areas, the native planetarium or the existing plasma clock.
assert "liveRadar:{ [weak session] in" in scene
assert "session?.currentHudRadarFrame600()" in scene
assert "contacts:[]" in scene
assert "SourceCombatHUD331(hud:session.hud" in scene
assert "HudPlasmaLayer600(" in scene
assert "HudPlanetariumHost600(" not in scene
assert ".allowsHitTesting(!showingHudEditor600)" in scene
assert "let time=liveTime().truncatingRemainder(dividingBy:3600)" in plasma
assert "view.preferredFramesPerSecond=gameSession == nil ? 30 : 60" in metal
assert "session.frame(at:physicsStart)" in metal
assert "session.frame(at:now)" in metal
assert "hudLiveRadar600" not in metal  # one owner
print("PASS HUD radar 60 Hz dataflow: one original projector, coherent lock, Canvas timeline, 10Hz counters, no gameplay/editor changes")

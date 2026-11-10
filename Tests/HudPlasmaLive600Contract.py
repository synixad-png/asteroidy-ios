#!/usr/bin/env python3
"""Source PC v600 RendererHudEnergy.cs + HudLayout.Begin parity gate.
This is a source-contract test, not an iPhone GPU visual test.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
read=lambda name:(root/"ASTEROIDYiOS"/name).read_text()
p=read("HudPlasmaLayer600.swift")
hud=read("SourceCombatHUD331.swift")
scene=read("Sector01Scene568.swift")
session=read("CarbonisSession568.swift")
physics=read("CarbonisCombat568.swift")
energy=read("HudEnergy600.swift")
assert "TimelineView(.animation(minimumInterval:1.0/60.0,paused:!active))" in p
assert "Canvas(opaque:false,rendersAsynchronously:false)" in p
assert "let pose=livePose()" in p
assert "let values:[Int?]=[gauge.hull,gauge.armor,gauge.shield]" in p
assert "let gauge=liveGauges()" in p
assert "func currentHudGauges600()->(" in session
assert "session?.currentHudGauges600()" in scene
assert "let maxima=[gauge.maxHull,gauge.maxArmor,100]" in p
assert "maxHull:session.hud.maxHull,maxArmor:session.hud.maxArmor" in scene
assert "Self.draw(bar,current:values[i],maximum:maxima[i]" in p
assert "HudEnergy600.ribbon(" in p and "for layer in 0..<5" in p
assert "for k in 0..<7" in p
assert "Double(k)*0.61803398875" in p
assert "let reach=2.5+5.3*turbulence" in p
assert "length-local<3.5" in p
assert "end-1.65" in p and "width:2.8,height:3.2" in p
assert "ink(90,255,205,150)" in p and "ink(90,255,237,166)" in p
assert "ink(90,228,255,187)" in p
# Exact 5/5/5 ARGB from PC source; never substitute uniform regular strips.
for pal in ("ink(18,255,32,23)","ink(46,255,41,24)","ink(128,231,20,11)",
            "ink(210,255,60,31)","ink(235,255,205,150)",
            "ink(20,255,93,6)","ink(53,255,124,17)","ink(140,238,103,5)",
            "ink(223,255,178,38)","ink(242,255,237,166)",
            "ink(18,37,255,50)","ink(49,55,252,56)","ink(129,16,205,47)",
            "ink(212,104,255,72)","ink(236,228,255,187)"):
    assert pal in p,pal
assert "Self.applyMotion(&context,pose:pose,widget:id)" in hud
for bad in ("Self.applyMotion(&bottomLeft","Self.applyMotion(&bottomRight",
            "Self.applyMotion(&topLeft","Self.applyMotion(&topRight"):
    assert bad not in hud
assert "HudEnergy600.ribbon(" not in hud
assert "Self.applyMotion(&bottom" not in p
for color in ("color(160,8,22,31)","color(69,90,123,134)",
              "color(55,74,101,111)"):
    assert color in hud
assert "HudPlasmaLayer600(" in scene
assert "active:session.hud.phase == .playing && !userPaused && !showingService" in scene
assert "session?.currentHudVisual600().pose" in scene
assert "session?.currentHudVisual600().seconds" in scene
assert "let time=liveTime().truncatingRemainder(dividingBy:3600)" in p
assert "hudLiveSeconds600=Double(game.elapsed)" in session
assert "seconds:now,hullPulse:" in session
assert "func currentHudVisual600()->(" in session
assert "maxHull=game.maxHull;maxArmor=game.maxArmor" in session
assert "maxHull:Int" in session and "maxArmor:Int" in session
assert "maxHull:Int=60,maxArmor:Int=25" in physics
assert "tarczaEnergy=max(0,Int(ceil(Double(game.tarcza145.energy))))" in session
for marker in ("[9.1,6.9,4.1,2.35,0.78]","[2.6,2.35,1.65,0.88,0.36]",
               "ceil(length/5)","style:Int,layer:Int","let cap=min(1,max(0.16",
               "coordinate*8.1-time*2.1+Double(style)*0.73"):
    assert marker in energy
print("PASS PC v600 HUD: 15 exact plasma tints, 5 turbulent ribbons, 7 licks, terminal, 60Hz isolated Canvas, real maxima, per-widget motion")

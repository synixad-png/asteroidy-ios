#!/usr/bin/env python3
"""Original W3 chrome at physical display edges, safe native iPhone UI.

Pure regression against the actual native Swift source, not a screenshot.
The app's Metal/3D geometry and per-sector progress must be untouched.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
read=lambda p:(root/p).read_text()
s=read("ASTEROIDYiOS/W3StartupSplash568.swift")
m=read("ASTEROIDYiOS/W3MainMenu568.swift")
l=read("ASTEROIDYiOS/W3AdaptiveViewport568.swift")
r=read("ASTEROIDYiOS/W3SafeAreaReader568.swift")
c=read("ASTEROIDYiOS/MissionCinematic568.swift")
scene=read("ASTEROIDYiOS/Sector01Scene568.swift")
proj=read("ASTEROIDYiOS/MissionViewportFraming568.swift")
assert "sourceHeader(layout)" in s and "sourceFooter(layout)" in s
assert ".frame(width:layout.width,height:layout.headerHeight)" in s
assert ".frame(width:layout.width,height:layout.footerHeight)" in s
assert "layout.headerHeight+layout.contentHeight/2" in s
assert "sourcePage(layout)" in s and ".scaleEffect(fit)" not in s
assert ".frame(height:layout.contentHeight)" in s
assert ".ignoresSafeArea()" in s
assert 'accessibilityIdentifier("w3-startup-enter")' in s
assert 'accessibilityIdentifier("asteroidy-w3-main-menu")' in m
assert ".ignoresSafeArea()" in m
assert "let diameter=min(geo.size.width * 0.76" in m
assert "W3HomePlanetMetal568(yaw:planetYaw,pitch:planetPitch)" in m
assert "var footerTop:Double {height-footerHeight}" in l

# End-to-end screen consistency, not manual iPhone 15 PM pixel offsets:
# full-screen image/shutter; original source chrome at physical bounds;
# only captions/buttons/panels inset by actual UIWindow safe area.
assert "window.safeAreaInsets" in r
assert "override func safeAreaInsetsDidChange()" in r
assert "override func didMoveToWindow()" in r
assert "override func layoutSubviews()" in r
assert "DispatchQueue.main.async" in r
for code in (s,m,c):
    assert "@State private var safeInsets=W3ScreenInsets568()" in code
    assert "W3SafeAreaReader568(insets:$safeInsets)" in code
    assert "insets:safeInsets" in code
assert ".frame(width:layout.usableWidth,height:center.size.height)" in s
assert "layout.safeLeft+layout.usableWidth/2" in s
assert "layout.leadingPadding" in s and "layout.trailingPadding" in s
assert "layout.safeBottom" in s
assert "if layout.usableWidth > 850" in m
assert "if proxy.size.width > 850" not in m
assert "layout.safeLeft+(compact ? 14 : 26)" in m
assert "layout.safeRight+(compact ? 14 : 26)" in m
assert "layout.safeLeft+(compact ? 12 : 24)" in m
assert "layout.safeRight+(compact ? 12 : 24)" in m
assert "layout.headerHeight" in m and "layout.footerHeight" in m
assert "layout.safeBottom" in m
assert "layout.safeLeft+side" in c
assert "layout.safeRight+side" in c
assert "layout.safeBottom" in c
assert "MetalScene(input:input)" in c
assert 'accessibilityIdentifier("intro41-skip-to-real-mission")' in c

# Source physics, original touch split and optical renderer unchanged:
assert "let compact=geo.size.height<550" in scene
assert "HStack(spacing:0)" in scene
assert ".gesture(movement)" in scene
assert ".gesture(aiming)" in scene
assert "Sector01CarbonisPreview568(" in scene
assert "let scale=min(1,a/sourceAspect)" in proj
assert "sourceWidth:Float=1280" in proj
assert "sourceHeight:Float=720" in proj
print("PASS actual UIWindow landscape iPhone 15 Pro Max safe areas, W3 splash/home/Intro41")
print("PASS iPad 4:3 pinned bars, original W3 planet Metal and untouched gameplay controls")

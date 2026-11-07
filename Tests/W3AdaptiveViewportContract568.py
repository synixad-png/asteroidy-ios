#!/usr/bin/env python3
"""Original W3 4:3 viewport source layout, independent of screenshot mockups."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
s=(root/"ASTEROIDYiOS/W3StartupSplash568.swift").read_text()
m=(root/"ASTEROIDYiOS/W3MainMenu568.swift").read_text()
l=(root/"ASTEROIDYiOS/W3AdaptiveViewport568.swift").read_text()
assert "sourceHeader(layout)" in s and "sourceFooter(layout)" in s
assert ".frame(width:layout.width,height:layout.headerHeight)" in s
assert ".frame(width:layout.width,height:layout.footerHeight)" in s
assert "layout.headerHeight+layout.contentHeight/2" in s
assert "sourcePage(layout)" in s and ".scaleEffect(fit)" not in s
assert ".frame(height:layout.contentHeight)" in s
assert "let layout=W3AdaptiveViewport568(" in s
assert ".ignoresSafeArea()" in s
assert "w3-startup-header-top" in s and "w3-startup-footer-bottom" in s
assert 'accessibilityIdentifier("w3-startup-enter")' in s
assert 'accessibilityIdentifier("asteroidy-w3-main-menu")' in m
assert ".ignoresSafeArea()" in m
assert m.count("compact ? 37 : 68")>=2
assert "let diameter=min(geo.size.width * 0.76" in m
assert "W3HomePlanetMetal568(yaw:planetYaw,pitch:planetPitch)" in m
assert "var headerHeight:Double {compact ? 52 : 74}" in l
assert "var footerHeight:Double {compact ? 37 : 68}" in l
assert "var footerTop:Double {height-footerHeight}" in l
print("PASS W3 4:3 iPad header/footer pinned to real screen edges; source GPU globe unchanged")

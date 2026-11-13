#!/usr/bin/env python3
"""Settings changed in a pause menu must reach the renderer that is running.

Regression guard for three options that were read once and then ignored:
1. CARBONIS 01: GLOW #2 and PLANETY #55-#57 (SourcePlanetGraphicsSettings568).
2. H290 orbit: PLANETY #45 lava brightness (SourceLavaLightSettings287).
3. H290 orbit: STEROWANIE key assignments (SourceControls586.Profile).
Renderers read one integer revision per frame and decode only after a save;
controls are re-read on a UI event, never in the flight frame loop.
"""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src = lambda name: (root / "ASTEROIDYiOS" / name).read_text()

carbonis = src("Sector01CarbonisPreview568.swift")
lava = src("SourceLavaLightSettings287.swift")
orbit = src("PC602HomeScene291.swift")
driver = src("PC602HomeWorldDriver291.swift")
page = src("PC602HomeWorldPage291.swift")
session = src("PC602HomeWorldSession291.swift")

# 1. CARBONIS planet options are re-read in the live mission renderer.
assert "private let planetFx568" not in carbonis, "CARBONIS planet options frozen at mission start"
assert "private var planetFx568=SourcePlanetGraphicsSettings568.load()" in carbonis
draw = carbonis.index("func draw(in view:MTKView)")
reload = carbonis.index("if planetFxRevision != planetFxRevision568 {", draw)
assert "forKey:SourcePlanetGraphicsSettings568.revisionKey)" in carbonis[draw:reload]
assert "planetFx568=SourcePlanetGraphicsSettings568.load()" in carbonis[reload:reload + 200]
first_use = carbonis.index("glow:planetFx568.glowEnabled", draw)
assert reload < first_use, "planet options must be refreshed before the sky uses GLOW"
# Outside the phone-only 0.25 s block, so iPhone and iPad both refresh.
assert "adaptivePhoneCombat568" not in carbonis[reload - 600:reload]

# 2. Lava brightness has a save revision, and the orbit renderer follows it.
assert 'static let revisionKey = key + ".revision"' in lava
save = lava[lava.index("func save("):lava.index("static func load(")]
assert "defaults.set(bytes,forKey:Self.key)" in save
assert "forKey:Self.revisionKey) &+ 1" in save, "save must bump the lava revision"
assert "private var lava287=SourceLavaLightSettings287.load()" in orbit
assert "            let lava287=" not in orbit, "orbit lava frozen at orbit start"
lava_reload = orbit.index("if lavaRevision != lavaRevision287 {")
assert "forKey:SourceLavaLightSettings287.revisionKey)" in orbit[lava_reload - 200:lava_reload]
assert lava_reload < orbit.index("glowPower:lava287.intensity"), "lava refreshed before use"

# 3. Orbit flight adopts changed key assignments when settings close.
refresh = driver[driver.index("func refreshControls586()"):driver.index("func exitH55()")]
assert "SourceControls586.Profile.load()" in refresh
assert "session?.adoptControls(controls)" in refresh
assert "withLock" in refresh
hook = page.index(".onChange(of:showingOrbitSettings291)")
assert "if !open {driver.refreshControls586()}" in page[hook:hook + 120]
# The simulation still never reads UserDefaults itself.
assert "Profile.load()" not in session, "orbit session must not read settings per frame"

print("PASS live settings: CARBONIS glow/planet, orbit lava and orbit key assignments")

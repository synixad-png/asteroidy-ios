#!/usr/bin/env python3
"""Protect animated original Boreas GLB in BOTH source scenes.

Source: real Windows/src/GpuIntro41.cs:490,492 invokes
DrawPlanetSolid() with weatherTime65=IntroTime. The implementation in
Windows/src/GpuPlanet.cs:149 and GpuPlanetGltf463.cs:70-73 uses
DrawReplacedPlanet463(time,true) to sample glTF animation. The first
iOS orbital preview accidentally retained the static first morph frame.
This test does not substitute for a full Xcode or iPhone GPU test.
"""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
s=(r/'ASTEROIDYiOS/MetalRenderer.swift').read_text()
m=(r/'ASTEROIDYiOS/BoreasMorphRenderer556.swift').read_text()
slots=(r/'ASTEROIDYiOS/MorphBufferSlots.swift').read_text()
app=(r/'ASTEROIDYiOS/App.swift').read_text()
def ck(ok,msg):
    if not ok:raise AssertionError(msg)

assert s.count('private func uploadBoreasMorphIfNeeded(seconds: Double)') == 1
method=s.split('private func uploadBoreasMorphIfNeeded(seconds: Double)',1)[1].split(
    'private static func introView41(',1)[0]
for token in (
    'guard seconds.isFinite, seconds >= 0 else { return }',
    'lastPlanetMorphUpload < 0',
    'seconds < lastPlanetMorphUpload',
    'seconds - lastPlanetMorphUpload >= 1.0/30.0',
    'planetBufferSlots.reserveWrite()',
    'planetAnimator.updateVertices(seconds: seconds, into: &planetMorphScratch)',
    'let range = planetAnimator.dynamicVertexRange',
    'let startByte = range.lowerBound * strideBytes',
    'let dynamicBytes = range.count * strideBytes',
    'guard startByte <= target.length &&',
    'dynamicBytes <= target.length - startByte',
    'planetMorphScratch.withUnsafeBytes { bytes in',
    'memcpy(target.contents().advanced(by:startByte),',
    'planetBufferSlots.cancelWrite(slot)',
    'planetBufferSlots.publish(slot)',
    'lastPlanetMorphUpload = seconds',
):
    ck(token in method,'Original safe triple-buffered morph upload regressed: '+token)
ck(method.index('planetBufferSlots.reserveWrite()') <
   method.index('planetAnimator.updateVertices(seconds: seconds') <
   method.index('planetBufferSlots.publish(slot)') <
   method.index('lastPlanetMorphUpload = seconds'),
   'Buffer must be reserved before CPU work, published after successful update')

start=s.index('if input.introPreview41 {\n            // The source Windows GpuIntro41.CinematicIntro41')
stop=s.index('\n        if input.planetPreview {\n            // Original GpuIntro41.DrawDeepSpace55', start)
cinematic=s[start:stop]
ck('uploadBoreasMorphIfNeeded(seconds:Double(introTime41))' in cinematic,
   'Real source intro clock is not driving GLB morph animation')
ck(cinematic.index('uploadBoreasMorphIfNeeded(seconds:Double(introTime41))') <
   cinematic.index('let slot=planetBufferSlots.retainCurrent()') <
   cinematic.index('drawMesh(mesh,planetModel)'),
   'Cinematic must update morph BEFORE retaining/drawing GPU buffer')

sphere=s[stop:]
ck('uploadBoreasMorphIfNeeded(seconds:planetAnimationTime)' in sphere,
   'Existing spherical combat morph was disconnected')
ck(sphere.index('uploadBoreasMorphIfNeeded(seconds:planetAnimationTime)') <
   sphere.index('let slot = planetBufferSlots.retainCurrent()'),
   'Combat morph must update before retaining GPU buffer')

ck('if input.introPreview41 != wasIntroPreview41 {' in s and
   'lastPlanetMorphUpload = -1' in s and
   'if input.introPreview41 {introTime41=0}' in s,
   'Switching Intro <-> sphere must restart morph sampling')
ck('truncatingRemainder(dividingBy:IntroOrbit41.duration)' in s,
   'Cinematic 16-second original timeline is no longer looping')
ck('BoreasMorphBinding556' in s and 'planetAnimator = try BoreasMorphRenderer556(' in s,
   'Original Boreas GLB node-0 morph binding missing')
ck('func updateVertices(seconds: Double, into result: inout [AssetMesh.Vertex])' in m,
   'Original source-morph calculation was unexpectedly replaced')
ck('let range =' in method and 'staticVertexCount' in m,
   'Original static mesh must remain immutable on morph upload')
ck('func reserveWrite() -> Int?' in slots and
   'func retainCurrent() -> Int' in slots and
   'func release(_ slot: Int)' in slots,
   'GPU read/write separation regressed')
ck('@Published var introPreview41 =\n        ProcessInfo.processInfo.environment["ASTEROIDY_SHIP367_VERIFY"] != "1"' in app and
   '@Published var planetPreview = true' in app,
   'Original cinematic and Boreas test switch should remain reachable')
print('PASS: original GpuIntro41 weatherTime65 drives Boreas glTF morph')
print('      in cinematic, existing combat morph retained, 30 Hz ring buffer')
print('      mode switch and 16-second loop retrigger actual GPU morph upload')
print('LIMIT: static source test; not native Apple GPU compilation/rendering')

#!/usr/bin/env python3
"""Static wiring guard for original 16-second Windows IntroScene41 scene.

Checks that the actual default iOS app enters a distinct source-derived
3D camera with original ship, Boreas asset, 1,500 stars and the 820
C# legacy belt coordinates; cannot prove shader output, rock
geometry parity, or completion of any mission.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
intro=(root/'ASTEROIDYiOS/IntroOrbit41.swift').read_text()
metal=(root/'ASTEROIDYiOS/MetalRenderer.swift').read_text()
rockmesh=(root/'ASTEROIDYiOS/IntroRockGeometry41.swift').read_text()
app=(root/'ASTEROIDYiOS/App.swift').read_text()
project=(root/'project.yml').read_text()
def ck(ok,msg):
    if not ok:raise AssertionError(msg)

for token in (
    'static let duration: Float = 16',
    'static let approachStart: Float = 8.4',
    'static let arrivalTime: Float = 15.2',
    'static let planetCenter = V(x:-38,y:4,z:-56)',
    'static let arrivalRadius: Float = 34',
    'static func orbitalShip(',
    'static func ship(',
    'static func forward(',
    'static func camera(',
    'static func craftOrientationColumns(',
    'static func frame(',
    'static let beltStoneCount=820',
    'DotNetRandom(seed:4109)',
    '2.399963',
    'radius:Float=52+Float(rng.nextDouble())*16',
    'size:Float=0.22+Float(randomSize*randomSize*randomSize)*1.75',
    'static let corridorSamples:[(eye:V,line:V)] = (0...80).map { sample in',
    'static func visible(',
    'static func planetRotationDegrees(',
    'Float(level)*29+time*2.2',
):
    ck(token in intro,'IntroScene41/OrbitWorld51 source changed: '+token)

for token in (
    'static func stone(_ direction:V,seed:Float)->V',
    'radius+=0.065*sin(p.x*4+p.y*3+p.z*5+seed)',
    'radius-=0.095*exp(-q*q/(0.04+f*0.014))',
    'static func stoneNormal(_ direction:V,seed:Float)->V',
    'let right=V.cross(p,axis).normalized',
    'let forward=V.cross(right,p).normalized',
    'let shade:Float=0.70+0.08*sin(seed+d.x*13+d.z*11)',
    'red *= 1.3;green *= 1.13;blue *= 0.9',
    'let depth=rock.size>1.15 ? 3 : 2',
    'subdivide(ab,bc,ca,size:size,seed:seed,depth:depth-1',
):
    ck(token in rockmesh,'Source GpuIntro41.IntroStone mesh mismatch: '+token)

# Cinematic sky must reuse genuine GpuIntro41 source shaders
# with the ORIGINAL IntroScene41.View right/up/forward basis.
ck('static func skyCamera(time:Float)->SphereCamera67' in intro and
   'camera.focus=basis.back * -1' in intro and
   'camera.right=basis.right' in intro and
   'camera.up=basis.up' in intro,
   'IntroSky projection basis differs from IntroScene41 camera')
intro_metal=metal.split(
    '        if input.introPreview41 {\n            // The source Windows GpuIntro41.CinematicIntro41',1)[1].split(
    '\n        if input.planetPreview {\n            // Original GpuIntro41.DrawDeepSpace55',1)[0]
# Prevent interpreting the still-intact Boreas diagnostic sky as proof
# that the separate cinematic actually displays that sky.
for token in (
    'let c=IntroOrbit41.skyCamera(time:introTime41)',
    'let sourceCloudTexture=ensureCloudTextures55(camera:c)',
    'for style in 0..<DeepSkyPlanets55.count',
    'style:style,time:introTime41,',
    'if let blackProjection=BlackHoleSky55.project(',
    'camera:c,time:introTime41)',
    'if let sun=SphereSolarOverlay556.project(',
    'camera:c)',
    'encoder.setRenderPipelineState(nebulaOverlayPipeline)',
    'encoder.setRenderPipelineState(blackHolePipeline)',
    'encoder.setRenderPipelineState(skyPointPipeline)',
    'encoder.setRenderPipelineState(solarOverlayPipeline)',
):
    ck(token in intro_metal,'Missing original IntroSky effect: '+token)
painter_order=(
    'vertexCount:24*6',
    'for style in 0..<DeepSkyPlanets55.count',
    'if let blackProjection=BlackHoleSky55.project(',
    'vertexStart:24*6,vertexCount:12*6',
    'encoder.setRenderPipelineState(skyPointPipeline)',
    'if let sun=SphereSolarOverlay556.project(',
)
indices=[intro_metal.index(token) for token in painter_order]
ck(indices==sorted(indices) and len(set(indices))==len(indices),
   'IntroSky must draw far clouds, planets, black hole, near clouds, stars and rays in source order')

ck('for (eye,line) in corridorSamples {' in intro,
   'Original source 81 eye-to-ship segments must be reused in all 820 rock tests')
ck(intro.index('let point=origin+planetCenter-eye') <
   intro.index('let projection=clamped('),
   'Flight corridor position must use source subtraction and projection')

ck('static let boreasSourceLevel = 5' in intro and
   'level:IntroOrbit41.boreasSourceLevel,' in metal,
   'Real PlanetAssetBytes463 loads Boreas at original game.Level=5, not 1')
# The new fully playable sector-01 cinematic uses real CARBONIS C279.
# Level=1 is correct ONLY for the source C279 branch, while the old
# Boreas-GLB diagnostic MUST remain level 5 with animated morph frames.
# The former global negative check incorrectly rejected this valid branch.
planetBlock=intro_metal.split('if missionCarbonis {',1)[1].split(
    '            // Original IntroScene41.CraftOrientation local axes.',1)[0]
carbonisBranch,boreasBranch=planetBlock.split('            } else {',1)
ck('level:1,time:introTime41' in carbonisBranch and
   'carbonis.draw(encoder:encoder,mvp:vp,' in carbonisBranch,
   'Mission 01 must render the original C279 with source planet level 1')
ck('level:1,time:introTime41' not in boreasBranch and
   'level:IntroOrbit41.boreasSourceLevel,' in boreasBranch and
   'uploadBoreasMorphIfNeeded(seconds:Double(introTime41))' in boreasBranch,
   'Boreas diagnostic must retain level 5 and animated glTF source')
ck('@Published var introPreview41 =\n        ProcessInfo.processInfo.environment["ASTEROIDY_SHIP367_VERIFY"] != "1"' in app,
   'The new source cinematic must be initially visible, not old training arena')
ck('@Published var planetPreview = true' in app,
   'Existing source Boreas sector still enabled as alternate scene')
ck('input.introPreview41.toggle()' in app and
   'Button(input.introPreview41 ? "BOREAS 3D" : "PRZELOT 3D")' in app,
   'Cinematic/Boreas scene switch no longer reachable')
ck('SCENA ROBOCZA • NIE JEST PEŁNĄ MISJĄ' in app,
   'Must label the unfinished intro faithfully')
ck('introProgress41' in app and 'input?.introProgress41 = introElapsed41' in metal,
   'Real 16-second source timeline is not reflected in preview')
ck('if input.introPreview41 {' in metal and
   'cameraFrame=Self.introView41(introTime41)' in metal,
   'Source IntroScene41 camera not connected to actual Metal rendering')
ck('Self.perspective(' in metal and
   'aspect,spherical:input.planetPreview || input.introPreview41' in metal,
   'Cinematic must share original intro frustum, not 36-degree flat arena')
ck('for (index,rock) in IntroOrbit41.belt.enumerated()' in metal and
   'where IntroOrbit41.visible(rock,time:introTime41,in:frame)' in metal,
   '820 source belt rock coordinates are not drawn with frustum culling')
ck('IntroOrbit41.beltRotationDegrees(time:introTime41)' in metal and
   'let beltTransform = Self.translation(' in metal and
   'let translation=beltTransform *' in metal,
   'Original 0.2-degree/second source belt transform is missing')
ck('IntroRockGeometry41.geometry(rock)' in metal and
   'introRockMaxCached41 = 256' in metal and
   'if builtThisFrame==0' in metal and
   'drawMesh(original,translation)' in metal,
   'Actual original seed-specific asteroid geometry/lazy cache not wired')
ck('drawMesh(mesh,planetModel)' in metal and
   'IntroOrbit41.introPlanetScale' in metal,
   'Real original planet asset absent from cinematic')
ck('drawMesh(shipMesh,craft)' in metal and
   'IntroOrbit41.craftOrientationColumns(introTime41)' in metal,
   'Actual Vanguard and source orientation absent')
ck('vertexCount:sphereSkyMesh.count)' in metal and
   'encoder.setRenderPipelineState(skyPointPipeline)' in metal,
   'Original deep-space stars missing')
ck('if input.introPreview41 {\n                // Source cinematic must not run either test simulation.' in metal,
   'Cinematic is incorrectly advancing training gameplay')
ck('return\n        }\n        if input.planetPreview {' in metal,
   'Cinematic draw is not separate from diagnostic planet mode')
ck("TARGETED_DEVICE_FAMILY: '1,2'" in project,
   'Source project no longer supports both iPhone and iPad')
print('PASS: original source IntroScene41 16-second camera/world/ship/belt')
print('      connected to real Metal, visual preview isolated, iPhone+iPad')
print('LIMITATIONS: only not-yet-generated stones use octahedron fallback;')
print('             NewHome290 terrain-placement and craft scale need parity audit')
print('             and runtime Apple GPU/iPad imagery NOT verified')

#!/usr/bin/env python3
"""Guard EXACT cinematic Vanguard dimensions from actual v568 runtime mesh.

Evidence:
  Shared/assets/vanguard431/vanguard431.mesh.gz (4311, 194427 vertices)
  Shared/assets/vanguard431/BakeInfo.json (3.265866381849069, .18199390172958374)
  Shared/assets/vanguard431/Vanguard_551_SOURCE.glb (source GLB)
  Windows/src/GpuIntro41.cs:493 and Windows/src/ShipMesh.cs:92
Do not use the stale Tools/bake_vanguard431.py 2.88 bake constants.
No demo or fabricated model is allowed to replace the user's source GLB.
"""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
model=(r/'ASTEROIDYiOS/IntroVanguard431.swift').read_text()
metal=(r/'ASTEROIDYiOS/MetalRenderer.swift').read_text()
export=(r/'Tools/export_vanguard.py').read_text()
orbital=(r/'ASTEROIDYiOS/IntroOrbit41.swift').read_text()
def check(ok,msg):
    if not ok:raise AssertionError(msg)
for token in (
    'static let pcBakedScale: Float = 3.265866381849069',
    'static let pcBakedYCenter: Float = 0.18199390172958374',
    'static let iosExportScale: Float = 0.32',
    'static let iosExportYCenter: Float = 0.18',
    'pcBakedScale / iosExportScale',
    '(iosExportYCenter-pcBakedYCenter)*pcBakedScale',
    'sourceUnitsPerPackedUnit*IntroOrbit41.radiusNormalization',
    'sourceLocalDorsalCorrection*IntroOrbit41.radiusNormalization',
    'static func sourceLocalPosition(_ packed:V)->V',
    'static func sourceLocalFromGLB(_ glb:V)->V',
):
    check(token in model,'Actual Vanguard v4311 mesh mapping regressed: '+token)
check("'Shared/assets/vanguard431/Vanguard_551_SOURCE.glb'" in export,
      'iOS Vanguard must still come from the user original GLB')
check("verts[:, 2], verts[:, 1]-0.18" in export and
      "axis swap" not in model,
      'Port source transform changed; re-audit original runtime asset')
check('static let planetCenter = V(x:-38,y:4,z:-56)' in orbital,
      'Vanguard positional reference must remain original IntroScene41')
start=metal.index('if input.introPreview41 {\n            // The source Windows GpuIntro41.CinematicIntro41')
end=metal.index('\n        if input.planetPreview {\n            // Original GpuIntro41.DrawDeepSpace55',start)
intro=metal[start:end]
check('let a=IntroOrbit41.craftOrientationColumns(introTime41)' in intro,
      'Original fighter local axes from IntroScene41 were removed')
check('let craft=Self.translation(ship.x,ship.y,ship.z) *' in intro,
      'Original craft centre must move with original ship flight')
check('Self.translation(0,0,\n                    IntroVanguard431.normalizedDorsalCorrection) *' in intro and
      'Self.scale(IntroVanguard431.normalizedShipModelScale)' in intro,
      'The converted GLB must receive exact v4311 original source 3D bounds')
check(intro.index('orientation * Self.rotateYDegrees(sin(introTime41*0.8)*7) *') <
      intro.index('Self.translation(0,0,\n                    IntroVanguard431.normalizedDorsalCorrection) *') <
      intro.index('Self.scale(IntroVanguard431.normalizedShipModelScale)'),
      'Original craft yaw must remain outside local GLB scale/centering')
check('SphereSurfaceStamp556.sourceCraftRadius*inv' not in intro,
      'Original cinematic must NOT use combat-collision radius')
check('drawMesh(shipMesh,craft)' in intro,
      'Cinematic must still render the original Vanguard AS3D asset')
check('if input.planetPreview {' in metal and
      'let shipModel=Self.translation(ship.x,ship.y,0)' in metal,
      'Legacy sandbox renderer / gameplay ship must be preserved')
print('PASS: actual PC v4311 source baked Vanguard dimensions, source axes')
print('      original cinematic yaw and standalone iOS combat regression guard')
print('LIMITATION: actual GLB baseColor texture/UV and GL source lights')
print('            have not yet been ported, native Apple GPU unverified')

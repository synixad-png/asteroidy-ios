# ASTEROIDY iOS — PC v586 source audit / 2026-11-10

## Baza
Reference archive: Asteroidy_v586_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip
SHA256: 8fad7f8444321ff91b77bd0dc7bdf50491cad65870df794151ffc586e27c06ff
1855 ZIP entries, CRC PASS. Preserve current iOS Swift/Metal branch.

## Original source modules
PickupGlbModels.cs: source model map (Tarcza145/Shield, Boost71, Energy, Bomb), common source GLB loader and reuse, procedural fallback.
CombatSupplyDrops.cs: single seeded roll, one supply max per killed actor; Bomb probabilities 0.065/0.025/0.008 asteroid sizes 3/2/1 and 0.055 enemy; Energy 0.17/0.09/0.025 asteroid and 0.155 enemy. Lifetime 26 s; max 96 active; IonAmmo +40 up to 300; Bombs +1 up to 3.
GpuSphere67.cs / Menu139.cs: original model brightness 180% (0–400); independent visual scales Shield 60, Boost/Energy/Bomb 78 (30–150); Token 78 (40–150).
Controls.cs: 60 real actions, PC v586 scrolls 65 rows (60 actions plus 5 device settings). Action 7 uses Bomb R, action 21 Shield V, action 35 Boost F.

## Original GLB facts
Each file is GLB 2.0 with one mesh, textured opaque material, original embedded JPEG and POSITION/NORMAL/TEXCOORD_0. All four contain 0 animation clips.
- shield.glb 478320 B / SHA256 531f1d49ea9782a2c40ce6870cd308d067461cc5f80cfaefc659f3db4ffe5a62
- boost.glb 502996 B / SHA256 6f7a083b493b029f4907988b55dbf9cdc49c7d5d187e023fa20521319b494362
- energy.glb 506076 B / SHA256 df9c3a85ef45d55d3ce08d9d82ec9ec1f0ec1b8c2cdf06fb35550eb96aa3aca1
- bomb.glb 483424 B / SHA256 e8787ce4b11c8b44b6b710a93419b0c8cc263cafe27c35e580b0c4cb8bffaaee

## Actual iOS integration boundaries
CarbonisCombat568.swift has real ionAmmo, bombs, useBomb(), fireSourceWeapon(), but only TokenPickup / tokenPickups / stepTokenPickups for mission collectible entities.
CarbonisSession568.swift and Sector01Scene568.swift already route a real touch button into useBomb(); do NOT clone the ammo or bomb subsystem.
Sector01CarbonisPreview568.swift draws tokenVertices for coins using its real Metal pass; no original shield/boost/energy/bomb instance renderer yet. iPhone and iPad have distinct validated FX preparation paths that must remain intact.
CarbonisVisualSettingsPanel568.swift has gameplay category 3 with rock/enemy scale, not PC586 pickup brightness and five independent pickup sizes yet.
H55 GLTFKit2 model loading is a different scene/camera domain; avoid per-pickup GLB loader or second Metal renderer. SourcePickupModels586.swift registers exact identities and safe absent-GLB fallback; not gameplay integration.
Current iOS input supports touch walk/aim/shoot, pause, bomb and H55 walk/jump/interact; no verified 60-action remap backend for keyboard/gamepad.

## Dependency and honest completion
Stage 2 cannot be finished merely by copying GLBs: existing active CARBONIS gameplay lacks four Supply pickup types and draw instances. Stage 2 requires the canonical runtime item entities and their shared GPU resources; this depends on stages 4/5 without justifying duplicate mechanics.
The ChatGPT Library reference archive is NOT automatically part of GitHub or any IPA. Binary resource delivery into the real iOS target remains necessary.
No v587-v589 HUD changes. Do not bump version or publish IPA merely for adding a source catalog.

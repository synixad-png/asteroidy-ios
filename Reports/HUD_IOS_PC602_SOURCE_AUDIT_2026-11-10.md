# ASTEROIDY iOS — HUD source parity audit against PC v602
Date: 2026-11-10

Authoritative user-supplied source: `Asteroidy_v602_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`. Retain the original animation tracks, shader/gauge formulas, and F6 layout. Do not invent replacement models, effects or physics.

## Source fingerprints
- Windows/src/HudGlbAssets.cs SHA256 `c63378f717a7d66f5c4b6e93fc419dd72d57d654b1dd8e09aee0cba4586a5432`
- Windows/src/HudCapsuleScene.cs SHA256 `44b10fedec29c83029c6e9c81950423ffd3153f3b78704c6dc13e92dd117bd3a`
- Windows/src/HudLayout.cs SHA256 `4c20dca71c935f7767ed83fdd0df6d2e746e69f64f32368cb2bda36c4a901586`
- Windows/src/HudMotion.cs SHA256 `dbc075df29f2288e29766a6aec4f9aec7bd4d081171761de393c4c9e1db041fa`
- Windows/src/RendererHudEnergy.cs SHA256 `784f42b0f7eece113a17165cde0c427434e977ea83534b207a74bfd2bae5ee13`
- Windows/src/RendererW3Combat331.cs SHA256 `cf45081b39e61602bfad1909f96c71ff4c9f1328e7bc9c12835b57fa070403e1`
- Shared/assets/hud/planetarium.glb: 3,228,900 bytes; SHA256 `71ca9ff24e044a831a5c7197e343594dd1fd801284af6231870570b35ad43860`
- Original GLB topology: 141 nodes, 20 meshes, 159 channels in the sole `HUD_PLANETARIUM_PREMIUM_48S_LOOP` animation, and 72 authored water-bubble translation channels. No replacement sphere/textures.

## Confirmed source mappings and fixes
1. `RendererW3Combat331.DrawCombatHud331` uses the monotonic **renderClock** for `Motion.Update` at frame cadence, and `g.Time` only for energy/plasma and corona. In iOS, `SourceCombatHUD331` now samples `CarbonisSession568.currentHudVisual600().pose` at display cadence. Semantic HUD values remain 10Hz snapshots; no ship physics adjustments.
2. `HudGlbAssets.DrawHudGlb` animates icons and the 159-track planetarium from **renderClock**. `Sector01CarbonisPreview568` now feeds icon springs `ProcessInfo.processInfo.systemUptime-started`, not `session.game.elapsed`. The original SceneKit GLTFKit2 animation is left intact; no fabricated keyframes.
3. `HudCapsuleController.Advance` uses renderer time. `CarbonisSession568` now advances the three resource smoothing channels with `seconds:now`. Source clip's original 72 bubble nodes and three hit flashes are matched by authored names.
4. `RendererHudEnergy.DrawEnergyRibbon` renders each ribbon as two source-authored triangles per segment on the OpenGL GPU path. `HudPlasmaLayer600` now uses those exact triangle indices, five per gauge, and seven source drift tongues. Animated geometry uses `game.elapsed` (`Game.Time`), frozen by pause. The 30FPS workaround was REVERTED.
5. `HudGlbAssets.DrawHudGlb` rotates the model Y/X/Z and scales it using `0.44 * widget.Width * widget.Scale / PlanetModelRadius463`; the camera itself is not rotated. Measured source GLB opaque geometry with the `H55Renderer.MeasurePlanetBounds463` algorithm: centre=(2.74528861,0,0), radius=5.112107576242468. The SceneKit wrapper preserves the *whole* original glTF root and attached 159-channel animation player.
6. `RendererHudLayout.HudToggle/HudCancel` freezes physics on F6, edits source F6 widget positions/scales, commits/reverts and resumes. iOS overlay edits the *real paused HUD* with touch drag and pinch, supports all 46 widgets, clamps to actual PC bounds, saves JSON or restores previous layout. Both left and right combat touch zones are gated during editing; no alternate physics.
7. `RendererHudEnergy.DrawEnergyGauge` reads the current Game.Hull78, Armor78 and TarczaEnergy145 levels each GPU frame. `CarbonisSession568.currentHudGauges600()` now provides a tiny locked immutable five-number snapshot on each Metal frame to `HudPlasmaLayer600`; only numeric HUD labels and radar remain @Published at 10 Hz. The true resource mechanics are untouched. Legacy tests `HudPlasmaLive600Contract.py` and `HudV600IntegrationContract.py` were brought into line with this exact v602 rendering contract.
8. Source `HudMotion.Update` returns Still when not playing. The GLB animation may continue at render clock during F6 while the additive combat tilt is zero. The 46-widget default JSON positions (including planetarium x=64.7882 y=553.0863 scale=1.4702 pitch=-20) were not altered.

## Release/verification contract
- CI source/Swift checks include `Tests/HudV602TouchRuntimeContract.py`, the HudV600 suite, original HudPlanetariumCorona source-time test, native Swift unit tests, and Xcode arm64 build. The release workflow uses cancel-in-progress concurrency for newer commits in the same branch; old workflows predating that gate can still be queued.
- The original binary planetarium model is NOT silently replaced or approximated. The GitHub repository currently lacks the full PC v602 binary asset; a release IPA assembled from the compiled GitHub artifact must have the SHA-verified `planetarium.glb` inserted from the supplied v602 source ZIP.
- Verify the final IPA CRC, original planetarium SHA and byte identity of all existing compiled app resources and executable. Installing an **unsigned** IPA on a device requires signing.
- Native iOS device (Metal+SceneKit) interactive visual and performance tests remain **not performed** unless explicitly proven. CI/static checks cannot establish 100% visual parity or a measured FPS improvement.
- Architectural difference remains: PC uses OpenGL rendering into the same HUD GPU path; iOS uses native Metal gameplay and a SceneKit GLTFKit2 HUD overlay, not the identical renderer binary. No claim of GPU-byte parity.

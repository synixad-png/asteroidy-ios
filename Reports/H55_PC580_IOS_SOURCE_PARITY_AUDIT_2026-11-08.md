# ASTEROIDY PC v580 → iOS H55: source-level collision audit (2026-11-08)

**Status: FAIL for 1:1 collision parity. This is an audit, NOT a new fixed IPA.** Do not call previous spawn patches complete or claim that automated Swift tests prove on-device entry.

Sources (original user-uploaded v580 archive):
- `Windows/src/Hub90.cs`: `EnterMenuHangar397`, `BeginHubScene397`, `StepHub90`. Menu enters the **same physical H55/H72 GLB** as orbital dock. Walk turns on after **3.25s**, only when `HubWalkSpawnClear380`.
- `Windows/src/HubWalk375.cs:130-149`: `HubWalkPlaceAtEntry380` tests exactly (2,14), (3,14), (-2,14), (4,15), (-4,15), (6,15), in order. For each candidate require `H55FullCollision379.Support(x,z,-.25,.45)`, `BodyClear(x,floor,z)`, **AND** `BodyClear(x,floor+.55,z)`, `BodyClear(x,floor+1.15,z)`, `BodyClear(x,floor+4.50,z)`. No invented backup spawn.
- `Windows/src/HangarCollision441.cs`: `FromGlb` builds actual world-space triangles and indexed prefab collision proxies from active GLB transforms. Excludes *specific dynamic mechanic/drone meshes* and controlled doors; splits measured hollow portals into solid jambs/header; includes corridor floor bridge.
- `Windows/src/HubWalk375.cs:696+`: `H55FullCollision379` indexes 2m buckets. `Support` (789+) projects onto triangles barycentrically, verifies `ny² >= 0.65(nx²+nz²)` independent of winding, and returns highest support within the specified vertical interval. `SupportLowest403` and `HubWalkSupport379` (center, ring voting, screw/trim exclusions) govern walking stability.
- `H55FullCollision379.BodyClear` (888+) verifies exact scene bounds (external GLB geometry bounds when appropriate), docked ship radius 3.95m, prefab proxy AABBs, and **four 3D point-to-triangle spheres**, radius **.325m** (`.34-.015`) at feet+`.335,.780,1.225,1.670`. Uses `Dist2` region tests, not rays.
- `HubWalk375.cs:401-649`: full wall-contact normal based on penetration energy, swept slide, recovery, stairs, step-headroom, original support votes; 5cm motion subdivisions. `Hub90.cs:67` applies arrival state gate.

**Verified gaps in PR #28 iOS**:
1. `H55ScenePage580.supportHeight` uses `SCNNode.hitTestWithSegment` and SceneKit normals. It is **not** the original `HangarCollision441` active triangle/proxy support query; reversed-normal correction alone is insufficient.
2. `H55ScenePage580.bodyClear` tests radial **ray segments** at tier heights, not source four-sphere exact point-to-triangle clearance. Can give false free/blocked positions.
3. iOS entry tests only one `bodyClear`; misses original checks at floor+.55, floor+1.15, floor+4.50.
4. `H55Walk580` still lacks source `HubWalkSupport379` center/ring votes, full capsule-step sweep, stair ramp, collision energy, contact-normal sliding and camera stabilizer.
5. iOS hardcoded map bounds disagree with original `H72Bounds392` derived extents for external GLB.
6. iOS starts walking immediately after loading rather than after PC's 3.25s arrival.
7. Door/dynamic geometry exclusions, 3D proxies, full NPC interactions and service flows are not source-parity implementations.

**Required corrective work**:
- Port `HangarCollision441.FromGlb` geometry/proxy builder **faithfully** (including active scene, prefab instance IDs, dynamically excluded objects and hollow portal handling); no SceneKit visual-mesh ray fallback.
- Port `H55FullCollision379.Support`, `Dist2`, `BodyClear`, proxy and ship bounds before enabling walk. Exact source spawn tests on **all six** candidates with four clearance levels must pass on the actual uploaded GLB (`SHA256 00e6ba4ab2cce025b1290265052c1e252e149209f6fcbbc50b5d569af4592461`).
- Then restore source `HubWalk375` movement/arrival logic and run differential output tests against the original PC algorithms, not just constants/mock floor shapes.
- Finally test actual scene/controls on physical iPhone/iPad. Until then, **do not claim fixed**.

Note: `Windows/src/HubWalk375.cs` and `SteamOS/src/HubWalk375.cs` in the uploaded archive are **not identical**; use the Windows PC v580 reference for this audit, not an unverified amalgam.

No physics or graphics code changed in this audit. No new IPA was released.

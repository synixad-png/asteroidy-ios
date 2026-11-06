#!/usr/bin/env python3
"""Positive end-to-end input test of the user's REAL uploaded PC v568 assets.

Run only when both original, non-LFS files are committed to GitHub.
Uses the actual 194427 source GPU vertices, normals, colours, and UVs.
No GLB conversion, synthetic mesh, invented colour/UV or screenshot.
"""
from pathlib import Path
import hashlib
import math
import struct
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "Tools"))
from verify_original_vanguard_resources import EXPECTED, inspect_assets

assets = ROOT / "ASTEROIDYiOS" / "Assets"
actual = {name: (assets / name).read_bytes() for name in EXPECTED}
inspect_assets(actual)
raw = actual["Vanguard431Source.mesh"]

version, engine_count = struct.unpack_from("<ii", raw, 0)
assert (version, engine_count) == (4311, 2)
left = struct.unpack_from("<3f", raw, 8)
right = struct.unpack_from("<3f", raw, 20)
for observed, expected in zip(left, (-0.44299396872520447, -1.5887130498886108,
                                    -0.1674797236919403)):
    assert abs(observed - expected) < 1e-7, "First original engine nozzle changed"
for observed, expected in zip(right, (0.44578471779823303, -1.5894304513931274,
                                      -0.18300314247608185)):
    assert abs(observed - expected) < 1e-7, "Second original engine nozzle changed"

float_count = struct.unpack_from("<i", raw, 32)[0]
count = float_count // 12
assert count == 194427
end = 36 + count * 48
stream = memoryview(raw)[36:end]
mins = [math.inf] * 3
maxs = [-math.inf] * 3
uvmin = [math.inf, math.inf]
uvmax = [-math.inf, -math.inf]
for idx, v in enumerate(struct.iter_unpack("<12f", stream)):
    position = v[:3]
    normal = v[3:6]
    rgba = v[6:10]
    uv = v[10:12]
    assert all(map(math.isfinite, v)), f"Non-finite source vertex: {idx}"
    assert 0.999 < sum(n*n for n in normal) < 1.001, (
        f"Incorrect original normal at {idx}"
    )
    assert rgba == (1.0, 1.0, 1.0, 1.0), "Original texture tint changed"
    assert 0 <= uv[0] <= 1 and 0 <= uv[1] <= 1, (
        f"Incorrect native source UV at {idx}"
    )
    for axis in range(3):
        mins[axis] = min(mins[axis], position[axis])
        maxs[axis] = max(maxs[axis], position[axis])
    for axis in range(2):
        uvmin[axis] = min(uvmin[axis], uv[axis])
        uvmax[axis] = max(uvmax[axis], uv[axis])

for got, original in zip(mins, (-1.43999994, -1.59667253, -0.59436774)):
    assert abs(got-original) < 0.00001, (got, original)
for got, original in zip(maxs, (1.43999994, 1.59667253, 0.59436774)):
    assert abs(got-original) < 0.00001, (got, original)
assert uvmin[0] < 0.002 and uvmin[1] < 0.004
assert uvmax[0] > 0.998 and uvmax[1] > 0.998
assert struct.unpack_from("<i", raw, end)[0] == 10802
print("PASS: both original PC v568 Vanguard source binaries are physically in repo")
print("      SHA256 matches exactly, not Git-LFS pointers or renamed resources")
print("      194427 3D positions, 194427 authentic unit normals,")
print("      194427 unchanged RGBA white tints and original GLB UV coordinates")
print("      exact source bounds, two real engine sockets and 10802 CPU triangles")
print("LIMIT: confirms source assets, not the built .app or live Apple GPU output")

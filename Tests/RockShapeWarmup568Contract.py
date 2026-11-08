#!/usr/bin/env python3
"""Keep Metal rock allocation out of the first combat hit/destroy frame.

Source shape mapping comes from the original StoneSubdivide56/RockVertices75,
not a new visual approximation. The W3 menu must not pay for combat variants.
"""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
geometry = (root / "ASTEROIDYiOS/CarbonisRockGeometry568.swift").read_text()
renderer = (root / "ASTEROIDYiOS/Sector01CarbonisPreview568.swift").read_text()
tests = (root / "Tests/CarbonisRockGeometry568Tests.swift").read_text()

assert "static let sourceShapeCount=8*5*2" in geometry
assert "(rock.shapeSeed & 7)*5+max(0,min(4,rock.tier))+(rock.fragment ? 40 : 0)" in geometry
assert "let initialShapes=Set(initialRocks.map" in renderer
assert "let preloadShapes:Set<Int> = gameSession == nil" in renderer
assert "? initialShapes" in renderer  # W3 planet-only preview remains light
assert ": Set(0..<CarbonisRockGeometry568.sourceShapeCount)" in renderer
assert "for shape in preloadShapes.sorted()" in renderer
# Initialization now uses the single exact Float-array GPU upload path.
# Verify that all 80 source shapes are still allocated and stored eagerly.
assert "rockBuffers[shape]=try Self.makeBuffer(values,device:device)" in renderer
assert "private static func makeBuffer(_ values:[Float],device:MTLDevice)" in renderer
assert "device.makeBuffer(bytes:$0,length:raw.count,options:[])" in renderer
assert "if rockBuffers[shape] == nil" in renderer  # legacy fallback preserved
assert "for shape in 0..<CarbonisRockGeometry568.sourceShapeCount" in tests
print("PASS: 80 exact original rock shapes preallocated for combat; W3 preview and fallback preserved")

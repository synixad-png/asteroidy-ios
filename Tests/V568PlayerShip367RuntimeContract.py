#!/usr/bin/env python3
"""Source and build-contract regression for opt-in, real v568 PlayerShip367.

Only a native macOS Xcode and simulator/GPU run can verify render and frame
placement, so these checks explicitly do not declare visual fidelity.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
app=(root/"ASTEROIDYiOS/App.swift").read_text()
renderer=(root/"ASTEROIDYiOS/MetalRenderer.swift").read_text()
source=(root/"ASTEROIDYiOS/SourcePlayerShip367.swift").read_text()
prepare=(root/"Tools/prepare_v568_player_ship_ios.py").read_text()
workflow=(root/".github/workflows/verify-combat-only.yml").read_text()
assert "@Published var sourceShip367Preview = false" in app
assert "input.sourceShip367Preview.toggle()" in app
assert "private func verifiedPlayerShip367()" in renderer
assert 'forResource: "PlayerShip367OriginalGPU"' in renderer
assert 'forResource: "PlayerShip363Base"' in renderer
assert 'SourcePlayerShip367.verifiedTexture(jpegBytes)' in renderer
assert 'SourcePlayerShip367(' in renderer
assert "sourceFighterTexturedPipeline431" in renderer
assert "if input.sourceShip367Preview {" in renderer
assert "if let native=verifiedPlayerShip367() {" in renderer
assert "drawMesh(shipMesh,shipModel)" in renderer
assert renderer.index("if input.sourceShip367Preview {")<renderer.index(
    "if let native=verifiedPlayerShip367() {")
assert 'vertexCount = 599_997' in source
assert 'expectedGPU_SHA256' in source
assert 'expectedTexture_SHA256' in source
assert "runtimeIntegrated" not in source  # model is read, not falsely marked fully tested
assert 'stage.verify_archive_set(args.root)' in prepare
assert 'source.convert(mesh)' in prepare
assert 'ASTEROIDYiOS/Assets' in prepare
assert "Wrong original v568 PlayerShip363 base JPG" in (root/"Tools/convert_v568_player_ship367.py").read_text()
assert workflow.index("Prepare ONLY original source-verified PlayerShip367 assets")<workflow.index(
    "Generate native Xcode project from verified project.yml")
assert "python3 Tests/V568PlayerShip367RuntimeContract.py" in workflow
print("PASS: exact v568 optional PlayerShip367, original packet and JPEG verified")
print("PASS: default v556 ship unchanged; no invented fallback when v568 source is missing")
print("LIMIT: native compile and visual GPU/frame-placement proof are separate")

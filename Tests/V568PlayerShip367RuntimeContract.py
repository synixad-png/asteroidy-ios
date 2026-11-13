#!/usr/bin/env python3
"""Source and build-contract regression for opt-in, real v568 PlayerShip367.

Only a native macOS Xcode and simulator/GPU run can verify render and frame
placement, so these checks explicitly do not declare visual fidelity.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]


def job_block(workflow_file, job):
    """Text of one job in a merged workflow file: its id line up to the next job id."""
    import re
    lines = (root/".github/workflows"/workflow_file).read_text().split("\n")
    start = lines.index(f"  {job}:")
    end = next((i for i in range(start + 1, len(lines))
                if re.match(r"^  [A-Za-z0-9_-]+:\s*$", lines[i])), len(lines))
    return "\n".join(lines[start:end])


app=(root/"ASTEROIDYiOS/App.swift").read_text()
renderer=(root/"ASTEROIDYiOS/MetalRenderer.swift").read_text()
source=(root/"ASTEROIDYiOS/SourcePlayerShip367.swift").read_text()
prepare=(root/"Tools/prepare_v568_player_ship_ios.py").read_text()
compile_job=job_block("mac-tests.yml","compile-ios-no-ipa")
test_job=job_block("source-tests.yml","verify-combat-no-ipa")
assert '@Published var sourceShip367Preview =\n        ProcessInfo.processInfo.environment["ASTEROIDY_SHIP367_VERIFY"] == "1"' in app
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
assert compile_job.index("Prepare ONLY original source-verified PlayerShip367 assets")<compile_job.index(
    "Generate native Xcode project from verified project.yml")
assert "python3 Tests/V568PlayerShip367RuntimeContract.py" in test_job
print("PASS: exact v568 optional PlayerShip367, original packet and JPEG verified")
print("PASS: default v556 ship unchanged; no invented fallback when v568 source is missing")
print("LIMIT: native compile and visual GPU/frame-placement proof are separate")

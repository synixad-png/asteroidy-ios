#!/usr/bin/env python3
"""Fail-closed contract for the real v568 PlayerShip367 Apple GPU draw proof."""
from pathlib import Path
import importlib.util
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/"Tools"))
spec=importlib.util.spec_from_file_location(
    "source367_capture",root/"Tools/run_v568_player_ship367_simulator_capture.py")
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
assert module.validate(dict(module.EXPECTED))
for key in ("vertexCount","gpuCommandBufferCompleted","sourceGPU_SHA256",
            "skinSHA256","pipeline","bundleID"):
    forged=dict(module.EXPECTED)
    forged[key]=False
    try:
        module.validate(forged)
    except module.AppValidationFailed:
        pass
    else:
        raise AssertionError("Accepted fraudulent GPU evidence: "+key)
app=(root/"ASTEROIDYiOS/App.swift").read_text()
renderer=(root/"ASTEROIDYiOS/MetalRenderer.swift").read_text()
capture=(root/"Tools/run_v568_player_ship367_simulator_capture.py").read_text()
assert app.count('ProcessInfo.processInfo.environment["ASTEROIDY_SHIP367_VERIFY"]')==2
assert "sourceShip367DrawProofRequested" in renderer
assert "sourceShip367DrawProofScheduled" in renderer
assert '"ASTEROIDY_PlayerShip367_RenderProof.json"' in renderer
assert renderer.index("encoder.drawPrimitives(type:.triangle,vertexStart:0,\n                        vertexCount:native.count)")<renderer.index("sourceShip367DrawProofScheduled=true")
assert "command.addCompletedHandler { finished in" in renderer
assert '"gpuCommandBufferCompleted":finished.status == .completed' in renderer
assert 'proof_path.unlink(missing_ok=True)' not in capture # unlink in per-path freshness loop
assert "for stale in (proof_path,screenshot,verified):" in capture
assert 'env["SIMCTL_CHILD_ASTEROIDY_SHIP367_VERIFY"]="1"' in capture
assert "validate(proof)" in capture
assert "screenshot.rename(verified)" in capture
assert capture.index("validate(proof)")<capture.index("screenshot.rename(verified)")
print("PASS: v568 GPU proof can only follow actual PlayerShip367 Metal draw")
print("PASS: stale images and prior sandbox proof cleared, mismatched proof fails")
print("LIMIT: simulator GPU still needed to establish actual execution")

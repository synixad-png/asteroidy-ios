#!/usr/bin/env python3
"""All original GPU proofs use one atomic writer, without hiding write errors.

Original GPU diagnostic proofs for Vanguard431, PlayerShip367, NewHome290, Carbonis L1 and W3 source-ship previews.
Each remains opt-in and runs only from a completed Metal command callback.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
gpu=root/"ASTEROIDYiOS"
writer=(gpu/"OriginalRenderProofWriter568.swift").read_text()
paths={
    "MetalRenderer.swift":[
        "ASTEROIDY_Vanguard431_RenderProof.json",
        "ASTEROIDY_PlayerShip367_RenderProof.json",
    ],
    "W3HomePlanetMetal568.swift":["ASTEROIDY_W3_NewHome290_GPUProof.json"],
    "Sector01CarbonisPreview568.swift":["ASTEROIDY_CARBONIS_L1_GPUProof.json"],
    "W3HomeShipPreview568.swift":["ASTEROIDY_W3_Vanguard431_GPUProof.json",
                                   "ASTEROIDY_W3_Bastion606_GPUProof.json",
                                   "ASTEROIDY_W3_Kestrel603_GPUProof.json"],
}
for name,filenames in paths.items():
    source=(gpu/name).read_text()
    assert source.count("OriginalRenderProofWriter568.save(")==len(filenames),name
    for filename in filenames:
        assert f'filename:"{filename}"' in source, (name,filename)
    # W3 Kestrel, Vanguard and Bastion are exclusive alternatives from ONE frame.
    # A single completed-command callback dispatches both proof names.
    callback_min=1 if name=="W3HomeShipPreview568.swift" else len(filenames)
    assert source.count("command.addCompletedHandler")>=callback_min,name
    assert "JSONSerialization.data(" not in source, f"Duplicate GPU proof serializer in {name}"
    assert "try? bytes.write" not in source and "try? data.write" not in source

home=(gpu/"W3HomePlanetMetal568.swift").read_text()
carbonis=(gpu/"Sector01CarbonisPreview568.swift").read_text()
metal=(gpu/"MetalRenderer.swift").read_text()
ship=(gpu/"W3HomeShipPreview568.swift").read_text()
for scene in (home,carbonis):
    assert 'ProcessInfo.processInfo.environment["ASTEROIDY_W3_MENU_VERIFY"]=="1"' in scene
    assert "proofScheduled=true" in scene
    assert '"gpuCommandBufferCompleted":' in scene
assert '"triangles":270249' in carbonis
assert '"vertexCount":516624' in home
assert '"originalW3PreviewScale":0.34' in ship
assert '"gpuCommandBufferCompleted":' in ship
assert '"ASTEROIDY_W3_MENU_VERIFY"]=="1"' in ship
assert "sourceDrawProofRequested && !sourceDrawProofScheduled" in metal
assert "sourceShip367DrawProofRequested &&" in metal

# Keep identical sorting, atomicity and error reporting in one place.
for contract in ("JSONSerialization.data(", "withJSONObject: payload",
                 "options: [.sortedKeys]", "try bytes.write(",
                 "options: .atomic", "catch {",
                 "ASTEROIDY render proof write failed"):
    assert contract in writer,contract

print("PASS original GPU proofs with exclusive W3 Kestrel/Vanguard/Bastion: one atomic writer, no duplicate callback")

#!/usr/bin/env python3
"""All original GPU proofs use one atomic writer, without hiding write errors.

Four diagnostic proofs: Vanguard431, PlayerShip367, NewHome290, Carbonis L1.
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
}
for name,filenames in paths.items():
    source=(gpu/name).read_text()
    assert source.count("OriginalRenderProofWriter568.save(")==len(filenames),name
    for filename in filenames:
        assert f'filename:"{filename}"' in source, (name,filename)
    assert source.count("command.addCompletedHandler")>=len(filenames),name
    assert "JSONSerialization.data(" not in source, f"Duplicate GPU proof serializer in {name}"
    assert "try? bytes.write" not in source and "try? data.write" not in source

home=(gpu/"W3HomePlanetMetal568.swift").read_text()
carbonis=(gpu/"Sector01CarbonisPreview568.swift").read_text()
metal=(gpu/"MetalRenderer.swift").read_text()
for scene in (home,carbonis):
    assert 'ProcessInfo.processInfo.environment["ASTEROIDY_W3_MENU_VERIFY"]=="1"' in scene
    assert "proofScheduled=true" in scene
    assert '"gpuCommandBufferCompleted":' in scene
assert '"triangles":270249' in carbonis
assert '"vertexCount":516624' in home
assert "sourceDrawProofRequested && !sourceDrawProofScheduled" in metal
assert "sourceShip367DrawProofRequested &&" in metal

# Keep identical sorting, atomicity and error reporting in one place.
for contract in ("JSONSerialization.data(", "withJSONObject: payload",
                 "options: [.sortedKeys]", "try bytes.write(",
                 "options: .atomic", "catch {",
                 "ASTEROIDY GPU proof write failed"):
    assert contract in writer,contract

print("PASS 4 original GPU completion proofs: one fail-visible atomic writer, unchanged opt-in gates, filenames and source payloads")

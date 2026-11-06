#!/usr/bin/env python3
"""True source v568 W3 HOME default Vanguard431 preview contract.

The 4 audited v568 ZIPs include Campaign37.cs, ShipMesh.cs and
Vanguard431.cs. The complete GpuW3HomeReal333.cs is in the user's
full v568 source archive, but NOT in those 4 ZIPs; its preview
constants are held as explicit porting contracts, not falsely
advertised as a full CI comparison against an absent file.
"""
from pathlib import Path
import importlib.util

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location("v568_stage",ROOT/"Tools/stage_v568_resources.py")
stage=importlib.util.module_from_spec(spec)
spec.loader.exec_module(stage)
open_files=[]
try:
    open_files,entries,hashes,total=stage.verify_archive_set(ROOT)
    def original(name):
        z,entry=entries["PortingReferenceCode/v568/Windows/src/"+name]
        return z.read(entry).decode("utf-8-sig")
    campaign=original("Campaign37.cs")
    ship=original("ShipMesh.cs")
    vanguard=original("Vanguard431.cs")
    assert "ShipType=1" in campaign
    assert "rawType==1&&playableShip" in ship
    assert "Vanguard431.TryApply(this)" in ship
    assert "if(r.ReadInt32()!=4311)" in vanguard
    assert "mesh.Start[0]=0" in vanguard
    assert "mesh.Count[0]=vertices.Length/12" in vanguard

    ios=(ROOT/"ASTEROIDYiOS/W3HomeShipPreview568.swift").read_text()
    menu=(ROOT/"ASTEROIDYiOS/W3MainMenu568.swift").read_text()
    metal=(ROOT/"ASTEROIDYiOS/Ship.metal").read_text()
    expected=[
        "SourceVanguardMesh431(data:source)",
        "SourceVanguardMesh431.exactMeshSHA256",
        "SourceVanguardMesh431.exactBaseJPEG_SHA256",
        'sourceVanguardVertex431',
        'w3HomeVanguardFragment431',
        "Self.translation(0,-0.15,-5.5)",
        "Self.rx(18 * .pi/180)",
        "Self.ry(elapsed * 42 * .pi/180)",
        "Self.rz(sin(elapsed * 0.71) * 8 * .pi/180)",
        "Self.scale(0.34)",
        "let halfH:Float=0.33*0.88",
        '"ASTEROIDY_W3_Vanguard431_GPUProof.json"'
    ]
    for token in expected:
        assert token in ios,token
    assert "W3HomeShipPreview568.isAvailable" in menu
    assert "W3HomeShipPreview568()" in menu
    assert 'Text("STATEK / PODGLĄD")' in menu
    assert "VANGUARD / TYP 01" in menu
    assert "fragment float4 w3HomeVanguardFragment431" in metal
    assert "float3 key=normalize(float3(-0.6f,0.8f,1.4f))" in metal
    assert "float band=0.25f+0.78f*d" in metal
    assert "gl_FragColor" not in metal  # Native Metal, not old GLSL hack.
    print("PASS: original v568 Campaign37 default ship type 1 is Vanguard431")
    print("PASS: W3 native GPU preview uses exact source mesh and source skin")
    print("PASS: original W3 source transform and smooth Toon60 constants pinned")
    print("LIMIT: PC GpuW3HomeReal333.cs is not part of 4 ZIP references;")
    print("       actual Apple GPU proof and complete ship effects still require testing")
finally:
    for z in open_files:
        z.close()

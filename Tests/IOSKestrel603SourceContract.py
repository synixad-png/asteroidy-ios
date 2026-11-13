#!/usr/bin/env python3
"""Static source-integrity regression for true PC609 KESTREL ShipType 0.

Checks routes and authentic model registration; dynamic Swift GPU proof is
provided independently by Apple ARM64 compile and device testing.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
def read(p):
    return (root/p).read_text(encoding="utf-8")
packer=read("Tools/build_kestrel603_ios_pack.py")
importer=read("ASTEROIDYiOS/SourceKestrel603.swift")
mechanics=read("ASTEROIDYiOS/H55SourceMechanics580.swift")
fleet=read("ASTEROIDYiOS/H55WorkshopPanel580.swift")
hangar=read("ASTEROIDYiOS/H55PlayerShip580.swift")
hangar_scene=read("ASTEROIDYiOS/H55ScenePage580.swift")
home=read("ASTEROIDYiOS/SourceHomeVanguard431.swift")
driver=read("ASTEROIDYiOS/PC602HomeWorldDriver291.swift")
flight=read("ASTEROIDYiOS/PC602HomeFlight291.swift")
combat=read("ASTEROIDYiOS/Sector01CarbonisPreview568.swift")
menu=read("ASTEROIDYiOS/W3HomeShipPreview568.swift")
for s in (packer,importer):
    for token in (
        "5d3598b655f362f284550261c4cbfe14775d1568885f1ce22b2baaa1c2c288a2",
        "9652c1ab9db5bbe75135c005df9d32e4147c1393615d4b2822d4c295b93ae34a",
        "f6a717ad7a50497da5ee232e50dc156f946081cef98d9d258c30ce26008fcba6",
        "KST60901",
    ):
        assert token in s, token
assert "6031" in packer and "expectedMagic:6031" in importer
assert "expectedGPUVertexCount=189_906" in importer
assert "SourceBakedShipMesh(" in importer
assert "try SourceKestrel603.install(from:file)" not in fleet
assert "h11-import-kestrel603" not in fleet
assert "h11-import-bastion606" not in fleet
assert 'WCZYTAJ MODEL KESTREL PC609 Z PLIKÓW' not in fleet
assert 'WCZYTAJ MODEL BASTION PC609 Z PLIKÓW' not in fleet
assert "h55-pc609-embedded-model-error" in fleet
assert "SourcePC609Zlib.inflateRFC1950" in importer
assert "SourcePC609Zlib.inflateRFC1950" in read("ASTEROIDYiOS/SourceBastion606.swift")
assert 'case 0:return kestrelAssetURL == nil ? nil : "SOURCE-PC603-KESTREL"' in mechanics
assert "SourceKestrel603.load()" in hangar and "originalModelVerified" in hangar
assert "kestrelNodeName" in hangar and "kestrelNodeName" in hangar_scene
assert "case 0:" in hangar and "kestrelGeometry=try? loadKestrel()" in hangar
assert "shipType==0" in home and "SourceKestrel603.load()" in home
assert "selectedShip==0 ? .kestrel" in driver
assert "selectedShip==0 ? 1.08" in driver
assert "ship==0 && SourceKestrel603.load() != nil" in driver
assert "[.kestrel,.vanguard,.bastion].contains" in flight
assert "if equipped==0" in combat and "SourceKestrel603.load()" in combat
assert "if selectedShip==0" in menu and "SourceKestrel603.load()" in menu
assert 'id==0 ? "Kestrel-PC609-ShipType0"' in menu
assert "SourceBakedShipMesh" in read("ASTEROIDYiOS/SourceVanguardMesh431.swift")
assert 'case 2:return bastionAssetURL == nil ? nil : "SOURCE-PC606-BASTION"' in mechanics
print("PASS KESTREL PC609: SHA, 6031 GPU ABI, embedded pack runtime decoder, H55/H290/C279/W3, PC shipType=0 dynamics, Vanguard/Bastion regressions")

#!/usr/bin/env python3
"""O01: identity and source-mapping guard, NOT a gameplay parity claim.

With --pc-zip, verify the exact user-provided v602 original and 19 C# files.
Without --pc-zip (CI), verify ONLY the iOS source's current mapping anchors;
print an explicit partial-coverage notice. Do not silently infer PC contents.
"""
import argparse
import hashlib
from pathlib import Path
import sys
import zipfile

ZIP_SHA = "359abd889544c846faa9426fd291df8528951ed2253fe67c47dbb9e9d9f2103b"
PC_SHA = {
    "HomeFlight291.cs": "7c26c62fc8010064f419512e83ce7b61e94cff8764d92cf595675c39d02a61d5",
    "Orbit50.cs": "8154038327fd78129cd8678bc482103f78bfa5e5c9756b344790cdba73aee5de",
    "OrbitWorld51.cs": "eb11e470fede861365143b1d11c74aacafa728f73f2092d4ab2f43ba756d276b",
    "SphereCombat67.cs": "c7bed25e62a06f4ef5d20ed9d1dc3fd0791780ec1dbe9746d40635904675e0be",
    "FlightDynamics298.cs": "111420ecfa889d360bc5557a56b3be8cab1846ed54fa6f30184da78b9a1e5fd0",
    "Campaign37.cs": "7418d8622bbe2a7b68c33823698572ebc011879c4576922bb58128c000b68874",
    "Modules97.cs": "dee2f806b778c8780b010248e7c5cec5d3f3508971b653a193efd2c5ca66bb01",
    "Game.cs": "34fd8b2877f5784a68ad7b2a7d31d59f506d3254a499c9124e720958f6e651ea",
    "SaveManager61.cs": "79e8162cae1966fb0c593f7c9bc666d7735965d650e855c4b1d2afb123b745e3",
    "Hub90.cs": "a908a3632d22fab0932798405e0d0faff39334e2f1298d9e2d607d5b42587a4d",
    "NewHome290.cs": "01a402967eee017a9e1d1fc526b974969c3055f5aea1904eab6140a002950500",
    "GpuIntro41.cs": "cdeecc6eedc96084e12d50d4062ba981feb404ade6b9d6b25ae333e43486c45e",
    "GpuAmbient37.cs": "92f9d3e096d77e2eed1f9a0f42e206ef8d433148637c2b7f5bfc27d633560636",
    "GpuToon60.cs": "2410cc91b17e640ddda0794a2b5f269fecc6650b0c81c47f0f66a9ecf9e097d7",
    "PlanetLife52.cs": "87ed9a5c23e331465a05c3baddc89da2d4e73e72c4f3f2e958705319811d05d4",
    "VisualStyle58.cs": "d14261dfc1c0d96014f8bc52c32f208bdbcf3e4018277164ec29224ec6fcb3d7",
    "GunMesh101.cs": "dd5dcb2da9d148f622c67169ae92a27c8705d4cb6658dcbb28876d83bfdad617",
    "MusicAudio.cs": "7f62ef5e1e41cf46046875fd4c582c4abc2ddbc68209ed1729bdadd237661318",
    "MusicSynth.cs": "1809d4cbe3bc2fb2d8ca088ba02cd61b36803d32ef8973094b2f9d9f4748900f",
}
PC_ANCHORS = {
    "HomeFlight291.cs": (
        "DirectFlight67(dt,input);", "MoveShip67(dt);",
        "UpdateSphereCamera67(dt);", "StepHomeWeaponTest292(dt,input.Fire);",
        "int originalShots=Shots,originalIon=IonAmmo",
    ),
    "Orbit50.cs": (
        "if(NewHome290.Enabled){StepHomeFlight291(dt,input);return;}",
        "void StartHubMission261(int selected,bool moveOrbit)",
        "public void EnterOrbit50(bool reset=false)",
        "internal static IP SunDirection111(float seconds)",
    ),
    "Hub90.cs": (
        "OrbitSpeed50=0;OrbitVelocity51=new IP();",
        "public bool CanDock90",
    ),
    "SaveManager61.cs": (
        "ASTEROIDY-SAVE-369", "public bool SaveSlot61",
        "public static bool DeleteSlot61", "void PerformSave61",
        "checkpoint61=Snapshot61()",
    ),
    "GpuIntro41.cs": ("void IntroSky(bool glow,bool nebula,bool rays,bool orbit=false)", "i<1500"),
    "GunMesh101.cs": ("if(CraftType==1||CraftType==3)return;",),
}
IOS_ANCHORS = {
    "PC602HomeWorldSession291.swift": (
        "try flight.step(input,dt:dt)",
        "weapons.step(ship:flight.flight,dt:dt,",
        "route.exitHangar()",
    ),
    "PC602HomeFlight291.swift": (
        "struct PC602HomeFlight291",
        "flight.camera.update(target:flight.position,dt:dt)",
        "Sphere67.advance(old,",
        "static func canDock90",
    ),
    "PC602HomeWorldDriver291.swift": (
        "vanguardEquipment291(",
        "craft:.vanguard,",
        "engineLevel:state.engine",
        "thrusterRank:state.thruster",
        "stabilizerLevel:state.stabilizer",
        "func exitH55()",
        "func refreshCampaign(",
    ),
    "PC602HomeWeaponTest292.swift": (
        "struct PC602HomeWeaponTest292",
        "mutating func step(ship:SphereFlight67,dt:Float,fire:Bool)",
    ),
    "PC602HomeScene291.swift": (
        "let sunAngle:Float=0.62+max(0,flight.orbitTime)*0.047",
        "originalSky.draw(encoder:encoder,",
        "worldScale:SphereCameraView556.originalPlanetOuterRadius",
    ),
    "PC602HomeHubRoute90.swift": ("mutating func exitHangar()->Exit?",),
    "PC602OrbitSave61.swift": ("struct Snapshot:Codable", "slot.map{"),
    "App.swift": (
        "homeWorld291.refreshCampaign(campaign)",
        "onExitToMainMenu:{",
        "sourceSector01=nil",
    ),
    "PC602HomeWorldPage291.swift": (
        'Button("PAUZA") {openOrbitOptions291()}',
        'Button("POWRÓT DO MENU GŁÓWNEGO")',
    ),
}

def sha256(data):
    return hashlib.sha256(data).hexdigest()

def read_pc_zip(path):
    path = Path(path)
    assert path.is_file(), f"Not found: {path}"
    assert sha256(path.read_bytes()) == ZIP_SHA, "PC602 ZIP SHA mismatch"
    with zipfile.ZipFile(path) as archive:
        for name, expected in PC_SHA.items():
            data = archive.read("Windows/src/" + name)
            assert sha256(data) == expected, f"PC source mismatch: {name}"
            content = data.decode("utf-8-sig")
            for needle in PC_ANCHORS.get(name, ()):
                assert needle in content, f"Missing source anchor {name}: {needle}"
    print("PASS PC602 O01: exact original ZIP + 19 source SHA256 + C# anchors")

def read_ios_tree(root):
    root = Path(root) / "ASTEROIDYiOS"
    for name, needles in IOS_ANCHORS.items():
        file = root / name
        assert file.is_file(), f"Missing native file: {file}"
        content = file.read_text(encoding="utf-8")
        for needle in needles:
            assert needle in content, f"Missing iOS mapping: {name}: {needle}"
    print("PASS PC602 O01: current iOS source mapping anchors (NOT dynamic parity)")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--pc-zip", type=Path)
    parser.add_argument("--ios-root", type=Path)
    args = parser.parse_args()
    if not args.pc_zip and not args.ios_root:
        parser.error("Provide --pc-zip and/or --ios-root")
    if args.pc_zip:
        read_pc_zip(args.pc_zip)
    else:
        print("NOT TESTED: original PC602 archive absent (iOS-only check)")
    if args.ios_root:
        read_ios_tree(args.ios_root)
    else:
        print("NOT TESTED: iOS working tree absent (PC-only check)")

if __name__ == "__main__":
    main()

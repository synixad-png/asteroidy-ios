#!/usr/bin/env python3
"""Real native W3 menu screenshot on an Apple simulator, no IPA or fake image."""
import argparse
import json
import os
from pathlib import Path
import time
from run_original_ios_simulator_capture import (
    PACKAGE,AppValidationFailed,EnvironmentUnavailable,available_devices,run_command
)

CAPTIONS=["NOWA GRA","KONTYNUUJ","KAMPANIA","HANGAR",
          "USTAWIENIA","AUTORZY","WYJŚCIE"]
EXPECTED={
    "screen":"native-W3-v568-home",
    "menuItems":CAPTIONS,
    "navigationAvailable":True,
    "htmlOrWebView":False,
    "hasOriginalW3BackgroundImage":True,
    "hasOriginalW3LogoImage":True,
    "sourcePlanet3DIntegrated":True,
    "bundleID":PACKAGE,
    "simulatorOnly":True,
}
def validate(proof):
    if not isinstance(proof,dict):
        raise AppValidationFailed("W3 menu marker is not a JSON object")
    mismatches={k:(proof.get(k),v) for k,v in EXPECTED.items()
                if proof.get(k)!=v}
    if mismatches:
        raise AppValidationFailed("Incorrect native W3 screen marker: "+str(mismatches))

def capture(app,reports,kind):
    if not app.is_dir() or app.suffix!=".app":
        raise AppValidationFailed("Compiled native ASTEROIDY iOS app is missing")
    reports.mkdir(parents=True,exist_ok=True)
    devices=available_devices((kind,))
    (reports/"selected-devices.json").write_text(json.dumps(
        devices,sort_keys=True,indent=2),encoding="utf-8")
    _,name,udid,state=devices[kind]
    print("REAL",kind,name,udid,flush=True)
    proof_name="ASTEROIDY_W3_MenuProof.json"
    gpu_proof_name="ASTEROIDY_W3_NewHome290_GPUProof.json"
    try:
        if state!="Booted":
            run_command(["xcrun","simctl","boot",udid],45,
                        reports/f"{kind}_boot.txt")
        run_command(["xcrun","simctl","bootstatus",udid,"-b"],540,
                    reports/f"{kind}_bootstatus.txt")
        run_command(["xcrun","simctl","install",udid,str(app)],300,
                    reports/f"{kind}_install.txt")
        raw=run_command(
            ["xcrun","simctl","get_app_container",udid,PACKAGE,"data"],
            45,reports/f"{kind}_container.txt")
        proof=Path(raw.strip())/"Library"/"Caches"/proof_name
        planet_proof=Path(raw.strip())/"Library"/"Caches"/gpu_proof_name
        candidate=reports/f"{kind}_W3_candidate_unverified.png"
        verified=reports/f"{kind}_VERIFIED_ASTEROIDY_W3_NATIVE.png"
        for stale in (proof,planet_proof,
                      Path(raw.strip())/"Library"/"Caches"/"ASTEROIDY_W3_Vanguard431_GPUProof.json",
                      candidate,verified):
            try:stale.unlink(missing_ok=True)
            except OSError as exc:
                raise AppValidationFailed("Cannot clear stale evidence: "+str(exc))
        env=os.environ.copy()
        env["SIMCTL_CHILD_ASTEROIDY_W3_MENU_VERIFY"]="1"
        # The same source-verified iPad build passed on other Apple
        # simulator runs; CoreSimulator launch exceeded 50 s once during
        # parallel CI. Allow bounded recovery before classifying an app fault.
        launched=run_command(["xcrun","simctl","launch",udid,PACKAGE],150,
                              reports/f"{kind}_launch.txt",env=env)
        if PACKAGE not in launched:
            raise AppValidationFailed("Native W3 app did not launch")
        # The real OriginalAudioAV568 synthesizes and verifies two
        # entire PCM menu pieces before SwiftUI mounts W3MainMenu568.
        # A fixed 5-second delay is invalid (false negative on iPad).
        # Wait for the *app-written* SwiftUI view-appearance marker; this
        # does not fake a view, bypass audio or inject a screenshot.
        # Use a bounded deadline and fail closed if W3 never appears.
        started=time.monotonic()
        deadline=started+240
        while not proof.is_file() and time.monotonic()<deadline:
            time.sleep(3)
        elapsed=round(time.monotonic()-started,1)
        (reports/f"{kind}_source_music_to_W3_wait.txt").write_text(
            f"elapsed={elapsed}s; swiftuiProofExists={proof.is_file()}\\n",
            encoding="utf-8")
        if not proof.is_file():
            raise AppValidationFailed(
                f"Source music preparation did not reach W3 SwiftUI within {elapsed}s")
        # The marker proves SwiftUI appeared, but the planet's Metal
        # command buffer still needs its separate source GPU proof below.
        time.sleep(1)
        run_command(["xcrun","simctl","io",udid,"screenshot",
                     "--type=png",str(candidate)],55,
                    reports/f"{kind}_screenshot.txt")
        if not candidate.is_file() or candidate.stat().st_size<1000:
            raise AppValidationFailed("Missing genuine simulator W3 screenshot")
        pixels=run_command([
            "swift","Tools/verify_simulator_render_snapshot.swift",
            str(candidate)],75,reports/f"{kind}_pixels.txt",check=False)
        if "PASS: authentic ASTEROIDY simulator screenshot" not in pixels:
            raise AppValidationFailed("Native W3 scene pixel gate failed")
        if not proof.is_file():
            raise AppValidationFailed("No actual W3 SwiftUI view appearance evidence")
        try:payload=json.loads(proof.read_text(encoding="utf-8"))
        except (OSError,ValueError) as exc:
            raise AppValidationFailed("Unreadable native W3 marker: "+str(exc))
        validate(payload)
        if not planet_proof.is_file():
            raise AppValidationFailed("Original NewHome290 v568 GPU proof missing")
        try:
            gpu=json.loads(planet_proof.read_text(encoding="utf-8"))
        except (OSError,ValueError) as exc:
            raise AppValidationFailed("Unreadable NewHome290 GPU proof: "+str(exc))
        expected_gpu={
            "render":"NewHome290-source-v568-original-3D",
            "gpuCommandBufferCompleted":True,
            "vertexCount":516624,
            "triangleCount":172208,
            "materialGroups":2,
            "baseTextureWidth":2048,
            "baseTextureHeight":1024,
            "geometrySHA256":"e93a0bbafc9bb50a25726a828ada81f36675bf88d802c5a8f985b89b6dc96c1b",
            "baseSHA256":"4987f35cd6f021fd98794f406c641f4853c538a82b10625e6b79e860c8a787c0",
            "glowSHA256":"6f1debd175f52b7ce1fbc687e9977597335ee432858d7d6d6e47cf66b5f9aa39",
            "simulatorOnly":True
        }
        errors={key:(gpu.get(key),v) for key,v in expected_gpu.items()
                if gpu.get(key)!=v}
        if errors:
            raise AppValidationFailed("NewHome290 GPU proof mismatches: "+str(errors))
        if kind=="IPAD":
            # Original PC W3 HOME right-hand panel shows default
            # Vanguard431 ShipType 1. iPad displays that side panel;
            # narrow iPhones intentionally omit it in responsive layout.
            ship_path=Path(raw.strip())/"Library"/"Caches"/"ASTEROIDY_W3_Vanguard431_GPUProof.json"
            if not ship_path.is_file():
                raise AppValidationFailed("Actual v568 W3 Vanguard431 ship GPU proof missing on iPad")
            try:
                ship=json.loads(ship_path.read_text(encoding="utf-8"))
            except (OSError,ValueError) as exc:
                raise AppValidationFailed("Unreadable W3 Vanguard431 GPU proof: "+str(exc))
            expected_ship={
                "source":"Vanguard431-default-ShipType1-v568",
                "gpuCommandBufferCompleted":True,
                "vertexCount":194427,
                "meshSHA256":"f5d6d0107437fa54c3e8505f9adfbf6143cc877cb970eef687603609e26f9f4a",
                "skinSHA256":"2945f711a6b559bfb5fdfb79750a2f2f77e2071aa5f3f4173eb450bce81b8b95",
                "originalW3PreviewScale":0.34,
                "simulatorOnly":True
            }
            differences={key:(ship.get(key),value)
                         for key,value in expected_ship.items() if ship.get(key)!=value}
            if differences:
                raise AppValidationFailed("W3 source ship GPU mismatch: "+str(differences))
            (reports/f"{kind}_W3_Vanguard431_GPU_proof.json").write_text(
                json.dumps(ship,sort_keys=True,indent=2),encoding="utf-8")
        (reports/f"{kind}_W3_NewHome290_GPU_proof.json").write_text(
            json.dumps(gpu,sort_keys=True,indent=2),encoding="utf-8")
        (reports/f"{kind}_W3_appearance_proof.json").write_text(
            json.dumps(payload,sort_keys=True,indent=2),encoding="utf-8")
        candidate.rename(verified)
        print("PASS REAL",kind,"native W3 source-caption SwiftUI view "
              "appeared and actual nonblank screenshot saved",flush=True)
        print("PASS: original NewHome290 v568 Metal source planet drew 172208 triangles",flush=True)
        print("LIMIT: shader pixel parity and all seven touch routes not yet tested",flush=True)
    finally:
        try:
            run_command(["xcrun","simctl","terminate",udid,PACKAGE],15,
                        check=False)
        except EnvironmentUnavailable:
            pass
        if state!="Booted":
            try:
                run_command(["xcrun","simctl","shutdown",udid],20,
                            check=False)
            except EnvironmentUnavailable:
                pass

if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--app",type=Path,required=True)
    p.add_argument("--reports",type=Path,required=True)
    p.add_argument("--only",choices=("IPHONE","IPAD"),required=True)
    args=p.parse_args()
    try:capture(args.app,args.reports,args.only)
    except (EnvironmentUnavailable,AppValidationFailed,OSError,ValueError) as exc:
        print("FAIL / INCONCLUSIVE: "+str(exc),flush=True)
        raise SystemExit(1)

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
    "sourcePlanet3DIntegrated":False,
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
        candidate=reports/f"{kind}_W3_candidate_unverified.png"
        verified=reports/f"{kind}_VERIFIED_ASTEROIDY_W3_NATIVE.png"
        for stale in (proof,candidate,verified):
            try:stale.unlink(missing_ok=True)
            except OSError as exc:
                raise AppValidationFailed("Cannot clear stale evidence: "+str(exc))
        env=os.environ.copy()
        env["SIMCTL_CHILD_ASTEROIDY_W3_MENU_VERIFY"]="1"
        launched=run_command(["xcrun","simctl","launch",udid,PACKAGE],50,
                              reports/f"{kind}_launch.txt",env=env)
        if PACKAGE not in launched:
            raise AppValidationFailed("Native W3 app did not launch")
        time.sleep(5)
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
        (reports/f"{kind}_W3_appearance_proof.json").write_text(
            json.dumps(payload,sort_keys=True,indent=2),encoding="utf-8")
        candidate.rename(verified)
        print("PASS REAL",kind,"native W3 source-caption SwiftUI view "
              "appeared and actual nonblank screenshot saved",flush=True)
        print("LIMIT: no proof of all touch navigation actions, source W3 "
              "JPEG/logo and 3D globe not yet present",flush=True)
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

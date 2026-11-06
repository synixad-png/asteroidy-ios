#!/usr/bin/env python3
"""Capture REAL source v568 PlayerShip367 in the ASTEROIDY Apple simulator.

Runs the actual app and requires its source renderer's COMPLETED Metal
command-buffer proof. Does not invent a screenshot or claim GLB/pixel parity.
No IPA is generated or signed. Fail closed on CoreSimulator timeouts.
"""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import time

from run_original_ios_simulator_capture import (
    PACKAGE,AppValidationFailed,EnvironmentUnavailable,
    run_command,available_devices
)

EXPECTED={
    "evidence":"actual-source-playership367-metal-command-buffer",
    "gpuCommandBufferCompleted":True,
    "pipeline":"sourceFighterTexturedPipeline431",
    "vertexCount":599997,
    "textureWidth":2048,
    "textureHeight":2048,
    "sourceGPU_SHA256":"932b0a9028404562cfd28db4174f51ded5977e23a90c15580566c69f9c41819a",
    "skinSHA256":"9ed4fe25c25566f40b0ca401185c6280aa219e2ecb186d160ed3254d14eeb111",
    "bundleID":PACKAGE,
    "simulatorTestOnly":True
}

def validate(proof):
    if not isinstance(proof,dict):
        raise AppValidationFailed("PlayerShip367 proof must be a JSON object")
    errors={key:(proof.get(key),value) for key,value in EXPECTED.items()
            if proof.get(key)!=value}
    if errors:
        raise AppValidationFailed("PlayerShip367 GPU evidence mismatches: "+str(errors))
    return True

def capture(app, reports, kind):
    if not app.is_dir() or app.suffix!=".app":
        raise AppValidationFailed("No real ASTEROIDY iOS .app")
    reports.mkdir(parents=True,exist_ok=True)
    devices=available_devices((kind,))
    (reports/"selected-devices.json").write_text(
        json.dumps(devices,indent=2),encoding="utf-8")
    _,name,udid,state=devices[kind]
    proof_name="ASTEROIDY_PlayerShip367_RenderProof.json"
    proof=None
    print(f"REAL {kind}: {name} {udid}",flush=True)
    try:
        if state!="Booted":
            run_command(["xcrun","simctl","boot",udid],45,
                        reports/f"{kind}_boot.txt")
        run_command(["xcrun","simctl","bootstatus",udid,"-b"],540,
                    reports/f"{kind}_bootstatus.txt")
        run_command(["xcrun","simctl","install",udid,str(app)],85,
                    reports/f"{kind}_install.txt")
        app_data=run_command(
            ["xcrun","simctl","get_app_container",udid,PACKAGE,"data"],45,
            reports/f"{kind}_container.txt").strip()
        proof_path=Path(app_data)/"Library"/"Caches"/proof_name
        screenshot=reports/f"{kind}_ship367_candidate.png"
        verified=reports/f"{kind}_VERIFIED_ASTEROIDY_source367.png"
        # Previous app installs and reused runner reports are not evidence.
        for stale in (proof_path,screenshot,verified):
            try:
                stale.unlink(missing_ok=True)
            except OSError as e:
                raise AppValidationFailed("Cannot clear stale evidence: "+str(e))
        env=os.environ.copy()
        env["SIMCTL_CHILD_ASTEROIDY_SHIP367_VERIFY"]="1"
        launched=run_command(
            ["xcrun","simctl","launch",udid,PACKAGE],50,
            reports/f"{kind}_launch.txt",env=env)
        if PACKAGE not in launched:
            raise AppValidationFailed("Actual source app did not launch")
        time.sleep(5)
        run_command(["xcrun","simctl","io",udid,"screenshot","--type=png",
                     str(screenshot)],55,reports/f"{kind}_screenshot.txt")
        if not screenshot.is_file() or screenshot.stat().st_size<1000:
            raise AppValidationFailed("Missing real Apple simulator screenshot")
        pixel=run_command(
            ["swift","Tools/verify_simulator_render_snapshot.swift",
             str(screenshot)],75,
            reports/f"{kind}_pixels.txt",check=False)
        if "PASS: authentic ASTEROIDY simulator screenshot" not in pixel:
            raise AppValidationFailed("Source app screenshot pixel gate failed")
        if not proof_path.is_file():
            raise AppValidationFailed("No completed source PlayerShip367 GPU proof")
        try:
            proof=json.loads(proof_path.read_text(encoding="utf-8"))
        except (OSError,ValueError) as e:
            raise AppValidationFailed("Unreadable source GPU proof: "+str(e))
        validate(proof)
        (reports/f"{kind}_GPU_source367_proof.json").write_text(
            json.dumps(proof,indent=2,sort_keys=True),encoding="utf-8")
        screenshot.rename(verified)
        print(f"PASS: {kind} original 599997-vertex PlayerShip367 GPU draw "
              "completed and real simulator screenshot saved",flush=True)
        print("LIMIT: does not establish model pixel visibility, correct on-screen size, "
              "full v568 visual parity, real iPhone, or real iPad",flush=True)
    finally:
        try:
            run_command(["xcrun","simctl","terminate",udid,PACKAGE],15,
                        check=False)
        except EnvironmentUnavailable:
            pass
        if state!="Booted":
            try:
                run_command(["xcrun","simctl","shutdown",udid],20,check=False)
            except EnvironmentUnavailable:
                pass

if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app",type=Path,required=True)
    parser.add_argument("--reports",type=Path,required=True)
    parser.add_argument("--only",choices=("IPHONE","IPAD"),default="IPHONE")
    args=parser.parse_args()
    try:
        capture(args.app,args.reports,args.only)
    except (EnvironmentUnavailable,AppValidationFailed,ValueError,OSError) as e:
        print("FAIL/INCONCLUSIVE: "+str(e),flush=True)
        raise SystemExit(1)

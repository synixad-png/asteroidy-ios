#!/usr/bin/env python3
"""Bounded actual ASTEROIDY iOS launch, screenshot and log verification.

Runs the REAL user's com.synixad.asteroidyios app from Xcode's
Debug-iphonesimulator build; never generates illustrative screenshots
or fake render output. Every external command has an explicit timeout
so a hung macOS CoreSimulator cannot stall CI for 45 minutes.

The two supported modes are:
  --self-test: exercise the fail-closed command timeout/error paths
  --app PATH --reports PATH: actual iPhone + iPad simulator startup

A CoreSimulator boot failure is ENVIRONMENT / INCONCLUSIVE: neither a
PASS nor proof of a rendering regression. A completed app screenshot
which is blank or lacks the original mesh log is a genuine failed test.
No IPA is created.
"""
import argparse
import json
import os
import signal
from pathlib import Path
import shlex
import subprocess
import sys
import time

PACKAGE = "com.synixad.asteroidyios"

# Original v568 PC 4311 GPU mesh + glTF image, not a guessed asset.
# The app writes this JSON only after GPU command-buffer completion
# in the *actual* sourceVanguardTexturedToonFragment431 path.
EXPECTED_GPU_PROOF={
    "evidence":"actual-source-vanguard-metal-command-buffer",
    "gpuCommandBufferCompleted":True,
    "pipeline":"sourceFighterTexturedPipeline431",
    "vertexCount":194427,
    "textureWidth":2048,
    "textureHeight":2048,
    "meshSHA256":"f5d6d0107437fa54c3e8505f9adfbf6143cc877cb970eef687603609e26f9f4a",
    "skinSHA256":"2945f711a6b559bfb5fdfb79750a2f2f77e2071aa5f3f4173eb450bce81b8b95",
    "bundleID":PACKAGE,
    "simulatorTestOnly":True
}

def validate_render_proof(proof):
    if not isinstance(proof,dict):
        raise AppValidationFailed("original Vanguard GPU proof is not JSON object")
    mismatches={
        key:(proof.get(key),expected)
        for key,expected in EXPECTED_GPU_PROOF.items()
        if proof.get(key)!=expected
    }
    if mismatches:
        raise AppValidationFailed(
            f"Original Vanguard431 GPU command buffer proof mismatches: {mismatches}")
    return True

class EnvironmentUnavailable(RuntimeError): pass
class AppValidationFailed(RuntimeError): pass

def run_command(args, timeout, stdout_path=None, check=True, env=None):
    command=list(map(str,args))
    # macOS simctl may leave descendants holding the parent's STDOUT
    # pipe. subprocess.run(timeout=...) kills only the parent and can
    # hang forever draining that pipe. Own the ENTIRE process group.
    try:
        proc=subprocess.Popen(command,stdin=subprocess.DEVNULL,
                              stdout=subprocess.PIPE,stderr=subprocess.STDOUT,
                              text=True,errors="replace",start_new_session=True,env=env)
        try:
            output,_=proc.communicate(timeout=timeout)
        except subprocess.TimeoutExpired as exc:
            try:
                os.killpg(proc.pid,signal.SIGKILL)
            except ProcessLookupError:
                pass
            try:
                output,_=proc.communicate(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                output=""
            msg=f"ENVIRONMENT TIMEOUT after {timeout}s: {shlex.join(command)}"
            if stdout_path is not None:
                Path(stdout_path).write_text(msg+"\n"+(output or ""),
                                             encoding="utf-8")
            raise EnvironmentUnavailable(msg) from exc
    except OSError as exc:
        raise EnvironmentUnavailable(
            f"ENVIRONMENT SPAWN ERROR: {shlex.join(command)}: {exc}") from exc
    if stdout_path is not None:
        Path(stdout_path).write_text(output,encoding="utf-8")
    if check and proc.returncode != 0:
        raise EnvironmentUnavailable(
            f"ENVIRONMENT COMMAND FAILED rc={proc.returncode}: "
            f"{shlex.join(command)}\n{output[-1600:]}")
    return output

def available_devices(kinds):
    raw=run_command(["xcrun","simctl","list","-j","devices","available"],60)
    data=json.loads(raw)
    found=[]
    for runtime,items in data.get("devices",{}).items():
        if ".iOS-" not in runtime: continue
        for d in items:
            if d.get("isAvailable",True):
                found.append((runtime,d["name"],d["udid"],d.get("state","")))
    result={}
    for kind,prefix in (("IPHONE","iPhone"),("IPAD","iPad")):
        if kind not in kinds:
            continue
        matches=[d for d in found if d[1].startswith(prefix)]
        if not matches:
            raise EnvironmentUnavailable(
                "ENVIRONMENT: no installed iOS "+prefix+" simulator")
        # Prefer an already booted device to avoid unnecessary startup.
        matches.sort(key=lambda d:(
            d[3]!="Booted",d[0],d[1]))
        result[kind]=matches[0]
    return result

def capture(app:Path,reports:Path,kinds):
    if not app.is_dir() or app.suffix!=".app":
        raise AppValidationFailed("Compiled original ASTEROIDY .app missing")
    reports.mkdir(parents=True,exist_ok=True)
    devices=available_devices(kinds)
    (reports/"selected-devices.json").write_text(
        json.dumps(devices,indent=2),encoding="utf-8")
    for kind,(runtime,name,udid,state) in devices.items():
        start=time.monotonic()
        print(f"REAL {kind}: selected {name} {runtime} {udid} state={state}",
              flush=True)
        try:
            if state!="Booted":
                run_command(["xcrun","simctl","boot",udid],45,
                    reports/f"{kind}_boot.txt")
            run_command(["xcrun","simctl","bootstatus",udid,"-b"],540,
                reports/f"{kind}_bootstatus.txt")
            print(f"REAL {kind}: CoreSimulator boot completed",flush=True)
            run_command(["xcrun","simctl","install",udid,str(app)],85,
                reports/f"{kind}_install.txt")
            # Clear proof from any previous install/launch. A stale JSON
            # must NEVER certify this launch's screenshot as a GPU draw.
            container=run_command(
                ["xcrun","simctl","get_app_container",udid,PACKAGE,"data"],
                45,reports/f"{kind}_app-container.txt").strip()
            proof_path=(Path(container)/"Library"/"Caches"/
                "ASTEROIDY_Vanguard431_RenderProof.json")
            try:
                proof_path.unlink(missing_ok=True)
            except OSError as exc:
                raise AppValidationFailed(
                    f"{kind}: cannot clear prior GPU render proof: {exc}")
            # Simulator-only flag: the game itself will write proof
            # AFTER its real Vanguard431 draw's Metal command buffer
            # successfully completes. Normal user's iOS app unchanged.
            simulator_env=os.environ.copy()
            simulator_env["SIMCTL_CHILD_ASTEROIDY_RENDER_VERIFY"]="1"
            output=run_command(
                ["xcrun","simctl","launch",udid,PACKAGE],50,
                reports/f"{kind}_launch.txt",env=simulator_env)
            if PACKAGE not in output:
                raise AppValidationFailed(
                    f"{kind}: Simulator launch output lacks {PACKAGE}: {output}")
            print(f"REAL {kind}: genuine app launched",flush=True)
            time.sleep(5)
            picture=reports/f"{kind}_candidate_unverified.png"
            run_command(
                ["xcrun","simctl","io",udid,"screenshot",
                 "--type=png",str(picture)],55,
                reports/f"{kind}_screenshot.txt")
            if not picture.is_file() or picture.stat().st_size<1000:
                raise AppValidationFailed(f"{kind}: no genuine screenshot")
            pixel_check=run_command(
                ["swift","Tools/verify_simulator_render_snapshot.swift",
                 str(picture)],75,
                reports/f"{kind}_real_pixels.txt",check=False)
            if "PASS: authentic ASTEROIDY simulator screenshot" not in pixel_check:
                raise AppValidationFailed(f"{kind}: scene pixel evidence missing")
            # The Apple unified-log database on hosted simulators can
            # fail to expose NSLog from an actual launched app. Query a
            # test-only file written by the source renderer ONLY when
            # the real GPU command buffer finishes. Independent of
            # logger permissions and the screenshot's apparent content.
            if not proof_path.is_file():
                raise AppValidationFailed(
                    f"{kind}: no proof of completed original textured "
                    "Vanguard431 GPU draw inside its real app sandbox")
            try:
                proof=json.loads(proof_path.read_text(encoding="utf-8"))
            except (OSError,ValueError) as exc:
                raise AppValidationFailed(
                    f"{kind}: corrupt original Vanguard431 GPU draw proof: {exc}")
            validate_render_proof(proof)
            (reports/f"{kind}_GPU_source431_proof.json").write_text(
                json.dumps(proof,indent=2,sort_keys=True),encoding="utf-8")
            verified=reports/f"{kind}_VERIFIED_ASTEROIDY_source431.png"
            picture.rename(verified)
            print(f"PASS: {kind} real pixels and GPU-completed "
                  f"original 194427-vertex textured draw, "
                  f"elapsed={time.monotonic()-start:.1f}s",flush=True)
        finally:
            # Never turn a cleanup problem into a false render pass.
            try:
                run_command(["xcrun","simctl","terminate",udid,PACKAGE],
                            15,check=False)
            except EnvironmentUnavailable:
                pass
            if state!="Booted":
                try:
                    run_command(["xcrun","simctl","shutdown",udid],
                                20,check=False)
                except EnvironmentUnavailable:
                    pass
    tested = " and ".join(kinds)
    print(f"PASS: genuine original ASTEROIDY rendered on selected Apple simulator family: {tested}")
    print("LIMIT: simulator render does not prove physical device GPU/FPS")

def self_test():
    # Real bounded OS child: test success, failure, and deadline paths
    # without requiring CoreSimulator or a Mac to run.
    success=run_command([sys.executable,"-c","print('RESULT_OK')"],5)
    assert "RESULT_OK" in success
    try:
        run_command([sys.executable,"-c","import time;time.sleep(10)"],0.2)
        raise AssertionError("Timeout guard failed")
    except EnvironmentUnavailable as exc:
        assert "TIMEOUT" in str(exc)
    # Forked child also inherits STDOUT: the old subprocess.run()
    # implementation could hang draining the pipe after parent timeout.
    # The process-group implementation must terminate both quickly.
    try:
        run_command([sys.executable,"-c",
            "import subprocess,sys,time;"
            "subprocess.Popen([sys.executable,'-c','import time;time.sleep(10)']);"
            "time.sleep(10)"],0.2)
        raise AssertionError("Inherited-pipe process-group guard failed")
    except EnvironmentUnavailable as exc:
        assert "TIMEOUT" in str(exc)
    try:
        run_command([sys.executable,"-c","raise SystemExit(7)"],5)
        raise AssertionError("Exit-code guard failed")
    except EnvironmentUnavailable as exc:
        assert "rc=7" in str(exc)
    print("PASS: real subprocess timeout, nonzero exit, normal return")
    print("LIMIT: self-test does not start an Apple simulator")

if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test",action="store_true")
    parser.add_argument("--app",type=Path)
    parser.add_argument("--reports",type=Path,default=Path("reports"))
    parser.add_argument("--only",choices=["IPHONE","IPAD","BOTH"],
                        default="BOTH")
    args=parser.parse_args()
    try:
        if args.self_test:
            self_test()
        elif args.app:
            kinds=("IPHONE","IPAD") if args.only=="BOTH" else (args.only,)
            capture(args.app.resolve(),args.reports.resolve(),kinds)
        else:
            parser.error("--self-test or --app is required")
    except EnvironmentUnavailable as exc:
        print(f"INCONCLUSIVE ENVIRONMENT: {exc}",file=sys.stderr)
        raise SystemExit(75)
    except (AppValidationFailed,ValueError) as exc:
        print(f"FAIL VERIFIED APP: {exc}",file=sys.stderr)
        raise SystemExit(1)

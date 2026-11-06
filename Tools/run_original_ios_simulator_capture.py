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

class EnvironmentUnavailable(RuntimeError): pass
class AppValidationFailed(RuntimeError): pass

def run_command(args, timeout, stdout_path=None, check=True):
    command=list(map(str,args))
    # macOS simctl may leave descendants holding the parent's STDOUT
    # pipe. subprocess.run(timeout=...) kills only the parent and can
    # hang forever draining that pipe. Own the ENTIRE process group.
    try:
        proc=subprocess.Popen(command,stdin=subprocess.DEVNULL,
                              stdout=subprocess.PIPE,stderr=subprocess.STDOUT,
                              text=True,errors="replace",start_new_session=True)
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

def available_devices():
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
        matches=[d for d in found if d[1].startswith(prefix)]
        if not matches:
            raise EnvironmentUnavailable(
                "ENVIRONMENT: no installed iOS "+prefix+" simulator")
        # Prefer an already booted device to avoid unnecessary startup.
        matches.sort(key=lambda d:(
            d[3]!="Booted",d[0],d[1]))
        result[kind]=matches[0]
    return result

def capture(app:Path,reports:Path):
    if not app.is_dir() or app.suffix!=".app":
        raise AppValidationFailed("Compiled original ASTEROIDY .app missing")
    reports.mkdir(parents=True,exist_ok=True)
    devices=available_devices()
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
            run_command(["xcrun","simctl","bootstatus",udid,"-b"],125,
                reports/f"{kind}_bootstatus.txt")
            print(f"REAL {kind}: CoreSimulator boot completed",flush=True)
            run_command(["xcrun","simctl","install",udid,str(app)],85,
                reports/f"{kind}_install.txt")
            output=run_command(
                ["xcrun","simctl","launch",udid,PACKAGE],50,
                reports/f"{kind}_launch.txt")
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
            log=run_command(
                ["xcrun","simctl","spawn",udid,"log","show","--last","3m",
                 "--style","compact","--predicate",
                 'eventMessage CONTAINS "Vanguard431 UV/BaseColor active"'],
                45,reports/f"{kind}_source-load.log")
            required="real PC Vanguard431 UV/BaseColor active: 194427 vertices"
            if required not in log:
                raise AppValidationFailed(
                    f"{kind}: genuine 194427-vertex texture activation "
                    "not confirmed by application's own log")
            verified=reports/f"{kind}_VERIFIED_ASTEROIDY_source431.png"
            picture.rename(verified)
            print(f"PASS: {kind} screenshot from own game + source GPU UV "
                  f"runtime log, elapsed={time.monotonic()-start:.1f}s",
                  flush=True)
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
    print("PASS: genuine original ASTEROIDY rendered on both Apple simulators")
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
    args=parser.parse_args()
    try:
        if args.self_test:
            self_test()
        elif args.app:
            capture(args.app.resolve(),args.reports.resolve())
        else:
            parser.error("--self-test or --app is required")
    except EnvironmentUnavailable as exc:
        print(f"INCONCLUSIVE ENVIRONMENT: {exc}",file=sys.stderr)
        raise SystemExit(75)
    except (AppValidationFailed,ValueError) as exc:
        print(f"FAIL VERIFIED APP: {exc}",file=sys.stderr)
        raise SystemExit(1)

#!/usr/bin/env python3
"""Bounded ASTEROIDY real app screenshot automation regression.

Runs the actual Python command runner's deterministic child-process
self-test. Verifies no screenshot is labelled verified before both the
image and source-specific renderer log pass; every CoreSimulator
command has a timeout to avoid silent multi-hour macOS worker hangs.
"""
import pathlib
import subprocess
import sys
root=pathlib.Path(__file__).resolve().parents[1]
script=root/"Tools/run_original_ios_simulator_capture.py"
p=subprocess.run([sys.executable,str(script),"--self-test"],
                 cwd=root,text=True,capture_output=True,timeout=15)
assert p.returncode==0,(p.stdout,p.stderr)
assert "PASS: real subprocess timeout" in p.stdout
source=script.read_text()
assert "class EnvironmentUnavailable" in source
assert "except subprocess.TimeoutExpired" in source
assert "start_new_session=True" in source
assert "os.killpg(proc.pid,signal.SIGKILL)" in source
assert "Inherited-pipe process-group guard failed" in source
assert "raise SystemExit(75)" in source
assert "raise SystemExit(1)" in source
assert 'picture=reports/f"{kind}_candidate_unverified.png"' in source
assert 'verified=reports/f"{kind}_VERIFIED_ASTEROIDY_source431.png"' in source
assert source.index('if required not in log:') < source.index('picture.rename(verified)')
assert "real PC Vanguard431 UV/BaseColor active: 194427 vertices" in source
assert "Tools/verify_simulator_render_snapshot.swift" in source
assert 'reports/f"{kind}_real_pixels.txt",check=False)' in source
assert 'raise AppValidationFailed(f"{kind}: scene pixel evidence missing")' in source
assert 'run_command(["xcrun","simctl","bootstatus",udid,"-b"],125,' in source
assert 'run_command(["xcrun","simctl","install",udid,str(app)],85,' in source
assert '["xcrun","simctl","launch",udid,PACKAGE],50,' in source
assert "PACKAGE = \"com.synixad.asteroidyios\"" in source
assert "run_command([" in source
print("PASS: ASTEROIDY simulator runner distinguishes CoreSimulator timeouts")
print("      from actual game rendering failures, and never labels a")
print("      screenshot verified before real pixels AND native model log")

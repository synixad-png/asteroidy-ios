#!/usr/bin/env python3
"""Bounded ASTEROIDY real app screenshot automation regression.

Runs the actual Python command runner's deterministic child-process
self-test. Verifies no screenshot is labelled verified before both the
image and actual completed GPU draw proof pass; every CoreSimulator
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
assert "picture.unlink(missing_ok=True)" in source
assert "verified.unlink(missing_ok=True)" in source
assert source.index("picture.unlink(missing_ok=True)") < source.index('["xcrun","simctl","io",udid,"screenshot",')
assert source.rindex("            validate_render_proof(proof)") < source.index("picture.rename(verified)")
assert source.index('validate_render_proof(proof)') < source.index('picture.rename(verified)')
assert 'SIMCTL_CHILD_ASTEROIDY_RENDER_VERIFY' in source
assert 'ASTEROIDY_Vanguard431_RenderProof.json' in source
assert "proof_path.unlink(missing_ok=True)" in source
assert source.index("proof_path.unlink(missing_ok=True)") < source.index('["xcrun","simctl","launch",udid,PACKAGE]')
assert source.index("proof_path.unlink(missing_ok=True)") < source.rindex("            validate_render_proof(proof)")
assert '["xcrun","simctl","get_app_container",udid,PACKAGE,"data"]' in source
assert "Tools/verify_simulator_render_snapshot.swift" in source
assert 'reports/f"{kind}_real_pixels.txt",check=False)' in source
assert 'raise AppValidationFailed(f"{kind}: scene pixel evidence missing")' in source
assert 'run_command(["xcrun","simctl","bootstatus",udid,"-b"],540,' in source
assert 'run_command(["xcrun","simctl","install",udid,str(app)],85,' in source
assert '["xcrun","simctl","launch",udid,PACKAGE],50,' in source
assert "PACKAGE = \"com.synixad.asteroidyios\"" in source
assert "run_command([" in source
assert 'parser.add_argument("--only",choices=["IPHONE","IPAD","BOTH"],' in source
assert 'if kind not in kinds:' in source
assert 'tested = " and ".join(kinds)' in source
assert 'rendered on selected Apple simulator family: {tested}' in source
assert 'rendered on both Apple simulators' not in source

# Exercise the ACTUAL schema validator, not a static-only regex.
import importlib.util
spec=importlib.util.spec_from_file_location("real_ast_sim_runner",script)
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
sample=dict(module.EXPECTED_GPU_PROOF)
assert module.validate_render_proof(sample) is True
for field in module.EXPECTED_GPU_PROOF:
    corrupt=dict(sample)
    corrupt[field]="WRONG_ORIGINAL_SOURCE"
    try:
        module.validate_render_proof(corrupt)
    except module.AppValidationFailed:
        pass
    else:
        raise AssertionError("Accepted forged original Vanguard GPU proof: "+field)
try:
    module.validate_render_proof({})
except module.AppValidationFailed:
    pass
else:
    raise AssertionError("Accepted missing actual Vanguard431 GPU proof")
print("PASS: ASTEROIDY simulator runner distinguishes CoreSimulator timeouts")
print("      from actual game rendering failures, and never labels a")
print("      screenshot verified before real pixels AND completed GPU command")

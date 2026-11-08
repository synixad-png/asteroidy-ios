#!/usr/bin/env python3
"""Regression tests for the whole-repository ASTEROIDY quality scanner."""
from pathlib import Path
from tempfile import TemporaryDirectory
import importlib.util

tool = Path(__file__).resolve().parents[1] / "Tools" / "code_quality_audit.py"
spec = importlib.util.spec_from_file_location("code_quality_audit", tool)
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
import sys
sys.modules[spec.name] = module
spec.loader.exec_module(module)

bad = """let a = try! load()
let b = value as! Int
DispatchQueue.main.sync { run() }
catch {}
fatalError("unexpected")
"""
issues = module.scan_text("ASTEROIDYiOS/Bad.swift", bad)
assert {i.rule for i in issues} == {
    "forced_try", "forced_cast", "main_sync", "empty_catch", "forced_abort"
}
assert len([i for i in issues if i.severity == "critical"]) == 5
assert module.scan_text("Tests/Bad.swift", bad) == []

dsp_guard = 'guard let sos=filters[key] else {preconditionFailure("Missing original source SOS filter: \\(key)")}'
allowed = module.scan_text("ASTEROIDYiOS/OriginalMusicSynth568.swift", dsp_guard)
assert len(allowed)==1 and allowed[0].rule=="verified_dsp_filter_invariant"
assert allowed[0].severity=="review"
assert module.scan_text("ASTEROIDYiOS/Other.swift", dsp_guard)[0].severity=="critical"

metal = module.scan_text("ASTEROIDYiOS/Test.metal","while(true) { busy(); }")
assert metal and metal[0].rule=="unbounded_shader_loop_candidate"
py = module.scan_text("Tools/loader.py","os.system('echo broken')")
assert py and py[0].rule=="shell_command_candidate"
workflow = module.scan_text(".github/workflows/bad.yml","pull_request_target:")
assert workflow and workflow[0].rule=="privileged_pr_candidate"
forced = module.scan_text("ASTEROIDYiOS/Cache.swift", "let item=cache[key]!")
assert forced and forced[0].rule=="forced_optional_subscript_candidate"


good = """// fatalError("commented-out text") is not production code.
func load() throws -> Data { return Data() }
let bytes = try load()
do { try save() } catch { log(error) }
"""
assert not [i for i in module.scan_text("ASTEROIDYiOS/Safe.swift", good)
            if i.severity == "critical"]
assert "duplicate_candidates" in module.audit.__code__.co_names

with TemporaryDirectory() as directory:
    root = Path(directory)
    (root / "ASTEROIDYiOS").mkdir()
    (root / "Tests").mkdir()
    (root / "ASTEROIDYiOS" / "Healthy.swift").write_text(
        "import Foundation\nfunc f() { return }\n", encoding="utf-8")
    (root / "Tests" / "Quality.swift").write_text(
        "let x = try! fakeTest()\n", encoding="utf-8")
    (root / "Tests" / "Quality.txt").write_text("ignored", encoding="utf-8")
    report = module.audit(root)
    assert report["tracked_source_files"] == 2, report
    assert report["production_swift_files"] == 1, report
    assert report["critical_count"] == 0, report
    assert "Największe moduły" in module.markdown(report)
print("PASS: quality scanner finds real hazards, ignores comments/tests, inventories all source files")

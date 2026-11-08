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

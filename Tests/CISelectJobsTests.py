#!/usr/bin/env python3
"""Tests for Tools/ci_select_jobs.py and .github/ci-jobs.json.

1. Path globs follow GitHub Actions path filters.
2. Events pick the right jobs; unknown changes run every allowed job.
3. Changed files come from a real git diff (push two-dot, PR three-dot).
4. Every job in a merged workflow has one rule, and every rule has a job.
"""
from __future__ import annotations

import importlib.util
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "ci_select_jobs", ROOT / "Tools" / "ci_select_jobs.py")
assert spec is not None and spec.loader is not None
sel = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = sel
spec.loader.exec_module(sel)


def glob(pattern: str, name: str) -> bool:
    return bool(sel.glob_regex(pattern).match(name))


# 1. GitHub path glob rules
assert glob("ASTEROIDYiOS/*.swift", "ASTEROIDYiOS/App.swift")
assert not glob("ASTEROIDYiOS/*.swift", "ASTEROIDYiOS/Assets/A.swift")
assert glob("ASTEROIDYiOS/**", "ASTEROIDYiOS/Assets/hud/a.png")
assert glob("**/*.swift", "App.swift") and glob("**/*.swift", "a/b/App.swift")
assert glob("Tests/**/*.py", "Tests/X.py") and glob("Tests/**/*.py", "Tests/a/X.py")
assert not glob("Tests/*.py", "Tests/a/X.py")
assert not glob("project.yml", "project.yml.bak")
assert not glob("project.yml", "x/project.yml")
assert not glob("Tools/a.py", "Tools/aXpy")
assert glob("ASTEROIDY_v568_*_z_04.zip", "ASTEROIDY_v568_CZESC_1_z_04.zip")
for bad in ("a?.py", "[ab].py", "a+.py"):
    try:
        sel.glob_regex(bad)
    except ValueError:
        pass
    else:
        raise AssertionError(f"unsupported glob accepted: {bad}")
both = ["ASTEROIDYiOS/**", "!ASTEROIDYiOS/Assets/**"]
assert sel.matches(both, ["ASTEROIDYiOS/App.swift"])
assert not sel.matches(both, ["ASTEROIDYiOS/Assets/a.png"])
assert sel.matches(both, ["ASTEROIDYiOS/Assets/a.png", "ASTEROIDYiOS/App.swift"])
assert sel.matches(["!x/**", "x/**"], ["x/a"]), "last matching pattern wins"
assert not sel.matches(["Tests/*.py"], [])

# 2. Event rules
rules = {
    "a": {"from": "old-a", "push": "always", "pull_request": None, "manual": True},
    "b": {"from": "old-b", "push": ["Tests/*.py"], "pull_request": ["Tests/*.py"],
          "manual": True},
    "c": {"from": "old-c", "push": None, "pull_request": None, "manual": True},
    "d": {"from": "old-b", "push": None, "pull_request": ["ASTEROIDYiOS/**"],
          "manual": False},
}
assert sel.select(rules, "push", ["README.md"]) == ["a"]
assert sel.select(rules, "push", ["Tests/x.py"]) == ["a", "b"]
assert sel.select(rules, "push", None) == ["a", "b"], "unknown changes: fail open"
assert sel.select(rules, "pull_request", ["ASTEROIDYiOS/App.swift"]) == ["d"]
assert sel.select(rules, "pull_request", None) == ["b", "d"]
assert sel.select(rules, "pull_request", []) == []
assert sel.select(rules, "workflow_dispatch", [], "all") == ["a", "b", "c"]
assert sel.select(rules, "workflow_dispatch", [], "old-b") == ["b"]
assert sel.select(rules, "workflow_dispatch", [], "nothing") == []
assert sel.select(rules, "schedule", []) == []


# 3. Changed files from git
def git(repo: Path, *args: str) -> str:
    return subprocess.run(
        ["git", "-c", "user.name=ci", "-c", "user.email=ci@example.invalid",
         "-c", "commit.gpgsign=false", *args],
        cwd=repo, check=True, capture_output=True, text=True).stdout.strip()


def commit(repo: Path, name: str, message: str) -> str:
    target = repo / name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(message + "\n", encoding="utf-8")
    git(repo, "add", "-A")
    git(repo, "commit", "-q", "-m", message)
    return git(repo, "rev-parse", "HEAD")


start = Path.cwd()
with TemporaryDirectory() as tmp:
    repo = Path(tmp)
    git(repo, "init", "-q", "-b", "main")
    first = commit(repo, "README.md", "one")
    second = commit(repo, "Tests/x.py", "two")
    git(repo, "checkout", "-q", "-b", "topic", first)
    topic = commit(repo, "ASTEROIDYiOS/App.swift", "three")
    os.chdir(repo)
    try:
        push = {"BEFORE": first, "AFTER": second}
        assert sel.changed_files("push", push) == ["Tests/x.py"]
        assert sel.changed_files("push", {"BEFORE": sel.ZERO_SHA, "AFTER": second}) is None
        assert sel.changed_files("push", {"BEFORE": "f" * 40, "AFTER": second}) is None
        pr = {"PR_BASE": second, "PR_HEAD": topic}
        assert sel.changed_files("pull_request", pr) == ["ASTEROIDYiOS/App.swift"], \
            "PR diff starts at the merge base, like GitHub"
        assert sel.changed_files("pull_request", {"PR_BASE": "", "PR_HEAD": topic}) is None
        assert sel.changed_files("workflow_dispatch", {}) == []
        out = repo / "github_output.txt"
        env = dict(os.environ, EVENT="push", BEFORE=first, AFTER=second,
                   GITHUB_OUTPUT=str(out))
        config = repo / "rules.json"
        config.write_text(json.dumps({"x.yml": rules}), encoding="utf-8")
        result = subprocess.run(
            [sys.executable, str(ROOT / "Tools" / "ci_select_jobs.py"),
             "--workflow", "x.yml", "--config", str(config)],
            env=env, capture_output=True, text=True, check=True)
        assert "jobs= a b \n" in result.stdout, result.stdout
        assert out.read_text(encoding="utf-8") == "jobs= a b \n"
    finally:
        os.chdir(start)

# 4. ci-jobs.json <-> workflow files
JOB = re.compile(r"^  ([A-Za-z0-9_-]+):\s*$")
config = json.loads((ROOT / ".github" / "ci-jobs.json").read_text(encoding="utf-8"))
workflow_dir = ROOT / ".github" / "workflows"
users = sorted(p.name for p in workflow_dir.glob("*.yml")
               if "Tools/ci_select_jobs.py" in p.read_text(encoding="utf-8"))
assert sorted(config) == users, (sorted(config), users)
for name, file_rules in config.items():
    text = (workflow_dir / name).read_text(encoding="utf-8")
    assert f"python3 Tools/ci_select_jobs.py --workflow {name}\n" in text, name
    lines = text.split("\n")
    jobs: dict[str, dict[str, str]] = {}
    current = None
    for line in lines[lines.index("jobs:") + 1:]:
        found = JOB.match(line)
        if found:
            current = found.group(1)
            assert current not in jobs, (name, current)
            jobs[current] = {}
        elif current:
            for key in ("needs", "if"):
                if line.startswith(f"    {key}:"):
                    jobs[current][key] = line.split(":", 1)[1].strip()
    assert "select" in jobs and "needs" not in jobs["select"], name
    ids = set(jobs) - {"select"}
    assert ids == set(file_rules), (name, sorted(ids ^ set(file_rules)))
    for job in ids:
        needs = jobs[job].get("needs", "")
        assert needs == "select" or needs.startswith("[select, "), (name, job, needs)
        gate = f"${{{{ contains(needs.select.outputs.jobs, ' {job} ')"
        assert jobs[job].get("if", "").startswith(gate), (name, job)
    choices, in_options = [], False
    for line in lines:
        if line.strip() == "options:":
            in_options = True
        elif in_options and line.startswith("          - "):
            choices.append(line.split("- ", 1)[1].strip())
        else:
            in_options = False
    has_pr = "\n  pull_request:" in text
    for job, rule in file_rules.items():
        assert set(rule) == {"from", "push", "pull_request", "manual"}, (name, job)
        for event in ("push", "pull_request"):
            value = rule[event]
            assert value is None or value == "always" or (
                isinstance(value, list) and value
                and all(isinstance(p, str) and p for p in value)), (name, job, event)
            if isinstance(value, list):
                for pattern in value:
                    sel.glob_regex(pattern.lstrip("!"))
                    moved = re.fullmatch(r"\.github/workflows/(.+)", pattern)
                    assert not moved or (workflow_dir / moved.group(1)).is_file(), \
                        (name, job, pattern)
        if rule["pull_request"] is not None:
            assert has_pr, (name, job, "pull_request rule without a trigger")
        if rule["manual"]:
            assert rule["from"] in choices, (name, job, rule["from"])
    for choice in choices:
        assert choice == "all" or any(
            r["from"] == choice and r["manual"] for r in file_rules.values()), (name, choice)

print(f"CI job selector: OK ({sum(len(r) for r in config.values())} jobs in "
      f"{len(config)} workflows)")

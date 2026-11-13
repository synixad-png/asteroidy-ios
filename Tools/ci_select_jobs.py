#!/usr/bin/env python3
"""Pick the CI jobs that run in one workflow file.

source-tests.yml, mac-tests.yml and build-ipa.yml each hold jobs that used
to live in separate workflow files with their own triggers. Every job in
them `needs: select` and runs only if this script lists its id.

.github/ci-jobs.json maps workflow file -> job id -> rule:
  from          old workflow file name without .yml; a manual run picks by it
  push          "always", null, or a list of path globs (push to main)
  pull_request  "always", null, or a list of path globs
  manual        true if a manual run (workflow_dispatch) may start the job

Path globs follow GitHub Actions path filters: `*` does not cross `/`,
`**` does, and a leading `!` removes earlier matches. If the changed files
cannot be listed, every job allowed for the event runs (fail open, never
skip a check silently).

Output: `jobs= id1 id2 ` (space padded, so a workflow can test
`contains(needs.select.outputs.jobs, ' id1 ')`), printed and appended to
$GITHUB_OUTPUT when it is set.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

ZERO_SHA = "0" * 40


def glob_regex(pattern: str) -> re.Pattern[str]:
    if re.search(r"[?+\[\]]", pattern):
        raise ValueError(f"unsupported path glob: {pattern}")
    out, i = [], 0
    while i < len(pattern):
        if pattern.startswith("**/", i):
            out.append("(?:.*/)?")
            i += 3
        elif pattern.startswith("**", i):
            out.append(".*")
            i += 2
        elif pattern[i] == "*":
            out.append("[^/]*")
            i += 1
        else:
            out.append(re.escape(pattern[i]))
            i += 1
    return re.compile("".join(out) + r"\Z")


def matches(paths: list[str], changed: list[str]) -> bool:
    rules = [(p.startswith("!"), glob_regex(p.lstrip("!"))) for p in paths]
    for name in changed:
        keep = False
        for negated, regex in rules:
            if regex.match(name):
                keep = not negated
        if keep:
            return True
    return False


def changed_files(event: str, env: dict[str, str]) -> list[str] | None:
    if event == "push":
        before, after = env.get("BEFORE", ""), env.get("AFTER", "")
        if not before or before == ZERO_SHA or not after:
            return None
        spec = [before, after]
    elif event == "pull_request":
        base, head = env.get("PR_BASE", ""), env.get("PR_HEAD", "")
        if not base or not head:
            return None
        spec = [f"{base}...{head}"]
    else:
        return []
    result = subprocess.run(
        ["git", "diff", "--name-only", "--no-renames", *spec],
        capture_output=True, text=True)
    if result.returncode != 0:
        print(f"select: git diff failed, running every allowed job: "
              f"{result.stderr.strip()}", file=sys.stderr)
        return None
    return [line for line in result.stdout.splitlines() if line]


def select(rules: dict[str, dict], event: str, changed: list[str] | None,
           run: str = "all") -> list[str]:
    picked = []
    for job, rule in rules.items():
        if event == "workflow_dispatch":
            if rule.get("manual") and run in ("all", rule["from"]):
                picked.append(job)
            continue
        if event not in ("push", "pull_request"):
            continue
        trigger = rule.get(event)
        if trigger is None:
            continue
        if trigger == "always" or changed is None or matches(trigger, changed):
            picked.append(job)
    return picked


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--workflow", required=True,
                        help="workflow file name, e.g. mac-tests.yml")
    parser.add_argument("--config", default=".github/ci-jobs.json")
    args = parser.parse_args(argv)
    config = json.loads(Path(args.config).read_text(encoding="utf-8"))
    rules = config[args.workflow]
    event = os.environ.get("EVENT", "")
    changed = changed_files(event, dict(os.environ))
    picked = select(rules, event, changed, os.environ.get("RUN") or "all")
    line = "jobs= " + " ".join(picked) + " "
    print(f"select: event={event} changed="
          f"{'unknown' if changed is None else len(changed)} "
          f"picked={len(picked)}/{len(rules)}")
    print(line)
    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with open(output, "a", encoding="utf-8") as handle:
            handle.write(line + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())

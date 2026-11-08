#!/usr/bin/env python3
"""ASTEROIDY iOS: reproducible whole-repository static quality inventory.

No network, third-party packages, app imports, or asset mutation.
This is a static risk finder; it does not assert that every flagged line is a bug.
Use --gate for narrowly defined *confirmed anti-patterns* in production Swift.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

CODE_SUFFIXES = {".swift", ".metal", ".c", ".cs", ".cpp", ".m",
                 ".mm", ".h", ".py", ".yml", ".yaml", ".json", ".sh"}
PRODUCTION_ROOT = "ASTEROIDYiOS/"
RULES = {
    # These are source-level release gates, not stylistic preferences.
    "forced_try": (r"\btry!", "critical"),
    "forced_cast": (r"\bas!", "critical"),
    "forced_abort": (r"\b(?:fatalError|preconditionFailure)\s*\(", "critical"),
    "main_sync": (r"\bDispatchQueue\.main\.sync\b", "critical"),
    "empty_catch": (r"\bcatch\s*\{\s*\}", "critical"),
    # Warnings require evidence before editing the line.
    "optional_try": (r"\btry\?", "review"),
    "quality_debt_marker": (r"\b(?:TODO|FIXME|HACK|placeholder|temporary|workaround|stub)\b",
                            "review"),
    "main_async": (r"\bDispatchQueue\.main\.async\b", "review"),
    "log_statement": (r"\b(?:NSLog|print)\s*\(", "review"),
    "hot_gpu_allocation_candidate": (
        r"\b(?:makeBuffer|makeTexture|makeRenderPipelineState)\s*\(", "review"),
}
COMPILED = {k: (re.compile(v[0], re.IGNORECASE if k == "quality_debt_marker" else 0), v[1])
            for k, v in RULES.items()}


@dataclass(frozen=True)
class Finding:
    rule: str
    severity: str
    path: str
    line: int
    excerpt: str


def strip_swift_line_comment(line: str) -> str:
    # Strip only clear // comments; it does not claim to parse the Swift
    # grammar. URLs inside strings are not expected in production API calls.
    return line.split("//", 1)[0]


def scan_text(path: str, content: str) -> list[Finding]:
    issues: list[Finding] = []
    production_swift = path.startswith(PRODUCTION_ROOT) and path.endswith(".swift")
    metal = path.startswith(PRODUCTION_ROOT) and path.endswith(".metal")
    python_tool = path.startswith("Tools/") and path.endswith(".py")
    workflow = path.startswith(".github/workflows/") and path.endswith((".yml", ".yaml"))
    if not any((production_swift, metal, python_tool, workflow)):
        return issues
    for number, raw in enumerate(content.splitlines(), start=1):
        code = strip_swift_line_comment(raw) if (production_swift or metal) else raw
        if not code.strip():
            continue
        if production_swift:
            for rule, (pattern, severity) in COMPILED.items():
                if not pattern.search(code):
                    continue
                # Both original SOS filter lookups are deliberate internal
                # invariants; they must remain source-exact and are protected
                # by Tests/OriginalMusicFilterKeys568Contract.py. Never classify
                # arbitrary new fatalError/preconditionFailure as permitted.
                if (rule == "forced_abort"
                    and path == "ASTEROIDYiOS/OriginalMusicSynth568.swift"
                    and 'guard let sos=filters[key] else {preconditionFailure(' in code
                    and 'Missing original source SOS filter:' in code):
                    issues.append(Finding("verified_dsp_filter_invariant", "review",
                                          path, number, raw.strip()[:180]))
                    continue
                issues.append(Finding(rule, severity, path, number, raw.strip()[:180]))
            if re.search(r"\[[^\]\n]+\]!", code):
                issues.append(Finding("forced_optional_subscript_candidate", "review",
                                      path, number, raw.strip()[:180]))
        if metal and re.search(r"\bwhile\s*\(\s*(?:true|1)\s*\)", code):
            issues.append(Finding("unbounded_shader_loop_candidate", "review",
                                  path, number, raw.strip()[:180]))
        if python_tool:
            for label, pattern in (
                ("bare_except_candidate", r"^\s*except\s*:"),
                ("shell_command_candidate", r"\bshell\s*=\s*True\b|\bos\.system\s*\("),
                ("dynamic_code_candidate", r"\b(?:eval|exec)\s*\("),
            ):
                if re.search(pattern, code):
                    issues.append(Finding(label, "review", path, number,
                                          raw.strip()[:180]))
        if workflow:
            for label, pattern in (
                ("shell_install_candidate", r"curl\s+.+\|\s*(?:sh|bash)\b"),
                ("privileged_pr_candidate", r"^\s*pull_request_target\s*:"),
                ("broad_write_permission_candidate", r"^\s*permissions\s*:\s*write-all"),
            ):
                if re.search(pattern, code):
                    issues.append(Finding(label, "review", path, number,
                                          raw.strip()[:180]))
    return issues

def tracked_files(root: Path) -> list[Path]:
    try:
        names = subprocess.check_output(
            ["git", "-C", str(root), "ls-files", "-z"], stderr=subprocess.DEVNULL
        ).decode("utf-8").split("\0")
        files = [root / n for n in names if n]
    except (OSError, subprocess.CalledProcessError, UnicodeDecodeError):
        files = list(root.rglob("*"))
    return sorted(
        p for p in files if p.is_file() and p.suffix.lower() in CODE_SUFFIXES
        and not any(part in {".git", ".build", "__pycache__", "DerivedData"}
                    for part in p.relative_to(root).parts)
    )


def duplicate_candidates(sources: dict[str, str]) -> list[tuple[str, str, int]]:
    # Exact repeated 10-line code windows across different Swift production
    # files; a hint for code review, not a claim that common formulas are slop.
    windows: dict[str, set[str]] = defaultdict(set)
    for path, body in sources.items():
        if not path.startswith(PRODUCTION_ROOT) or not path.endswith(".swift"):
            continue
        lines = [re.sub(r"\s+", "", strip_swift_line_comment(s))
                 for s in body.splitlines()]
        lines = [s for s in lines if s and s not in {"{", "}", "}", "else{"}]
        for i in range(max(0, len(lines) - 9)):
            chunk = "".join(lines[i:i + 10])
            if len(chunk) < 240:
                continue
            windows[hashlib.sha1(chunk.encode("utf-8")).hexdigest()].add(path)
    pairs: Counter[tuple[str, str]] = Counter()
    for paths in windows.values():
        if len(paths) > 1 and len(paths) <= 8:
            p = sorted(paths)
            for i, left in enumerate(p):
                for right in p[i + 1:]:
                    pairs[(left, right)] += 1
    return [(a, b, count) for (a, b), count in
            pairs.most_common(12)]


def audit(root: Path) -> dict:
    files = tracked_files(root)
    sources: dict[str, str] = {}
    sizes: dict[str, int] = {}
    linecounts: dict[str, int] = {}
    for file in files:
        path = file.relative_to(root).as_posix()
        try:
            content = file.read_text(encoding="utf-8")
        except (OSError, UnicodeError):
            continue
        sources[path] = content
        sizes[path] = len(content.encode("utf-8"))
        linecounts[path] = len(content.splitlines())
    production = {p: v for p, v in sources.items() if
                  p.startswith(PRODUCTION_ROOT) and p.endswith(".swift")}
    findings = [issue for p, value in sources.items()
                for issue in scan_text(p, value)]
    extensions = Counter(Path(p).suffix for p in sources)
    return {
        "tool_version": 1,
        "scan_scope": "tracked source/config files; static analysis only",
        "tracked_source_files": len(sources),
        "production_swift_files": len(production),
        "production_swift_bytes": sum(sizes[p] for p in production),
        "source_bytes": sum(sizes.values()),
        "extension_counts": dict(sorted(extensions.items())),
        "large_modules": [
            {"path": p, "lines": linecounts[p], "bytes": sizes[p]}
            for p in sorted(production, key=lambda p: linecounts[p], reverse=True)
            if linecounts[p] >= 500
        ][:30],
        "rule_counts": dict(sorted(Counter(x.rule for x in findings).items())),
        "findings": [asdict(x) for x in findings],
        "duplicate_candidates": [
            {"left": a, "right": b, "shared_windows": count}
            for a, b, count in duplicate_candidates(sources)
        ],
        "critical_count": sum(x.severity == "critical" for x in findings),
    }


def markdown(report: dict) -> str:
    lines = [
        "# ASTEROIDY iOS — automatyczny audyt jakości źródeł",
        "",
        "**Zakres:** wszystkie śledzone pliki kodu i konfiguracji; "
        "reguły krytyczne obejmują produkcyjne pliki Swift.",
        "Ta analiza statyczna nie dowodzi ani nie wyklucza błędów runtime, "
        "klatkowania, błędów grafiki czy niepełnej zgodności z oryginałem.",
        "",
        f"- Pliki źródłowe/konfiguracyjne: **{report['tracked_source_files']}**",
        f"- Produkcyjne pliki Swift: **{report['production_swift_files']}**",
        f"- Rozmiar produkcyjnego Swift: **{report['production_swift_bytes']:,} B**",
        f"- Wyniki krytyczne: **{report['critical_count']}**",
        "",
        "## Kategorie plików", "",
        "| Typ | Liczba |", "|---|---:|",
    ]
    for ext, count in report["extension_counts"].items():
        lines.append(f"| {ext} | {count} |")
    lines += ["", "## Największe moduły (kandydaci do stopniowego podziału)",
              "", "| Plik | Linie |", "|---|---:|"]
    for row in report["large_modules"]:
        lines.append(f"| \`{row['path']}\` | {row['lines']} |")
    lines += ["", "## Reguły wykryte w produkcyjnym Swift", "",
              "| Reguła | Trafienia |", "|---|---:|"]
    for rule, count in report["rule_counts"].items():
        lines.append(f"| {rule} | {count} |")
    lines += ["", "## Wymagające analizy — dokładne miejsca",
              "", "| Priorytet | Plik:linia | Reguła |", "|---|---|---|"]
    for issue in sorted(report["findings"], key=lambda x:
                        (x["severity"] != "critical", x["path"], x["line"]))[:75]:
        lines.append(f"| {issue['severity']} | "
                     f"\`{issue['path']}:{issue['line']}\` | {issue['rule']} |")
    lines += ["", "## Powielone fragmenty (kandydaci, nie potwierdzone błędy)",
              "", "| Moduły | Wspólne okna 10 linii |", "|---|---:|"]
    for item in report["duplicate_candidates"]:
        lines.append(f"| \`{item['left']}\` / \`{item['right']}\` "
                     f"| {item['shared_windows']} |")
    lines += ["", "## Interpretacja i dalsze zasady",
              "",
              "- Wymagane jest ręczne ustalenie przyczyny każdej zmiany.",
              "- Duży plik, podobna formuła, debug log lub \`try?\` nie są "
              "same w sobie dowodem wadliwego kodu.",
              "- Zakaz nowych wymuszonych awarii, pustych \`catch\` i "
              "synchronicznych wywołań głównej kolejki.",
              "- Każdy wyłapany problem naprawiać w małym PR z testami i bez "
              "naruszenia 60 FPS, dotyku, audio, HUD-u i iPada 4:3.",
              "- Testy urządzeń, kompletność portu i porównanie graficzne "
              "muszą być potwierdzane oddzielnie.",
              ""]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--json", dest="json_path")
    parser.add_argument("--markdown", dest="markdown_path")
    parser.add_argument("--gate", action="store_true")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    report = audit(root)
    if args.json_path:
        dest = Path(args.json_path)
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
    if args.markdown_path:
        dest = Path(args.markdown_path)
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(markdown(report), encoding="utf-8")
    print("QUALITY_AUDIT", json.dumps({
        k: report[k] for k in ("tracked_source_files", "production_swift_files",
                                "source_bytes", "critical_count", "rule_counts",
                                "large_modules", "duplicate_candidates")
    }, ensure_ascii=False))
    if args.gate and report["critical_count"]:
        for issue in report["findings"]:
            if issue["severity"] == "critical":
                print(f"ERROR {issue['path']}:{issue['line']} {issue['rule']}",
                      file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

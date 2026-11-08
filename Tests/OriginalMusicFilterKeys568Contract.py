#!/usr/bin/env python3
"""Verify two deliberate source-DSP filter invariants without changing samples.

The missing-key precondition is only safe if EVERY internally generated
filter key exists in the exact v568 source coefficient table.
"""
from pathlib import Path
import re

source=(Path(__file__).resolve().parents[1]/
        "ASTEROIDYiOS/OriginalMusicSynth568.swift").read_text(encoding="utf-8")
keys=set(re.findall(r'^\s*"([^"]+)"\s*:\s*\[',source,flags=re.MULTILINE))
acid={f"acid:{650+210*i}" for i in range(11)}
pads={f"lowpass:{1200+250*i}" for i in range(5)}
static={
    "lowpass:9000", "lowpass:7000", "lowpass:7500",
    "lowpass:6200", "lowpass:9000", "lowpass:7000",
    "highpass:29", "highpass:25", "highpass:1800",
    "highpass:6500", "highpass:2500",
}
expected=acid|pads|static
missing=expected-keys
assert not missing, f"Missing exact original DSP coefficients: {sorted(missing)}"
# The synthesis path selects voice in the closed 0...4 range.
assert "voice=v<5 ? v : 1" in source
assert "guard (0..<count).contains(track)" in source
assert "let hz=650+((index*17+variant*9)%11)*210" in source
assert "let hz=650+((index*13+style*7)%11)*210" in source
assert 'channel=filtered(channel,"lowpass:\\(1200+variant*250)")' in source
guards=re.findall(
    r'guard let sos=filters\[key\] else \{preconditionFailure\('
    r'"Missing original source SOS filter: \\(key\)"\)\}',
    source)
assert len(guards)==2, f"Unexpected source DSP invariants: {len(guards)}"
print(f"PASS exact source SOS table: {len(expected)} required keys, two guarded internal invariants, no DSP coefficient change")

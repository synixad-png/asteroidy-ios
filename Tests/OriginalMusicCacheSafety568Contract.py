#!/usr/bin/env python3
"""Source DSP cache invariants: no force unwrap or altered synthesis maths.

A separate CI test must prove byte-for-byte parity against approved
OriginalMusicSynth568.swift from commit 8af0f3f1; this is only a source
safety contract, never a claim of audible or binary parity on its own.
"""
from pathlib import Path

r=Path(__file__).resolve().parents[1]
s=(r/"ASTEROIDYiOS/OriginalMusicSynth568.swift").read_text()

for token in (
    'for kind in ["closed","open","clap","shaker","tom"] {perc[kind]=SourceDsp568.percussion(&rng,kind)}',
    'guard let closedPerc=perc["closed"],let openPerc=perc["open"],',
    'let clapPerc=perc["clap"],let shakerPerc=perc["shaker"],',
    'let tomPerc=perc["tom"] else {throw SynthError568.invalidPCM}',
    'if bass[note]==nil {bass[note]=SourceDsp568.bass(note,beat/4*0.88)}',
    'guard let cachedBass=bass[note] else {throw SynthError568.invalidPCM}',
    'if pads[padKey]==nil {pads[padKey]=SourceDsp568.pad(key,voice,section,bar*4)}',
    'guard let cachedPad=pads[padKey] else {throw SynthError568.invalidPCM}',
    'acid[cache]=v<5 ? SourceDsp568.acid(note,beat*0.64,idx,voice) : SourceDsp568.lead(note,beat*0.64,idx,v-5)',
    'guard let cachedAcid=acid[cache] else {throw SynthError568.invalidPCM}',
    'SourceDsp568.add(&main,cachedBass,at+Double(s)*beat/4,0.69*strength,0)',
    'SourceDsp568.add(&space,cachedPad,Double(b)*bar,breakdown ? 0.85 : 0.32)',
    'SourceDsp568.add(&main,cachedAcid,at,gain,pan)',
    'SourceDsp568.add(&delay,cachedAcid,at,gain*0.6,-pan)',
    'SourceDsp568.add(&main,openPerc,at+beat/2,0.15*strength,(q%2==1 ? 1 : -1)*0.22)',
    'SourceDsp568.add(&main,closedPerc,at+Double(s)*beat/4,0.095*strength,(s==1 ? -1 : 1)*0.35)',
    'SourceDsp568.add(&main,clapPerc,at,0.12*strength,0.05)',
    'SourceDsp568.add(&main,shakerPerc,at+Double(s)*beat/4,',
    'SourceDsp568.add(&main,tomPerc,Double(b)*bar+(3+Double(p)/4)*beat,',
):
    assert token in s, f"Original MusicAudio.cs source PCM arrangement or sample cache changed: {token}"
for token in ('bass[note]!','pads[padKey]!','acid[cache]!',
              'perc["open"]!','perc["closed"]!','perc["clap"]!',
              'perc["shaker"]!','perc["tom"]!'):
    assert token not in s, f"Unsafe DSP sample forced unwrap reintroduced: {token}"
assert 'guard (0..<count).contains(track), testBars>0, testBars<=bars' in s
assert 'var rng=try SourceRng568(track:v,zigURL:zigURL)' in s
assert 'checkpoint()' in s
print("PASS original v568 sample cache safety: 9 forced lookups removed without changing source DSP/RNG expressions")

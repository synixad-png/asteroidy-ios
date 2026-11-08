#!/usr/bin/env python3
"""No forced dictionary unwrap in source-ordered rock hit processing.

Behavior is independently exercised by GameCoreTests.swift,
SphereCombatBatch556Tests.swift and SphereSector556Tests.swift in CI.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]/"ASTEROIDYiOS"
flat=(root/"GameCore.swift").read_text()
sphere=(root/"SphereSector556.swift").read_text()

for source,source_name,sorted_keys,safe_lookup,forbidden in (
    (flat, "GameCore", "for index in damageEvents.keys.sorted(by: >)",
     "guard let amount=damageEvents[index] else { continue }",
     "damageEvents[index]!"),
    (sphere, "SphereSector556", "for idx in rockHits.keys.sorted(by:>)",
     "guard let incoming = rockHits[idx] else { continue }",
     "rockHits[idx]!"),
):
    assert sorted_keys in source, f"{source_name}: source descending damage order lost"
    assert safe_lookup in source, f"{source_name}: missing safe dictionary read"
    assert forbidden not in source, f"{source_name}: forced unwrap reintroduced"

# Preserve exact hit aggregation, split order, first-contact and demo rules.
for token in (
    "damageEvents[i,default:0] += 1",
    "damageRock(at:index,amount:amount)",
    "bolts = bolts.enumerated().compactMap",
):
    assert token in flat, f"Flat training damage path changed: {token}"
for token in (
    "rockHits[target,default:[]].append(bolts[i])",
    "for bolt in incoming { impactRock(at:idx,with:bolt) }",
    "damageRock(at:idx,amount:incoming.count)",
    "AmigaBounce265.impact(&asteroids[idx],",
    "score += 10",
):
    assert token in sphere, f"Sphere source combat hit path changed: {token}"
print("PASS: safe dictionary reads, original descending hit order and deterministic rock damage paths")

#!/usr/bin/env python3
"""PC609 fail-closed iPad black-screen diagnostics for real Intro41 renderer.

A Metal setup error at intro t=0 must never be covered by the normal 100%
cinematic fade; preserve the authentic fade whenever the renderer works.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
intro=(root/"ASTEROIDYiOS/MissionCinematic568.swift").read_text()
app=(root/"ASTEROIDYiOS/App.swift").read_text()
renderer=(root/"ASTEROIDYiOS/MetalRenderer.swift").read_text()
orbit=(root/"ASTEROIDYiOS/PC602HomeWorldPage291.swift").read_text()
assert 'Color.black.opacity(input.rendererError == nil' in intro
assert '? Double(min(1,max(0,fade))) : 0)' in intro
assert 'if let error=input.rendererError' in intro
assert 'Button("WRÓĆ DO MAPY")' in intro
assert 'input.introProgress41>=0.6' in intro
assert 'MetalScene(input:input)' in intro
assert 'missionIntroInput568.rendererError=nil' in app
assert 'showingMissionIntro568=true' in app
assert 'private func enterOrbitMission291' in app
assert 'private func cancelMissionIntro568()' in app
assert 'input?.rendererError =' in renderer
assert 'driver.reportRendererError(error)' in orbit
assert 'pc602-orbit-renderer-recovery' in orbit
print("PASS original Intro41 fade preserved and error remains visible when Metal is missing; H290 return escape unchanged")

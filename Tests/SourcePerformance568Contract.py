#!/usr/bin/env python3
"""Windows v568 source ShowPerformance Option ID 6, real native Metal FPS."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def f(p):return (root/p).read_text()
ui=f("ASTEROIDYiOS/CarbonisVisualSettingsPanel568.swift")
perf=f("ASTEROIDYiOS/SourcePerformance568.swift")
car=f("ASTEROIDYiOS/Sector01CarbonisPreview568.swift")
metal=f("ASTEROIDYiOS/MetalRenderer.swift")
scene=f("ASTEROIDYiOS/Sector01Scene568.swift")
app=f("ASTEROIDYiOS/App.swift")
acc=f("ASTEROIDYiOS/SourceFPSAccumulator568.swift")
assert "case 0: sourceGraphicsPage" in ui
assert 'LICZNIK WYDAJNOŚCI (POMIAR FPS)' in ui
assert '"w3-source-show-performance-006"' in ui
assert "performance.setEnabled(value)" in ui
assert "static let sourceOptionID=6" in perf
assert "UserDefaults.standard.bool(forKey:Self.sourceKey)" in perf
assert "UserDefaults.standard.set(value,forKey:Self.sourceKey)" in perf
assert "command.addCompletedHandler" in perf
assert "completed.status == .completed" in perf
assert "completed.gpuStartTime" in perf
assert "completed.gpuEndTime" in perf
assert "samplingSeconds:Double=0.5" in acc
assert "SourcePerformance568.shared.watch(command)" in car
assert metal.count("SourcePerformance568.shared.watch(command)")==2
assert "SourcePerformanceOverlay568()" in scene and "session.hud.phase == .playing" in scene
assert "SourcePerformanceOverlay568()" in app and "!showMainMenu && sourceSector01 == nil" in app
assert "SourcePerformanceOverlay568()" not in f("ASTEROIDYiOS/W3StartupSplash568.swift")
assert "SourcePerformanceOverlay568()" not in f("ASTEROIDYiOS/W3MainMenu568.swift")
assert "CADisplayLink" not in perf,"must measure finished frames, not refresh rate"
print("PASS original Windows v568 option ID6 true Metal-completed FPS and 0.5s")
print("PASS menu/splash excluded; active CARBONIS/diagnostic scenes only")

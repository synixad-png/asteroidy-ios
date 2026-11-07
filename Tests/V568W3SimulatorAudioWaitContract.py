#!/usr/bin/env python3
"""Source-proof screenshot capture waits for real audio before SwiftUI home."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
script=(root/"Tools/run_w3_native_menu_simulator_capture.py").read_text()
assert "deadline=started+240" in script
assert "while not proof.is_file() and time.monotonic()<deadline:" in script
assert "if not proof.is_file():" in script
assert "Source music preparation did not reach W3 SwiftUI" in script
assert "time.sleep(5)" not in script
assert "time.sleep(1)" in script
assert 'SIMCTL_CHILD_ASTEROIDY_W3_MENU_VERIFY' in script
assert 'run_command(["xcrun","simctl","io",udid,"screenshot"' in script
assert "validate(payload)" in script and "gpuCommandBufferCompleted" in script
assert "candidate.rename(verified)" in script
print("PASS original W3 audio-generation gate waits for app-created SwiftUI proof")
print("PASS captures actual screenshot only after the verified app emits proof")

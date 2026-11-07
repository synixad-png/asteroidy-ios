#!/usr/bin/env python3
"""Fail-closed source contract for original v568 W3 NEW GAME."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
ui=(root/"ASTEROIDYiOS/W3MainMenu568.swift").read_text()
app=(root/"ASTEROIDYiOS/App.swift").read_text()
profiles=(root/"ASTEROIDYiOS/SourceNewGame568.swift").read_text()
combat=(root/"ASTEROIDYiOS/CarbonisCombat568.swift").read_text()
wave=(root/"ASTEROIDYiOS/Sector01PreparedWave568.swift").read_text()
for x in ['"1 GRACZ"','"2 GRACZY"','"ŁATWY"','"NORMALNY"','"TRUDNY"','"URUCHOM MISJĘ"','"POTWIERDŹ NOWĄ GRĘ"','"ANULUJ"']:
    assert x in ui,x
assert 'newPlayers568 != 1' in ui
assert 'SourceNewGame568.hasActiveProfile()' in ui
assert 'startNewGame:startNewGameFromW3' in app
assert 'SourceNewGame568.create(choice)' in app
assert 'Sector01CarbonisPreview568.isAvailable' in app
assert 'difficulty:SourceNewGame568.selection().difficulty' in app
assert 'let difficulty:CombatBalance556.Difficulty' in combat
assert 'difficulty=prepared.difficulty' in combat
assert 'difficulty:difficulty.rawValue' in combat
assert 'difficulty:difficulty' in combat
assert 'difficulty:.normal' not in combat
assert 'let difficulty:CombatBalance556.Difficulty' in wave
assert 'difficulty:difficulty,' in wave
assert '"ASTEROIDY/backups61"' in profiles
assert 'bytes.write(to:target,options:.atomic)' in profiles
assert 'CampaignStore556.save(fresh,defaults:defaults)' in profiles
assert 'guard request.players==1' in profiles
assert '62-sekundowy prolog Story359 nie jest jeszcze przeniesiony' in ui
print("PASS W3 native NEW GAME source / fail-closed boundaries")

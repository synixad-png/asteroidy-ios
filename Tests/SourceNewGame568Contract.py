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
assert 'var shipType:Int=1' in profiles
assert 'request.shipType' in profiles
assert 'lives:startingLives(difficulty:request.difficulty,' in profiles
assert 'selected.selectedShip=request.shipType' in profiles
assert 'H55SourceMechanics580.save(selected,defaults:defaults)' in profiles
assert 'w3-new-selected-ship-lives' in ui
assert 'w3-new-ship-' in ui and 'ForEach(0..<3,id:' in ui
assert 'newShipType568' in ui and 'shipType:newShipType568' in ui
assert 'shipType:shipType' in ui
assert '!playable' in ui
assert 'choice.shipType==selected' not in app
assert 'forShip:choice.shipType) != nil' in app
assert 'resourcesInstalled(' in app and 'forShip:choice.shipType)' in app
assert 'mechanicsOverride:freshMechanics' in app and 'shopOverride:freshShop' in app
assert 'shipType:state.shipType' in app
assert 'shipType:H55SourceMechanics580.load().selectedShip' in app
assert 'PC602HomeFlight291.Equipment(craft:craft)' in app
# Original PC609 three craft preflight is completed BEFORE the previous
# campaign is archived/reset; the old saved game survives a scene failure.
fresh=app.split('private func startNewGameFromW3',1)[1].split('// Windows Program.cs:',1)[0]
assert fresh.index('try homeWorld291.start(') < fresh.index('SourceNewGame568.create(choice)')
assert 'PC602HomeWorldDriver291.resourcesInstalled(' in fresh
assert 'Sector01CarbonisPreview568.isAvailable' in fresh
assert '62-sekundowy prolog Story359 nie jest jeszcze przeniesiony' in ui
print("PASS PC609 W3 NEW GAME: exact selected Kestrel/Vanguard/Bastion lives, safe source profile reset and mission intro")

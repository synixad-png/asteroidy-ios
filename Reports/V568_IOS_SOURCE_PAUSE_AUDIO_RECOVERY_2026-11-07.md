# ASTEROIDY iOS v568 — oryginalna pauza misji i ponowne otwarcie audio po blokadzie iPada

**Zgłoszenie:** po zablokowaniu i odblokowaniu iPada dźwięk działa sporadycznie w menu i nie działa w misji, nawet po poprawce IPA #139; użytkownik dodatkowo zlecił wdrożenie oryginalnej pauzy i przycisku.

## Zweryfikowane oryginalne źródła v568
Archiwum: `Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip` (Library ChatGPT, 150 473 406 B). Zawartość sprawdzona bez zgadywania:
- `Windows/src/BossTunnelGame.cs:46–50`: `PausedFrom`, `Pause()`, `Resume()`, `TogglePause()`. `Pause()` przechodzi z `Mode.Playing` do `Mode.Paused` i wyłącza ciąg, `Resume()` przywraca tryb.
- `Windows/src/Game.cs:232–235`: `Game.Step` nie wykonuje ruchu i fizyki, gdy `Mode.Paused`.
- `Windows/src/RendererW3Pause317.cs:25–50`: ciemna półprzezroczysta nakładka nad istniejącą sceną, `GRA WSTRZYMANA`, `KONTYNUUJ`, `WYJDŹ DO MENU`, inne pozycje PC (ZAMKNIJ/ZAPISZ/WCZYTAJ/WYNIKI) nie są częścią portu.
- `Windows/src/Program.cs:181–184`: klawisz pauzy/ESC, przycisk kontynuacji i powrót do menu.
- `Windows/src/MusicAudio.cs:18,79`: podczas `Mode.Paused` ścieżka muzyczna jest wybierana przez `PausedFrom` i nie zmienia się; `duck=.55f`, `engineLevel=0`, `MusicBank.AllowPreparation(true)`.

## Zmiany kodu iOS
1. `ASTEROIDYiOS/Sector01Scene568.swift`: przycisk **PAUZA** widoczny w sektorze CARBONIS 01, funkcje `pauseMission568` / `resumeMission568` / `exitMission568`, W3 modal z **KONTYNUUJ** i **WYJDŹ DO MENU**. Wykorzystuje rzeczywistą blokadę `CarbonisSession568.paused` i realną klatkę `frame(at:)`, bez dodatkowego zegara lub fałszywego HUD. Odczyt palca: `session.release()`; pauza trwa przez blokadę systemową, a odblokowanie nie usuwa pauzy ustawionej przez użytkownika. Geometria, sterowanie lotem i prawej połowy ekranu nietknięte.
2. `ASTEROIDYiOS/App.swift`: przekazuje `onMissionPause` do rzeczywistego systemu dźwięku.
3. `ASTEROIDYiOS/OriginalAudioAV568.swift`: podczas pauzy wycisza źródłowy silnik, nie emituje nowych SFX, ustawia głośność muzyki na 55% poprzedniego poziomu. Po kontynuacji (albo po rzeczywistym lock/unlock iOS) aktywuje sesję, tworzy nowy `AVAudioPlayer` z **oryginalnego istniejącego WAV** przy tej samej `currentTime`, zamiast ufać staremu `isPlaying`; chroni STOP i 0% muzyki.
4. `ASTEROIDYiOS/OriginalEnginePlayback52.swift`: oryginalny DSP 44100Hz/2048 buforów bez zmian; wspólna `AVAudioSession` jest konfigurowana przed restartem engine w `OriginalAudioAV568`. Usunięto równoległe `setCategory/setActive` z kolejki silnika, które mogło ścigać się ze wznowieniem muzyki.
5. `Tests/IOSSourceCombatPause568Contract.py` i aktualizacja `Tests/IOSAudioLockResume568Contract.py` — testy źródłowej semantyki pauzy i odtwarzacza, wykonywane w workflow `verify-combat-only.yml` oraz w pełnej kompilacji IPA.

## Kontrola regresji
- PR: https://github.com/synixad-png/asteroidy-ios/pull/4
- PR CI [#419](https://github.com/synixad-png/asteroidy-ios/actions/runs/42416411451): **2/2 wymagane PASS** (macOS Swift/Metal i pełna regresja), a [main CI #421](https://github.com/synixad-png/asteroidy-ios/actions/runs/42416753068): **3/3 PASS**. PR #4 scalono do main `634da7b62f59c7205a77f40cc1234bd89cdf7013`. Pierwsza próba #418 wykryła nieaktualną sygnaturę testu po zmianie funkcji; kontrakt poprawiono i sprawdzono.
- Zachowano 18-zadaniowy plan portu, nie należy sztucznie zwiększać 38% wykonania / 62% do zrobienia.
- **Test fizyczny iPad/iPhone nadal wymagany**: faktyczna słyszalność muzyki, strzałów i silnika po lock/unlock, pause/resume, szybki dotyk przycisków i touch zones. Sam test Xcode/CI nie rozstrzyga skuteczności dźwięku na głośnikach.

## Co pozostało
**CI i IPA zakończone:** [#140](https://github.com/synixad-png/asteroidy-ios/actions/runs/42416753095) **4/4 PASS**, Xcode 16.4 iPhoneOS/ARM64 **BUILD SUCCEEDED**, kontrakt pauzy i blokady ekranu PASS, 43 oryginalne efekty/voice/intro i 15 generowanych ścieżek, `unzip -t` i `Tools/verify_ipa.py` PASS. [Niepodpisane IPA #140](https://github.com/synixad-png/asteroidy-ios/actions/runs/42416753095/artifacts/13592246637): ZIP artefaktu 28 025 256 B, SHA-256 **zewnętrznego ZIP** `a64aa584ba35b52f6458b34cf0a25080d00385160540ae34171bafbee98a2025`, zawiera `ASTEROIDY_iOS_UNSIGNED.ipa`. Test źródłowy nie gwarantuje dźwięku na sprzęcie. Potwierdzić na fizycznym urządzeniu z użytkownikiem: muzyka/menu, gra/strzały/silnik, wielokrotne wygaszenie ekranu, przycisk PAUZA→KONTYNUUJ i powrót do menu. Potem kontynuować 18-zadaniowy harmonogram bez regresji.

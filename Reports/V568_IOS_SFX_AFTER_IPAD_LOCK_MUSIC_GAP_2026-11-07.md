# ASTEROIDY iOS v568 — efekty strzałów/wybuchów po blokadzie iPada i luka muzyki

**Data:** 07.11.2026. **Baza:** iOS IPA #140. **Zgłoszenie sprzętowe:** po lock/unlock muzyka po krótkiej ciszy wraca, ale odgłosy strzelania i wybuchów pozostają nieme.

## Potwierdzone w kodzie wady poprzedniej implementacji
1. `OriginalAudioAV568.sceneIsActive(false)` wykonywało `effects.forEach { $0.pause() }`, lecz odtwarzacze przygotowane przy uruchomieniu były nadal przechowywane w `prewarmedEffects`. Po dezaktywacji urządzenia stare kolejki/dekodery `AVAudioPlayer` mogły już nie działać.
2. `sourceEffect(_:) ` pobierało z tej puli głos o `!isPlaying`, wywoływało `player.play()` i **ignorowało zwrócony wynik Bool**. W efekcie nowe zdarzenia oryginalnego strzelania i wybuchów mogły zostać bez dźwięku i bez informacji o niepowodzeniu.
3. Nawet po ręcznej pauzie/wznowieniu użytkownika `missionUserPause568(false)` rekonstruowało odtwarzacz z długiego WAV, co nie było potrzebne do zdrowego utworu i może dodawać chwilową ciszę. Przy prawdziwym lock/unlock rekonstrukcja wprowadzona w IPA #140 pozostaje potrzebna, bo stary player może błędnie zgłaszać `isPlaying`.

## Zmiany
- W `ASTEROIDYiOS/OriginalAudioAV568.swift` utworzono `invalidateSuspendedEffects568()`: zatrzymanie i zwolnienie starych aktywnych `effects`, `spokenVoices` oraz `prewarmedEffects`, osobno na wejście w tło i podczas systemowego przerwania audio. Nowy oryginalny efekt z kodu 10–14 lub 20–22 jest otwierany **na żądanie** dokładnie z wcześniej załadowanego `sounds[stem]`; nie uruchamiamy ciężkiego przebudowania całego banku na wejściu do misji, aby uniknąć niepotrzebnego kosztu CPU.
- `sourceEffect` nadal zachowuje oryginalne `variation % 3`, numer próbki, głośności, limit 16 równoczesnych głosów i oddzielne voice SFX. Gdy `play()` zwraca `false`, wywoływana jest jedna próba z nowym `AVAudioPlayer(contentsOf:file)`, a przy jej niepowodzeniu ustawiany jest stan błędu. Podczas `audioInterrupted`, `suspended` lub ręcznej pauzy nie emitujemy dodatkowych efektów.
- Muzyka: po poprawnej reaktywacji wspólnej `AVAudioSession` natychmiast próbujemy wznowić istniejący oryginalny WAV, dopiero potem otwieramy bezpieczną kopię z jego bieżącą pozycją przy prawdziwym uśpieniu. Start źródłowego `OriginalEnginePlayback52` jest wykonywany po operacjach muzyki, aby zmniejszyć ciszę. W przypadku zwykłej `PAUZA → KONTYNUUJ` nie ma rekonstrukcji WAV.
- Nie zmieniono żadnego pliku dźwiękowego, formuł PCM, źródłowego DPS silnika, muzyki, opcji użytkownika, fizyki, nagród, oryginalnych SFX, strzelania, wybuchów ani shaderów. Ograniczenie `MusicPercent=0` i pauza manualna są respektowane.

## Kontrole
- [PR #5](https://github.com/synixad-png/asteroidy-ios/pull/5) scalony jako `a12d8a5f48e666e35fd1a3a24336767fa7f64ffe`.
- [CI #423](https://github.com/synixad-png/asteroidy-ios/actions/runs/42419029222) **2/2 wymagane PASS**: natywne Swift/Metal oraz pełna macierz fizyki, walki, wybuchów, źródłowego audio. Pierwszy PR CI #422 wykazał nieaktualny test formatowania warunku pauzy; dopasowano zapis i końcowy CI #423 przeszedł.
- Nowy `Tests/IOSShotExplosionAudioResume568Contract.py`, zaktualizowane `Tests/IOSAudioLockResume568Contract.py` i `Tests/IOSSourceCombatPause568Contract.py`; uruchamiane w obu workflow GitHub Actions.
- [IPA #141](https://github.com/synixad-png/asteroidy-ios/actions/runs/42419340016) uruchomiono z commita naprawy. Wynik ostateczny i artefakt wymagają odrębnego sprawdzenia.

## Rzeczywisty iPad/iPhone — nadal konieczny test
Należy sprawdzić kolejno strzelanie i wybuchy przed zablokowaniem, blokadę ekranu na 20–30 sekund, powrót do misji bez wyłączania aplikacji, następnie muzykę, silnik oraz SFX (strzały i wybuchy), kilkukrotną blokadę z rzędu i ręczne `PAUZA → KONTYNUUJ`. Sprawdzić brak nowego chwilowego spadku FPS przy pierwszym strzale po odblokowaniu, gdy AVAudioPlayer jest odtwarzany na żądanie.

**Nie wykonano faktycznego odsłuchu ani testu na fizycznym urządzeniu.** Kompilacja i testy kontraktów nie uprawniają do ogłoszenia usunięcia usterki; jeśli nadal wystąpi, potrzebne będą logi AVAudioSession z rzeczywistego urządzenia.

**Stały harmonogram portu:** 18 zadań, **38% wykonane / 62% pozostało**, bez podwyższania postępu za naprawę regresji audio.

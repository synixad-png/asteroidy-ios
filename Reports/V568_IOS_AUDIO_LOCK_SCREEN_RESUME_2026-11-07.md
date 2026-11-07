# ASTEROIDY iOS v568 — przywracanie dźwięku po wygaszeniu i odblokowaniu ekranu iPada

**Data:** 07.11.2026. **Baza:** ASTEROIDY iOS v568 po IPA #138. **Zmiana:** PR #3, merge `fe473b21691480651911fa063ccfb3e32e995447`.

## Zgłoszenie i potwierdzony brak w kodzie

Użytkownik potwierdził, że w normalnej rozgrywce dźwięk działa, a po zablokowaniu ekranu iPada i powrocie do już uruchomionej gry zanika całe audio. Wada występowała **także we wcześniejszych wydaniach**, dlatego nie należy przypisywać jej optymalizacji geometrii z IPA #138.

W `ASTEROIDYiOS/App.swift` zdarzenie `.onChange(of: scenePhase)` prawidłowo wywołuje `audio.sceneIsActive(phase == .active)`. Jednak poprzednia implementacja `sceneIsActive(true)` w `OriginalAudioAV568.swift` wywoływała bezpośrednio `AVAudioPlayer.play()` dla muzyki/Intro43 i uruchamiała engine bez wspólnego **jawnego ponownego aktywowania `AVAudioSession`**. Apple dokumentuje, że przy zawieszeniu procesu system może dezaktywować sesję audio i opóźnić dostarczenie powiadomienia o przerwaniu.

## Wdrożona naprawa

1. `OriginalAudioAV568.swift`: `reactivateAudioSession568()` przywraca dotychczasową kategorię `.ambient` i aktywuje sesję **zanim** zostaną wznowione: oryginalny utwór WAV, Intro43, źródłowy silnik DSP. Błąd aktywacji jest raportowany w statusie audio, a nie maskowany.
2. `AVAudioSession.interruptionNotification`: reaguje na rozpoczęcie/koniec przerwania; rzeczywiste rozmowy/Siri nie wymuszają ponownego odtwarzania w trakcie przerwania. Opóźniony sygnał po zawieszeniu procesu jest obsługiwany odrębnie przy `AVAudioSessionInterruptionWasSuspendedKey`, gdy scena ponownie jest aktywna.
3. Jeśli `AVAudioPlayer` został unieważniony, awaryjnie ponownie otwierany jest **ten sam wcześniej wygenerowany oryginalny WAV**, z zachowaniem pozycji. Nie ma ponownego generowania 15 utworów ani wprowadzania zamienników. Intro43 pozostaje osobne i nie jest przykrywane muzyką misji.
4. `OriginalEnginePlayback52.swift`: dotychczasowe `running` nie jest uznawane za dowód słyszalnego wyjścia. Jeśli silnik audio zatrzymał się w systemie mimo flagi aplikacji, kod zatrzymuje nieaktualny player i uruchamia ponownie oryginalny strumień DSP. Formuły, częstotliwość 44,1 kHz i próbki silnika pozostają bez zmian.
5. Nie zmieniono ustawień głośności, źródłowych efektów trafień, muzyki, fizyki, sterowania, rendererów i wymiarów iPhone/iPad. `MusicPercent=0` i `MusicLibrary STOP` pozostają respektowane.

## Testy

- [PR #3](https://github.com/synixad-png/asteroidy-ios/pull/3) — osobna gałąź, przegląd różnic, scalona po kontroli.
- [CI #416](https://github.com/synixad-png/asteroidy-ios/actions/runs/42413506428) — **2/2 wymagane zadania PASS**: natywna kompilacja kodu Swift/Metal w Xcode i pełne testy rozgrywki; pomocniczy publikator pominięty zgodnie z konfiguracją PR.
- `Tests/IOSAudioLockResume568Contract.py` PASS: scena aktywna/wygaszona, przywrócenie sesji jako pierwsze, opóźnione powiadomienia, ochrona Intro43, brak automatycznego restartu muzyki przy zerowej głośności lub STOP, wznowienie oryginalnych WAV, kontrola `AVAudioEngine.isRunning` i `player.isPlaying`.
- [GitHub Actions — IPA #139](https://github.com/synixad-png/asteroidy-ios/actions/runs/42413786602) uruchomione po merge. Wynik builda urządzeniowego należy osobno potwierdzić.
- **Test blokady/odblokowania rzeczywistego iPada pozostaje niewykonany**. Same testy kompilacji nie potwierdzają przywrócenia słyszalnego dźwięku.

## Weryfikacja na iPadzie

Uruchomić nowy IPA, włączyć misję z muzyką i silnikiem, zablokować ekran przez przycisk iPada, odblokować i wrócić bez ponownego uruchamiania gry. Sprawdzić osobno muzykę misji, odgłosy strzałów/trafień oraz silnik. Powtórzyć przy menu i przy oryginalnym Intro43; zweryfikować zachowanie muzyki przy wartości 0% i STOP. Jeśli dźwięk pozostaje niemy, odczytać status audio iOS i prześledzić rzeczywiste logi `AVAudioSession`.

## Harmonogram

Utrzymano oryginalną listę 18 zadań portu: **38% wykonane, 62% pozostało**. Sama naprawa lifecycle audio nie stanowi nowej ukończonej funkcji gry.

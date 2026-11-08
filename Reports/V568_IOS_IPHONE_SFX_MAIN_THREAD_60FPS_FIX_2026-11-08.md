# ASTEROIDY iOS — skuteczne rozdzielenie wywołań SFX od głównego wątku (IPA #145)

**Data:** 08.11.2026. **Baza:** oryginalne źródła Windows ASTEROIDY v568, przeniesienie iOS na bazie IPA #144. **PR:** [#9 — fix iOS SFX off main](https://github.com/synixad-png/asteroidy-ios/pull/9), merge commit `1725a7e9aa4337fe6f359ffb357335500e4256de`.

## Wiarygodna obserwacja z fizycznego urządzenia, przekazana przez użytkownika

- Na iPhonie z włączonymi efektami strzały obniżały FPS do ok. **40**; pomiary z IPA #144: **DRAW 40/s, średni odstęp 25,0 ms, p95 44,8 ms, max 72,7 ms, CPU 1,6 ms, SYM 0,6 ms, GPU 4,3 ms, WAIT drawable 0,0 ms i WAIT stream 0,0 ms**.
- Przy **głośności efektów dźwiękowych 0% i muzyce 100%** zarówno **iPhone, jak i iPad utrzymywały 60 FPS**, co znacząco zwiększa podejrzenie blokowania pętli UI przez obsługę efektów audio, a nie ograniczeń GPU.
- Nie wynika z tego automatycznie, że na podstawie pomiarów znamy jedyną przyczynę. Wynik z nową poprawką i aktywnymi efektami wymaga testu rzeczywistych urządzeń.

## Rzeczywista zmiana

W `ASTEROIDYiOS/OriginalAudioAV568.swift` poprzednia implementacja `sourceEffect` wykonywała na głównym wątku dla każdego dźwięku `AVAudioPlayer.isPlaying`, `AVAudioPlayer.prepareToPlay()`, `AVAudioPlayer.play()`, potencjalne `AVAudioPlayer(contentsOf:)`, zatrzymywanie i czyszczenie 16-głosowej listy. Metody AVFoundation mogły opóźniać obsługę wejścia `MTKViewDelegate.draw(in:)`.

Dodano `ASTEROIDYiOS/OriginalShotSFXWorker568.swift` ze **ściśle szeregową kolejką DispatchQueue o priorytecie userInitiated**, przejmującą własność oryginalnych instancji SFX. Na głównym wątku pozostało tylko źródłowe wyliczenie kodu próbki, wariantu `variation++`, gain i przekazanie krótkiego zdarzenia do kolejki. Odtwarzanie, wybór wolnego głosu, tworzenie ewentualnego nowego AVAudioPlayer, obsługa `play()==false`, `stop` oraz usuwanie zakończonych głosów wykonuje teraz serial worker, **poza główną kolejką UI/MetalKit**.

Zachowano:
- Te same oryginalne pakietowe M4A, identyczny cykl wariantów (0/1/2), gains 0,84 / 0,38 / 0,32 / 0,55 zależnie od kodu i ustawiany przez użytkownika poziom efektów.
- Dwa wstępnie przygotowane głosy na próbkę tworzone podczas startu poza głównym wątkiem, rozszerzenie do maksymalnie czterech głosów per stem oraz **16 głosów na całość**, przerwanie poprzedniego głosu polskiego lektora bez wyciszania eksplozji i broni.
- `prepareToPlay()` tylko dla nowego lub awaryjnie odtworzonego odtwarzacza — **nie przy każdym strzale**. W razie nieudanego `play()` ponowne otwarcie **tego samego źródłowego M4A** i pojedyncza powtórka; błąd w UI publikowany asynchronicznie na głównym wątku.
- Naprawę dźwięku po blokadzie ekranu z #141: przerywanie/wygaszenie wszystkich chwilowych efektów oraz odrzucenie starych pul audio po suspensie na dedykowanej kolejce; aktywacja `AVAudioSession`, podkład muzyczny i `OriginalEnginePlayback52` pozostały w swoich dotychczasowych ścieżkach.
- Wszystkie dotychczasowe rendering Metal, obiekt iPhone-only 100/84/74% z #142, kolejność `currentDrawable` z #143, licznik `DRAW` z #144, obsługę iPada 4:3, mechanikę, fizykę, kolizje, obraz i dźwięki oryginału.

## Testy i wydanie

- [PR CI #433](https://github.com/synixad-png/asteroidy-ios/actions/runs/42463798647): **2/2 właściwe testy PASS**; natywna kompilacja iOS Swift/Metal, pełna macierz regresji fizyki, dźwięków i źródłowych kontraktów. Podpis w logu: `PASS iPhone fire/explosion AVAudioPlayer off main; original 16 voices, variants, PCM and gain preserved` oraz `PASS iPad lock/unlock: invalidate stale voices on worker, retry exact original file, fast music-first resume`.
- [Main CI #434](https://github.com/synixad-png/asteroidy-ios/actions/runs/42464084686): właściwe joby kompilacji Swift/Metal i regresji combat **PASS**; pomocnicza publikacja statusu `publish-combat-verify-run` zgłosiła **409 Conflict** (zmiana commita dokumentacyjnego na main; nie dotyczy źródeł ani kompilacji), więc **nie raportujemy 3/3 PASS**.
- [GitHub Actions IPA #145](https://github.com/synixad-png/asteroidy-ios/actions/runs/42464084745): **4/4 PASS**, Xcode `BUILD SUCCEEDED` na iOS ARM64, 43 oryginalne SFX/głosy/intro i 15 utworów syntezowanych podczas działania PASS, test poprzedniego dźwięku po iPad lock PASS, `unzip -t` PASS, `Tools/verify_ipa.py` PASS (Payload, Info.plist, fizyczny iPhone/iPad, iOS 17+, ZIP CRC).
- [Pobierz **ASTEROIDY-iOS-device-unsigned-ipa #145**](https://github.com/synixad-png/asteroidy-ios/actions/runs/42464084745/artifacts/13611482405) — zewnętrzny ZIP **28 050 698 B**, SHA256 `fa67f7834a0550a85af6d11d1530a0791c6939b2d619fa370659f14d0b4028db`; w środku `ASTEROIDY_iOS_UNSIGNED.ipa`, wymaga podpisania na docelowym urządzeniu.

## Ograniczenia i następny test

**Nie wykonano testu interaktywnego na fizycznym iPhonie/iPadzie z nowym IPA.** Użytkownik powinien przetestować w #145 w **obu urządzeniach**: muzyka 100%, efekty 100%, ciągły ostrzał, uderzenia i wybuchy przez 20–30 sekund; sprawdzić stabilność FPS i zachowanie prawdziwych oryginalnych efektów. Następnie uśpić i odblokować iPada w trakcie misji i sprawdzić, że głosy, strzały, wybuchy i muzyka nadal działają. Jeżeli spadki występują, przekazać `FPS, DRAW, CPU, GPU, WAIT drawable/stream`, a nie redukować grafikę bez dowodu.

**Harmonogram portu iOS** — bez sztucznego zwiększania zakresu: 18 zadań, 38% zakończone / 62% pozostaje. Optymalizacja SFX nie stanowi automatycznie ukończenia następnego etapu portu.

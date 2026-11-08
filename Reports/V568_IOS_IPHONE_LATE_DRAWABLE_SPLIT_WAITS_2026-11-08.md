# ASTEROIDY iOS v568 — iPhone-only deferred CAMetalDrawable / source shooting FX

**Data:** 2026-11-08. **Wydanie:** unsigned iOS IPA #143. **Główna baza:** IPA #142; zachowane poprawki audio #141. **Źródło zmiany:** użytkownik potwierdził, że na iPadzie strzelanie działa bez dużych spadków, a na iPhonie występują spadki FPS z 60 do 30 podczas strzelania.

## Potwierdzony problem w źródłach, bez zgadywania przyczyny sprzętowej
W `ASTEROIDYiOS/Sector01CarbonisPreview568.swift` (baza #142) pętla `MTKViewDelegate.draw(in:)` pobierała `view.currentDrawable` oraz render pass/encoder **przed** wywołaniem semafora 3-frame `fxStream568.beginFrame()`, przed oryginalną symulacją `CarbonisSession568.frame` i przed zbudowaniem trzech grup efektów CPU: `CarbonisProjectileFX69.indexedGroundLights`, `CarbonisProjectileFX69.indexedVertices` wraz z muzzle oraz `CarbonisExplosion524Meshes.vertices`. W tej kolejności potencjalnie przetrzymywano zasób CAMetalDrawable w czasie oczekiwania na GPU i liczenia geometrii.

Samo to nie dowodzi, że wąskim gardłem iPhone'a jest `currentDrawable`, GPU lub CPU. Brak było pomiarów urządzenia wskazujących na konkretną przyczynę. Dlatego zmiana poprawia kolejność oraz dodaje dokładne pomiary zamiast dalszego ograniczania efektów.

## Rzeczywista implementacja — PR #7
[Pull request #7](https://github.com/synixad-png/asteroidy-ios/pull/7) scalono do `main`: **commit `2bf285dd132adcb8c1bc1774b8cd5b72f64bdfe2`**.

- **iPhone i aktywna misja wyłącznie:** bramka `gameSession != nil && UIDevice.current.userInterfaceIdiom == .phone`. Pętla Metal robi `session.frame`, źródłowe indeksowane światła pocisków, geodezyjne smugi i orby wraz z 24-slice muzzle, ostrzeżenia wrogów, oryginalne tokeny, 3D debris i Explosion524 *przed* pobraniem `view.currentDrawable`. Jednorazowy `PhonePreparedFX568` przechowuje te same oryginalne wierzchołki i indeksy, które następnie przechodzą przez istniejące GPU stream buffers i draw calls. Geometria nie jest budowana ponownie po pozyskaniu drawable.
- **Synchronizacja:** iPhone wywołuje `fxStream568.beginFrame()` przed pobraniem drawable, po zakończeniu przygotowania CPU. Jeśli `currentDrawable`, pass, command lub encoder nie są dostępne, wywołuje nowy `fxStream568.abortFrame()` uwalniający jednorazowo wcześniej zarezerwowany semafor.
- **Rozdzielone pomiary:** `SourcePerformance568` w istniejącym liczniku FPS na iPhonie pokazuje dodatkowo `WAIT drawable X / stream Y ms`; osobno od `CPU/SYM`, `GPU` i `FX CPU P/W`. `WAIT drawable` mierzy dokładnie wywołanie `view.currentDrawable`, nie tworzenie encoderów; CPU na iPhonie obejmuje także wcześniejsze generowanie source FX. Wartości są średnimi, nie pomiarami osobnych GPU passów.
- **iPad i ekran W3 pozostają poza nową ścieżką:** pierwotna kolejność `currentDrawable` → `beginFrame` → `session.frame` → budowanie FX → `present/commit` nadal jest zachowana. iPad nie dostaje dodatkowej linii overlay, nie ma adaptacyjnej rozdzielczości iPhone i korzysta z oryginalnej natywnej rozdzielczości.
- Zachowane: komplet źródłowych shaderów i efektów, liczba strzałów, logika kolizji/obrażeń, kontrola W3, dźwięk strzałów i wybuchów przy lock/unlock z IPA #141, adaptacja 100/84/74% tylko iPhone z #142. Nie zmieniano plików audio/Physics68.

## Automatyczna weryfikacja
- [PR CI #429](https://github.com/synixad-png/asteroidy-ios/actions/runs/42458911490): **2/2 PASS**, natywny Swift/Metal oraz wszystkie kontrakty i regresje. Wcześniejszy #428 wykrył błędy parsowania wielowierszowych operatorów matematycznych w nowym kodzie Swift, usunięte przed scaleniem.
- [main CI #430](https://github.com/synixad-png/asteroidy-ios/actions/runs/42459117791): **3/3 PASS**.
- [build IPA #143](https://github.com/synixad-png/asteroidy-ios/actions/runs/42459117850): **4/4 PASS**; urządzeniowa kompilacja Xcode `** BUILD SUCCEEDED **`; 43 oryginalne sample/voice/intro i 15 syntetyzowanych utworów, poprawka audio lock SFX PASS; `unzip -t` i `Tools/verify_ipa.py` **PASS** (ARM64, iOS 17+, fizyczne iPhone/iPad, Info.plist, kompletny Payload i ZIP CRC).
- [Pobierz unsigned IPA #143](https://github.com/synixad-png/asteroidy-ios/actions/runs/42459117850/artifacts/13609575476) — artifact `ASTEROIDY-iOS-device-unsigned-ipa`, ZIP **28 043 867 bajtów**; **SHA256 zewnętrznego ZIP** `0b70c73c4a040c80dbc5f8c341835ee8f199e14b1c3ab01a9270e8cea2a7b90d`. W ZIP `ASTEROIDY_iOS_UNSIGNED.ipa`. IPA wymaga podpisania dla docelowego urządzenia, np. Sideloadly.

## Co pozostało
1. **Test na rzeczywistym iPhonie:** FPS przy ciągłym strzelaniu (60→30), trafieniu w asteroidę i wroga; włączyć istniejący licznik i spisać `CPU`, `SYM`, `WAIT`, `GPU`, `FX CPU P/W`, nowy `WAIT drawable / stream`.
2. **Test na rzeczywistym iPadzie:** powtórzyć ostrzał, upewnić się, że zachowane są dawne stabilne FPS i wygląd renderowanej sceny oraz audio #141.
3. Jeśli po poprawce iPhone nadal pokazuje 30 FPS, diagnozować na podstawie tych wartości: wysokie `WAIT drawable` to presja na CAMetalLayer; wysokie `stream` to blokowanie GPU in-flight; wysokie `FX CPU P` to koszt geometrii; wysokie `GPU` oznacza faktyczne obciążenie GPU. Nie wprowadzać kolejnych niepotwierdzonych redukcji jakości.

**Ograniczenie:** brak testu na fizycznym iPhonie/iPadzie; 60 FPS nie jest potwierdzone przez wydanie ani CI. **Stała lista 18 zadań portu: 38% wykonane, 62% pozostało**. Poprawka FPS nie jest kolejnym ukończonym etapem portowania.

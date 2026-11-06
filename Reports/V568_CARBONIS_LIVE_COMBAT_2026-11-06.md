# ASTEROIDY iOS v568 — integracja rozgrywki CARBONIS 01

Data: 2026-11-06. Gałąź: main, repozytorium synixad-png/asteroidy-ios. Ściśle rozdzielono wdrożenie kodu i potwierdzone uruchomienie na urządzeniu.

## Wykonane w bieżącej sesji

- `CarbonisCombat568.swift`: źródłowa inicjalna fala 13 asteroid / 4 myśliwców, lot po Sphere67, sterowanie kierunkiem i celowanie, Pulse (0.16 s), pociski wrogów, kontakt, 25 pancerza / 60 kadłuba, trzy życia, odradzanie, kontakt z asteroidą na poziomie 01 za 18 HP, fizyczne rozpady asteroid, przegrana, warunek zwycięstwa z opóźnieniem Game.cs 0.20 s.
- `CarbonisSession568.swift`: jedna współdzielona symulacja na ekran, krok maksymalnie 1/120s, stan sterowania i aktualizowany HUD wraz z pozycjami dla radaru.
- `Sector01Scene568.swift`: działająca w kodzie scena dotykowa (lewa strona ruch; prawa cel; OGIEŃ), HUD kadłuba, pancerza, życia, liczby wrogów, czasu i radar asteroid/myśliwców, powrót do atlasu.
- `Sector01CarbonisPreview568.swift`: tryb prawdziwej kamery podążającej za źródłowym statkiem, renderowanie oryginalnego VANGUARD431 z prawdziwą siatką i teksturą w autentycznym świecie C279, poruszające się i dzielące asteroidy ze źródłowymi siatkami, rysowanie pocisków bez fałszowania pełnej zgodności efektów z PC.
- `Sector01Carbonis568.metal`: źródłowe osobne potoki GPU statku i pocisków; oryginalne planetarne 810747 indeksów / 2 materiały / 3 tekstury niezmienione.
- `Tests/CarbonisCombat568Tests.swift`: testy stanu gry, startowej fali, prędkości statku, ruchu po sferze, pocisków, kolizji, zwycięstwa po 0.2 s, utraty żyć i niezależności zapisu kampanii.
- Workflow `.github/workflows/build-ios.yml` został na wyraźne żądanie użytkownika uruchomiony przez zmianę i uzupełniony o przywrócenie autentycznych zasobów C279 z 4 archiwów ZIP przed kompilacją Xcode. Publikuje niepodpisany IPA tylko po sukcesie i raportuje numer przebiegu. Aktualny wykryty przebieg: [42246582810](https://github.com/synixad-png/asteroidy-ios/actions/runs/42246582810), commit 388f0d3.

## Potwierdzenia i ograniczenia

- Źródła Windows/SteamOS v568 zostały zweryfikowane w poprzednim etapie przez CRC i przegląd `Game.cs`, `Physics68.cs`, `Campaign37.cs`, `EnemyTactics71.cs`, `Action38.cs`, `GpuSphere67.cs`, `GpuRobot70.cs`.
- GitHub Actions reporter w przebiegu 42246582810 **SUCCESS**; testy poprzedniego przebiegu `verify-sphere-linux` **SUCCESS**.
- W chwili sporządzenia raportu **brak potwierdzonego zakończenia natywnej kompilacji Xcode obecnej rewizji** i brak zweryfikowanego artefaktu IPA. Interaktywnego testu iPhone/iPad również nie przeprowadzono. Nie wolno uważać zmiany kodu za dowód poprawnej grafiki GPU.
- Myśliwce mają rzeczywisty stan AI, HP, pozycje i pociski, widoczne na radarze, ale nie mają jeszcze wiernych modeli 3D `BossMesh65/ShipMesh` w rendererze CARBONIS. Wyświetlanie ich jako innego statku byłoby zabronionym substytutem.
- Testowy wynik zwycięstwa nie aktualizuje zamkniętych danych kampanii; pełna ścieżka PC `FinishLevel`, wynagrodzenia i sektorów 2–25 nie jest jeszcze zintegrowana.
- Tarcza, broń inna niż Pulse, bossowie, audio, menu ustawień, optymalizacja GPU i interaktywne testy urządzenia pozostają niedokończone.
- Aktywna walka na CARBONIS **jest wdrożona w kodzie**, ale nie należy jej nazywać przetestowaną w działającym IPA bez PASS xcodebuild i faktycznego uruchomienia.

## Następna funkcjonalna bramka

1. Zakończyć źródłowy port geometrii myśliwców (GpuRobot70/BossMesh65/ShipMesh), a następnie narysować je na odpowiednich osiach na C279.
2. Uwierzytelnić poprawną kompilację Mac Xcode i działający artefakt IPA, kontrola CRC/Info.plist/Mach-O, native touch tests.
3. Rozszerzać oryginalne misje 2–25, cele, bossów, zasoby, zapis, audio — kolejność A–J.

## Wstępny postęp źródłowy

Cały projekt: **33% wykonane (+2 pp) / 67% pozostało**, ale jest to szacunek implementacji kodu, nie potwierdzonego działania aplikacji na iPhone. W stałej tabeli 18 zadań zmieniły się pozycje 6 (35→41), 9 (10→13), 10 (0→3), 12 (12→18), 14 (15→19), 17 (35→41); pozostałe 12 pozycji bez zmian. Nie zaliczać całego oryginalnego portu jako ukończonego.

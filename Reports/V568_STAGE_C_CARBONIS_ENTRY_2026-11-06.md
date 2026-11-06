# ASTEROIDY iOS v568 — etap C, rzeczywiste wejście do planety CARBONIS

**Data:** 06.11.2026. **Baza:** źródłowy port PC Windows/SteamOS v568.
**Zadanie:** przestać powtarzać testy menu, podłączyć istniejący wybór
26 sektorów do pierwszej rzeczywistej sceny źródłowej.

## Wykonana nowa funkcja w natywnej aplikacji

W W3 HOME akcja **NOWA GRA** i **KAMPANIA** prowadzi do źródłowego
atlasu 26 sektorów. Odblokowany sektor 01 ma teraz przycisk
**WEJDŹ NA CARBONIS 01 / ŹRÓDŁOWA SCENA 3D**. Jego dotknięcie
w `App.swift` uruchamia osobny ekran
`Sector01Scene568.swift`. Nie uruchamia starego Boreas GLB,
treningu dziewięciu asteroid ani obcej, zastępczej geometrii.

Ekran wyświetla prawdziwą siatkę **C279** pierwszej planety z
`Sector01CarbonisPreview568.swift`:
**137067** oryginalnych unikalnych wierzchołków,
**810747** indeksów, **270249 trójkątów**, dwie grupy materiałów
i trzy oryginalne mapy. Zasoby nadal wymagają zgodności sum SHA-256.
Dodatkowo gest palcem zmienia położenie kamery podglądu bez
modyfikacji źródłowych pozycji, UV i siatki modelu.

Przycisk **WRÓĆ DO MAPY** wraca teraz faktycznie do
**atlasu 26 sektorów** (a nie do głównego ekranu W3).
Powrót nie zmienia `completedMask`, wybranego sektora,
osiągnięć, nagród ani zapisów kampanii. Ekran jest oddzielony
od `MetalRenderer` i dotychczasowego diagnostycznego świata Boreas.

## Bezpieczny kontrakt misji i zamrożone mechaniki

`Sector01Entry568.swift` jest osobną, testowaną bramką
przejścia: wymagane są źródłowe zasoby C279, sektor 01
zaznaczony w kampanii i odblokowanie według `MissionUnlocked50`.
Nigdy nie przekierowuje innych 25 sektorów do modelu Carbonis,
nie odblokowuje misji ani nie ustawia bitów jej ukończenia.
Test `Tests/Sector01Entry568Tests.swift` obejmuje wszystkie
26 sektorów, brak zasobów, zablokowane pozycje, reset i
niezmienność stanu.

`Tests/V568W3NativeMenuContract.py` wymaga rzeczywistej
natywnej ścieżki `W3MainMenu568` →
`CampaignAtlas556` → `Sector01Scene568`, z kontrolą
źródłowego atlasu i oryginalnych zasobów. Dotychczasowe
kontrakty kolizji, obrażeń i asteroid pozostają nienaruszone.

## Potwierdzone testy

[GitHub Actions 42225858732](https://github.com/synixad-png/asteroidy-ios/actions/runs/42225858732)
zakończył się **SUCCESS w obu jobach**:

- `Compile iOS source only`: natywna kompilacja
  **Swift/Metal iPhoneOS arm64 PASS**, z oryginalnymi zasobami C279.
- `Verify unlocked-only CARBONIS first sector entry`: **PASS**.
- `Verify source v568 W3 menu start and real navigation contracts`:
  **PASS**.
- Pełna dotychczasowa macierz `Physics68/Damage556/destruction`:
  **PASS**.

**Nie wykonano** nowego pełnego testu rzeczywistego
przeciągania planety na urządzeniu i interakcji całej trasy
`atlas → Carbonis → atlas` w aktualnej wersji. Sama
natywna kompilacja NIE jest dowodem interakcji.

## Zakres jeszcze niewykonany

To jest **natywne wejście w źródłową scenę planety**,
a NIE pełna grywalna misja PC. Nadal brakuje:
`Game.StartHubMission261`, poprawnego `Wave()`,
fizyki lotu po powierzchni Carbonis i kolizji z jego
rzeczywistą mapą wysokości, przeciwników, oddzielnych
elementów HUD dla tej misji, stanu zwycięstwa/przegranej
i postępu 26 grywalnych planet. Nie należy nazywać tego
zakończonym etapem C ani 100% zgodnością.

**IPA:** nie zlecono nowego wydania; dotychczasowy na Dysku
Google nie zawiera tej późniejszej zmiany. Nie wygenerowano
nowego IPA w tej implementacji.

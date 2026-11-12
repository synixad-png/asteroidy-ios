# ASTEROIDY iOS — CARBONIS 01 powtórka, przedmioty, audio i edytor HUD H290

**Data:** 2026-11-12. **Wzorzec:** dostarczony PC v602 / Windows/src. **Harmonogram:** O01–O12 bez zmiany identyfikatorów i zakresów.

## Potwierdzenia użytkownika — osobno od niezależnych testów zgodności

Użytkownik potwierdził na swojej instalacji, że działają: **O02** (lot VANGUARDA), **O03** (strzelnica), **O04** (świat H290), **O06** (dokowanie i powrót H55), **O07** (przejścia orbita/Carbonis/W3). To rzeczywisty odbiór funkcjonalny wskazanych obszarów; nie jest niezależnym numerycznym testem C#↔Swift ani odbiorem wszystkich procedur każdego etapu. Zgłoszone błędy dotyczą powtórki, przedmiotów, audio i możliwości edycji H290.

## Zdiagnozowane i zaimplementowane zmiany

1. **Powtórka sektora 01:** `PC602HomeWorldDriver291.selectMission` zapisuje cel w `CampaignStore556`. `GameView.inspectSourceSector` używał starego `@State campaign`, przez co `Sector01Entry568.open` odrzucał sektor wybrany na H290 po zaliczeniu misji. Teraz przed sprawdzeniem wejścia i przygotowaniem `Sector01PreparedWave568` pobiera rzeczywisty najnowszy `CampaignStore556.load()`, po udanym przygotowaniu synchronizuje UI. Nie modyfikuje maski ukończeń. W PC `Orbit50.cs:89,92` i `W3Campaign316.cs` potwierdzają możliwość ponownego wyboru ukończonej misji.
2. **Przedmioty na powtórce:** PC `Game.cs:136` ogranicza `DropLoot`/monety przez `MissionRewards57`, ale `Tarcza145.cs:26`, `Boost71.cs:9` oraz `CombatSupplyDrops.cs:7–17` wymagają `LootEnabled`, nie braku flagi replay. iOS `CarbonisCombat568` błędnie stosował `!isReplay` i `lootYieldScale>0` do przedmiotów użytkowych. Poprawiono obie ścieżki: ogniwa tarczy, boost, energia jonowa i bomby mogą ponownie wypadać; monety i nagroda za ukończenie pozostają zablokowane na replay. Nie zmieniano algorytmów RNG, częstości, limitów i modeli pickupów.
3. **Zakłócenia dźwięku przy wyborze sektora na H290:** `PC602HomeWorldDriver291.selectMission/cycleMission/refreshCampaign` odświeżały `HUD` bez parametru `weapons`, co zerowało `shotEmissions` i sprawiało, że następny render zgłaszał poprzednie strzały jako nowe. Wszystkie te ścieżki mierzą teraz aktualny `flight+weapons+steppedFrames` pod tą samą blokadą sesji. Nie zmieniono plików ani syntezy audio i nie dodano dublującej ścieżki dźwięków.
4. **EDYTOR HUD / ORBITA:** nowy niezależny profil `PC602OrbitHUDLayout291` edytuje sześć grup źródłowych informacji na H290 (w tym atlas i nawigację) oraz **wszystkie pięć istniejących przycisków funkcyjnych**: OPCJE, ATLAS, CEL+, PAUZA i WEJDŹ. Wejście: H290 → OPCJE → EDYTUJ HUD / PRZYCISKI H290. W edytorze: wybór elementu, przeciąganie, szczypanie, suwaki X/Y/skalowanie, domyślny układ, ZAPISZ i ANULUJ. Zapis działa w UserDefaults po walidacji. Domyślne wartości x=y=0, scale=1 zachowują zatwierdzony obraz. Profil CARBONIS 01 `HudLayout600` i `HudControlLayout600` pozostaje nienaruszony.
5. **Regresje:** `Tests/PC602ReplayHUDRegression291.py` chroni źródłowe rozdzielenie pieniędzy i itemów, świeży wybór sektora, licznik SFX i 11 identyfikatorów edytora; `Tests/PC602OrbitHUDLayout291Tests.swift` sprawdza zapis, odczyt, domyślne pozycje i brak zmiany niepoprawnymi danymi. `Tests/Sector01FullMission568Tests.swift` rozszerzono o realną automatyczną drugą rozgrywkę, wykrywanie użytkowych pickupów i brak monet.

## Zakres testowania i wydania

Kompilacje, testy źródłowe i testy Swift należy potwierdzić na **tym samym SHA** po ostatniej poprawce; wcześniejsza PASS nie potwierdza nowych zmian. Nie wykonano testu wizualnego na sprzętowym iPhonie; taką ocenę przeprowadza użytkownik. Naprawa dźwięku wynika z udowodnionego w kodzie resetu licznika, natomiast zniknięcie objawu na konkretnym urządzeniu wymaga jego testu.

**Stała dyspozycja użytkownika:** **po każdej sesji prac nad portem iOS wygenerować i udostępnić IPA**. Zapewnić wywołanie testowego workflow również po zmianach Carbonis, H290 HUD i edytora; nie utożsamiać unsigned IPA z podpisaną, instalowalną wersją. O09 i pozostałe etapy O01–O12 zachowują ustalone definicje.

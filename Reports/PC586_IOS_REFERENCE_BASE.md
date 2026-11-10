# ASTEROIDY iOS — uzgodniona baza PC v586 (2026-11-10)

## Źródło referencyjne PC (zamrożone)

- Biblioteka: `/Asteroidy_v586_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`
- Dokładna nazwa: `Asteroidy_v586_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`
- Rozmiar: **138 363 319 B**
- SHA-256 całego archiwum: `8fad7f8444321ff91b77bd0dc7bdf50491cad65870df794151ffc586e27c06ff`
- Archiwum: **1855 pozycji, test ZIP CRC PASS**
- W środku: gałęzie Windows i SteamOS, raporty i zasoby źródłowe, modele pickupów.
- Przy wykonywaniu zakresu PC v582–v586 nie używać PC v587–v589 jako zamiennika.

## Cztery oryginalne zasoby w `Shared/assets/pickups/`

| Model | Bajty | SHA-256 | Typy źródłowe z `PickupGlbModels.cs` |
| --- | ---: | --- | --- |
| shield.glb | 478320 | 531f1d49ea9782a2c40ce6870cd308d067461cc5f80cfaefc659f3db4ffe5a62 | Tarcza145, Shield |
| boost.glb | 502996 | 6f7a083b493b029f4907988b55dbf9cdc49c7d5d187e023fa20521319b494362 | Boost71 |
| energy.glb | 506076 | df9c3a85ef45d55d3ce08d9d82ec9ec1f0ec1b8c2cdf06fb35550eb96aa3aca1 | Energy |
| bomb.glb | 483424 | e8787ce4b11c8b44b6b710a93419b0c8cc263cafe27c35e580b0c4cb8bffaaee | Bomb |

Nie zastępować niezweryfikowanych modeli innymi pod taką samą nazwą. Docelowa IPA ma zawierać wszystkie cztery pliki; użytkownik nie może być zmuszony do importu.

## Kod referencyjny i kontrakt implementacji

- `Windows/src/PickupGlbModels.cs`: jeden rejestr, współdzielone zasoby, bez osobnych importerów i bez podwójnego rysowania; fallback proceduralny.
- `Windows/src/CombatSupplyDrops.cs`: pojedynczy niezależny roll deterministyczny, bomb chance: enemy .055 / asteroid big .065, medium .025, small .008; energy: enemy .155 / big .17, medium .09, small .025. Jedna nowa nagroda na jeden zniszczony cel. Life 26 s, limit 96, IonAmmo +40 (limit 300), Bombs +1 (limit 3), właściwe gate'y LootEnabled, MissionRewards57 i aktywna misja.
- `Windows/src/GpuSphere67.cs` i `Windows/src/Menu139.cs`: osobne skale osłona 60%, boost/energy/bomb/monety po 78%; parametr jasności modeli 180%, zakres 0–400%; brak wspólnego suwaka „pozostałe przedmioty”.
- `Windows/src/Controls.cs`: **60 rzeczywistych akcji + 5 wierszy ustawień (65 pozycji)**. Kluczowe indeksy: bomba 7 (R), osłona 21 (V), dopalacz 35 (F). Domyślne mapowania i obsługę konkretnych akcji wyprowadzać z pełnego źródła, nie zgadywać.

## Baza implementacji iOS (nie zastępować)

- Repozytorium: `synixad-png/asteroidy-ios`
- Gałąź przy przyjęciu referencji: `feature/ios-h55-v580-native-entry`
- Commit wejściowy przed audytem: `a83663f3f7e0b298b4bc6be439082cd09a54927f`
- Zachować natywne Swift/Metal, H55/H71, aktualne poprawki rąk i broni, misje, HUD, audio, iPhone/iPad i optymalizacje.
- Obecne `CarbonisCombat568.swift` zawiera jedną mechaniczną pulę tokenów (`tokenPickups`) i aktywne zasoby `ionAmmo`/`bombs`; aktualne `Sector01Scene568.swift` wywołuje `session.useBomb()`. Nie oznacza to przeniesionego dropu GLB Energy/Bomb.
- Nie wolno implementować PC v587–v589 HUD 3D, planetarium, edytora HUD, regulacji całego HUD w ramach tej integracji.

## Stała kolejność integracji (bez pozornej realizacji)

1. Pełny audyt i porównanie PC v586 ↔ iOS
2. Dołączenie czterech GLB i podłączenie ich do istniejącego systemu przedmiotów
3. Jasność 0–400%, domyślnie 180%
4. Prawdziwe losowanie Energii i Bomb
5. Powiązanie z autentycznym zapasem IonAmmo i Bombs
6. Niezależne skale pięciu kategorii (cztery przedmioty + monety)
7. Audyt 60 akcji sterowania
8. Wspólny router: urządzenie → akcja → istniejąca mechanika, konflikty i trwały zapis
9. Przewijane menu 65 pozycji
10. Migracja ustawień
11. Regresje, testy GPU, iPhone/iPad, wydajność i niezmienność HUD/H55/H71
12. IPA po udanej implementacji i weryfikacji (ARM64, zasoby, SHA, raport).

**Stan na utworzenie dokumentu:** baza PC sprawdzona (ZIP/CRC/SHA, cztery GLB i wybrane źródła), audyt aktualnego portu rozpoczęty. Żaden z punktów 2–12 nie został zaliczony jako ukończony. Ten dokument nie wprowadza żadnych zmian funkcjonalnych, nie tworzy IPA ani nie zmienia numeru wydania.

### Definicja ukończenia

Sukces kompilacji lub dodanie pozycji w menu NIE oznacza działającej funkcji. Każda ukończona funkcja wymaga rzeczywistego działania w mechanicznym modelu gry, testów odpowiednich do zakresu i wyraźnej informacji o brakujących testach fizycznych urządzeń Apple. Zachować modularność; nie dublować renderera, importera, mechaniki zasobów i mapowania wejścia.

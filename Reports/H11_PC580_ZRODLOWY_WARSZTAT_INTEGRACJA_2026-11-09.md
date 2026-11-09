# ASTEROIDY iOS — H11 / warsztat, serwis, uzbrojenie, profile: pierwsza rzeczywista integracja
Data: 09.11.2026 | baza: PC v580 oraz iOS H10 | gałąź: feature/ios-h55-v580-native-entry (PR #28)

## 1. Materiał źródłowy — wyłącznie oryginalny Windows PC v580
Archiwum **Asteroidy_v580_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip**, źródła:
- `Windows/src/Hub90.cs` (SHA256 `a908a3632d22fab0932798405e0d0faff39334e2f1298d9e2d607d5b42587a4d`), `OpenHubPanel90`, `HubServiceMissing95`, `HubServicePrice95`, `HubService95`, `HubWeaponOwned90`, `HubEquip90`, `HubWalkInteract375` i wybór stanowisk 0..5.
- `Windows/src/HubWalk375.cs` (SHA256 `a8a1a4d49dcfada5f56cf345d0a8fbc9ca15e52a44add713cbedc9512fa43980`), prawdziwa odległość od konsoli H55 (9.4, 9.85), promień 3.55m i fallback `HubWalkInteract375`.
- `Windows/src/Game.cs` (SHA256 `8c269f1cc9b70799e3312c2dc53a85406b2ce21827647290cebb2f66c47e5c14`), `Buy(4)`, `Price(4)=12`, `Available`, `Equip`, `ShopProfile56`.
- `Windows/src/ShopProfile56.cs` (SHA256 `f303556e1678b5e7758ab68111bf4ca5b0d9d94e6d35af989d944ea8e5f1eba3`), zapis żetonów, zakupów, typu broni i osłon; `SaveManager61.cs` oraz `Talents78.cs`.
- `Windows/src/Modules97.cs` (SHA256 `dee2f806b778c8780b010248e7c5cec5d3f3508971b653a193efd2c5ca66bb01`), pięć źródłowych modułów, minima sektorów i wzory ceny dla rang 0..2.
- `Windows/src/Talents78.cs` (SHA256 `e71d11d7e1a0d20e7c7eedc5a47f0fa94cfe628339b8b7d1258d938c425546ed`), bazowe HP/pancerz 60/25 i koszt talentów 1/2/3/4 trofeów.
- `Windows/src/Campaign37.cs` (SHA256 `7418d8622bbe2a7b68c33823698572ebc011879c4576922bb58128c000b68874`), wszystkie sześć oryginalnych statków i koszt VANGUARD X 240, TITAN 420, MAMMOTH 620.
- `Windows/src/RendererW3Hub320.cs` (SHA256 `43a53011174de69d977ec27ab8c55471ec18c03f584bfd241a82640604897a39`), autentyczny układ sześciu stanowisk.

## 2. Faktycznie zrealizowane funkcje H11
1. `ASTEROIDYiOS/H55Workshop580.swift`: funkcje biznesowe tylko dla udowodnionych operacji obecnego pierwszego sektora, podłączone do **tego samego** `Sector01Shop568.State` co żywy silnik CarbonisCombat568, bez fikcyjnego portfela. Autentyczne bronie: pulse/twin/scatter, zakup 45/80 żetonów i darmowe ponowne wyposażanie, brak naliczenia żetonów przy odmowie. Źródłowa pasywna osłona kosztuje 12 żetonów za ładunek i ma limit 3 sztuki; `Game.Buy(4)` sprawdzane przez wspólne `shop.buy(.shield)`. Naprawy kadłuba i pancerza przy ubytku są bezpłatne, a przy maksymalnym stanie odmawiane.
2. `ASTEROIDYiOS/H55WorkshopPanel580.swift`: wszystkie **sześć prawdziwych nazw paneli** PC W3, źródłowe opisy i kwoty, przyciski wykonawcze tylko dla faktycznie wspieranych efektów; reszta czytelnie zablokowana. Tło wspólnego renderowanego GLB widoczne pod UI, nie zastąpione imitacją ani zrzutem.
3. `ASTEROIDYiOS/H55ScenePage580.swift`: dostęp do stanowisk w czasie działania prawdziwego H55; brak naruszenia dotykowego rozglądania/strzałów/Foot IK. Otwarcie z pobliża komputera (X=9.4, Z=9.85, odległość poniżej 3.55m) wybiera SERWIS (PC panel 4), poza komputerem wybiera STATEK (PC panel 0). Zamknięcie wraca do tej samej sceny. Ruch gracza blokowany przy otwartym panelu; NPC H08 nie jest zastępowany teleportem.
4. `CarbonisCombat568.swift`: w momencie prawdziwego startu misji odczytywany jest zapisany kadłub/pancerz, a nie tylko etykieta HUD. `Sector01Scene568.swift` przekazuje przy wyjściu oraz zakończeniu rzeczywiste cztery parametry (lives/shields/hull/armor); `App.swift` zapisuje stan gry. `App.swift` przy nowej grze zeruje pozostałości uszkodzeń poprzedniego profilu. Osłony i wybrana broń nadal są wyłącznie stanem `Sector01Shop568`, natychmiast używanym przez faktyczny silnik C279.
5. Ceny modułów `[90,75,130,150,170]` oraz przyrost na rangę `[100,90,120,130,140]`, progi sektorów `[3,2,5,6,8]`, rangi 0..2, poprawne nazwy sześciu statków i stopniowanie talentów 1..4 są odwzorowane w sprawdzalnym kodzie i na ekranie.

## 3. Granice funkcjonalności — brak atrap
- iOS udostępnia aktualnie **rzeczywiście grywalny sektor CARBONIS 01**. Nie istnieją jeszcze wszystkie misje PC v580, sześć silników/pełnych modeli statków, uzbrojenie Rail/Swarm, źródłowe 5 modułów z fizycznymi skutkami ani wypłata trofeów v78. Dlatego odpowiednie operacje H11 nie pobierają żetonów i nie udają wykonania.
- Schemat PC `ShopProfile56` i podpis `SaveManager61` nie są obecnie importowane/eksportowane jako identyczny plik Windows; iOS używa właściwego i już działającego `Sector01Shop568` oraz osobnego, trwałego `H55Workshop580.Vitals` dla dokładnie tych pól, które silnik odczytuje.
- Brak deklaracji 100% H11, ponieważ ponad połowa docelowego zakresu oryginalnego warsztatu zależy od niewdrożonej rozgrywki późniejszych sektorów. Nie przechodzić do H12 bez jawnego odnotowania ograniczeń.
- W H11 nie zmieniano geometrii H02–H05, H06 ruchu/sterowania, H07 śluz, H08 trasy, H09 animacji, H10 dialogu ani shaderów, zamrożone mechanizmy wymagają regresji.

## 4. Testy
- `Tests/H55Workshop580Tests.swift`: wszystkie nazwy i ceny źródłowe, 3 operacje serwisu, zero opłat za maksymalny stan, brak żetonów, max 3 osłony, źródłowe transakcje broni, odmowa operacji niezaimplementowanych, bezpieczny format/czytanie/zerowanie zapisanych żywych vitals. GitHub [H11 szybki test źródła 42580285574](https://github.com/synixad-png/asteroidy-ios/actions/runs/42580285574) **PASS**.
- [H11 pełna bramka H01–H11 42580103040](https://github.com/synixad-png/asteroidy-ios/actions/runs/42580103040) **testy źródłowe PASS**; wynik natywnego kompilowania iOS ARM64 / IPA odnotować osobno po faktycznym ukończeniu.
- `verify-combat-only.yml`: dodano zależność rzeczywistego stanu H11 do pięciu istniejących testów Linux C279, bez usuwania istniejących modułów. Status pełnej regresji po ukończeniu.

## 5. Status uczciwy
H11 — **35%** szacunkowo (pierwszy działający zakres na istniejącym porcie sektora 01). Wymaga odrębnych funkcji misji, statków, modułów i trofeów dla pełnego oryginalnego PC v580. Odbiór dotykowy i FPS na urządzeniu nadal H15. Zachowano stałe H01–H16.

# ASTEROIDY iOS — PC v586: migracja profili sterowania, spójność H55 i kontrola regresji

Data: 2026-11-10. Baza: zatwierdzony ZIP PC v586 + dotychczasowy Swift/Metal w gałęzi `feature/ios-h55-v580-native-entry`. Bez aktualizacji HUD z PC v587–v589 i bez zmian oryginalnego modelu świata.

## Wdrożone i przetestowane
1. `SourceControls586.Profile` ma spójną, pojedynczą dekodującą ścieżkę profilu JSON. Stare zapisy z indeksami 0–9 lub 0–37 zachowują własne `keys` i `pad`, otrzymują brakujące akcje PC v586 oraz brakujące opcje urządzenia z zatwierdzonych wartości domyślnych. Nie powstaje równoległy format zapisu.
2. Zapis migruje do schematu 2 w sposób idempotentny i nie usuwa własnych przypisań. Nieobsługiwane przyszłe wersje formatu są odrzucane; losowe niekompletne tablice nie powodują wyjścia poza indeksy.
3. Import `ASTEROIDY_CONTROLS_1` odrzuca nieprawidłowe pole odwrócenia pionowej osi (musi mieć 0/1); nie dokonuje częściowego zapisu.
4. `SourceControls586` zachowuje dokładnie 60 oryginalnych akcji i 5 dodatkowych pól; `SourceControlRouter586` pozostaje jednym routerem dla sprzętu i istniejących akcji, bez powielania silnika gry.
5. `SourceControlSettings586` jasno oznacza jedyną działającą dodatkową opcję (martwa strefa, pozycja 60) i pozostałe ustawienia atlasu/myszy (61–64), które są przechowywane dla późniejszego portu, lecz nie mają jeszcze działającego odbiorcy w misji/H55.
6. Zgodność PC: tarcza i dopalacz mają oryginalny wspólny przycisk pada B7. **To konflikt oryginalnych przypisań.** Menu wyświetla go, a test pilnuje, aby domyślnych wartości nie zmieniano bez decyzji użytkownika.
7. Dwa historyczne testy H11 wymagały starego wyrażenia `showingWorkshop ? 0 : moveForward`; kontrole zaktualizowano do rzeczywistych bramek `arrival.walking`, `conversationOpen`, `showingWorkshop` oraz miksowania dotyku i sprzętu oddzielnie dla przód/tył i lewo/prawo. Zakres H55 fizyki i kolizji nie został zmieniony.
8. Wcześniejsze korekty `A2/A3` obsługują rzeczywiste zmiany przypisań osi w misji i H55. Nie usunięto radialnej martwej strefy celowania po przekątnej.

## Testy — tylko wyniki faktycznie potwierdzone
- `42796516161` — kontrola 60 akcji, routera, 65 wierszy, importu i migracji — **PASS** na commicie `739f0ea349b8de322864c22b57d4ae67ff7ac558`.
- `42796523596` — Code Quality / No Slop — **PASS** na tym samym commicie.
- `42795460162` — oryginalne operacje sklepu H11 / źródła — **PASS** po aktualizacji kontraktu.
- `42795465434` — kontrola H11 sceny/warsztatu — **PASS**; pełna niezależna kompilacja tej gałęzi jest osobną bramką.
- Ostatnie pełne regresje `verify-combat-no-ipa` / ARM64 i `H11` Release mogą jeszcze trwać. Brak wyniku końcowego nie jest PASS.
- Żadnych testów fizycznego iPhone/iPada, ergonomii, FPS 60 ani rzeczywistej gry z nową IPA — użytkownik wyraźnie odroczył testy wizualne.

## Harmonogram PC v586 (niezmienne 12 etapów)
| Etap | Uczciwy stan |
|---|---:|
| 1. Audyt PC v586 | 100% |
| 2. Cztery modele GLB | 90% |
| 3. Jasność modeli | 85% |
| 4. Wypadanie przedmiotów | 95% |
| 5. Integracja zdolności | 95% |
| 6. Niezależne skale | 85% |
| 7. Audyt 60 akcji | 100% |
| 8. Router sterowania | 80% |
| 9. Menu 65 pozycji | 90% |
| 10. Migracja ustawień | 95% |
| 11. Testy i regresje | 65% |
| 12. IPA i weryfikacja | 55% |

Średnia etapów około 86%, ale testy na urządzeniach nadal nie zostały zaliczone. Nie utożsamiać tej średniej z procentem portu wszystkich mechanik 60 akcji PC; w iOS pozycje nieportowanych funkcji pozostają tylko konfiguracją.

## Następny krok
Zamknąć końcową macOS ARM64 / H55 / CARBONIS regresję najnowszych źródeł; zablokować wydanie niezweryfikowanej IPA; dokończyć poprawki funkcjonalne tylko w obrębie tych mechanik, które rzeczywiście występują w iOS. Po powrocie testów urządzeniowych osobno potwierdzić jakość oraz wygląd.

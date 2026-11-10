# ASTEROIDY iOS — audyt i poprawki sterowania PC v586
Data: 10.11.2026

## Baza i zakres
- Referencyjne PC: `Asteroidy_v586_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`. Nie importować zmian PC v587–v589 (HUD3D).
- Baza wykonawcza: bieżąca gałąź Swift/Metal `feature/ios-h55-v580-native-entry`.
- Cel: kontynuacja bez fizycznych testów wizualnych iPhone/iPad zgodnie z życzeniem użytkownika; nie mylić testu źródeł z testem na rzeczywistym sprzęcie.

## Wynik audytu 60 akcji + 5 opcji
- `SourceControls586.swift`: dokładnie 60 indeksów i profili klawiszy/pada, pięć oryginalnych opcji wejściowych, brak zastępczych akcji kooperacji i nieportowanych trybów.
- `SourceControlSettings586.swift`: jedna przewijana lista 65 pozycji w natywnym menu W3, edycja klawiszy i padów, sygnalizacja konfliktów, reset i import profilu PC.
- `SourceControlRouter586.swift`: pojedyncza ścieżka wejścia, zdarzenia przy naciśnięciu bomby/dopalacza/pauzy i ciągłe przytrzymanie tarczy, bez drugiego timera i symulacji.
- `SourceHardwareInput586.swift`: klawiatura HID i GameController, opakowanie danych wejściowych i przekazywanie do istniejących źródłowych mechanizmów misji i H55.
- Import starych `ASTEROIDY_CONTROLS_1` i `ASTEROIDY_CONTROLS_2` oraz dodatkowego `ASTEROIDY_FLIGHT_67`; test odrzuca błędne formaty. Dane zapisywane w UserDefaults.
- Mechaniki **rzeczywiście portowane**: CARBONIS ruch, celowanie, strzał, bomba, pauza, aktywna Tarcza145, Boost71; H55 spacer, sprint, skok, interakcja, kamera. Pozostałe z 60 oryginalnych działań są na liście, ale mają status **NIEPRZENIESIONE / PC**, a nie udawany przycisk w grze.

## Poprawione regresje i błędy
1. `Tests/IOSSourceCombatPause568Contract.py`: dotychczasowy stary test sprawdzał dokładne wywołanie `game.step(move:move,aim:aim,shooting:shooting,...)`, które od czasu dodania prawdziwego routera wejścia zostało zastąpione `effectiveMove/effectiveAim/effectiveFire`. Kontrola nowej funkcji zachowuje wymaganie bramki pauzy i oryginalnych kroków fizyki 120Hz zamiast łagodzenia testu.
2. `SourceControls586.Snapshot.boundAnalog`: akcje prawego drążka **33/34** sterowały wcześniej w grze zawsze z surowych A2/A3 mimo dostępnych w menu zmian przypisań. Teraz odczytują oryginalne konfigurowalne profile pad/klawiatura.
3. Martwa strefa w CARBONIS zostaje **radialna**, czyli 25% na X i 25% na Y daje łączne wychylenie >30% i nadal płynne celowanie ukośne. Nie wolno przywracać błędnego filtrowania każdej osi osobno.
4. `SourceControlRouter586.readHangar`: kamera H55 też używa tych samych konfigurowalnych indeksów 33/34, bez własnej sztywnej mapy A2/A3. Zachowano dotychczasowe, osiowe odcięcie drgań w H55.
5. `SourceControlSettings586`: akcje 33/34 są prawdziwie dostępne w obu scenach i mają jednoznaczny status „DZIAŁA / MISJA 01 + H55”.
6. Testy: rzeczywiste przemapowanie na A0/A1, odwrócenie kierunku, przypisanie przycisku oraz zachowanie domyślnej osi i granicy deadzone, weryfikacja w jednym routerze CARBONIS/H55.

## Weryfikacja
- GitHub Actions [42792433525](https://github.com/synixad-png/asteroidy-ios/actions/runs/42792433525), końcowa automatyczna regresja **60+5** — **PASS**.
- GitHub Actions [42791386990](https://github.com/synixad-png/asteroidy-ios/actions/runs/42791386990), pełne starsze testy mechaniki i kompilacja ARM64 — **PASS** po naprawie starszej asercji pauzy.
- Kontrole jakości No Slop na kolejnych commitach — **PASS**.
- Zewnętrzna fizyczna klawiatura/pad na iPhonie/iPadzie oraz 60 FPS i odczucia sterowania nie były testowane; nie oznaczać ich jako PASS.

## Pozostałe zależności
- Mechaniki 60 akcji PC poza dostępnym portem misji/H55 nadal wymagają rzeczywistego zaimplementowania odpowiednich systemów gry; sam zapis klawisza nie wystarcza.
- Dynamiczna zmiana profilu w trakcie JUŻ uruchomionej misji wymaga ponownego przeładowania ustawień albo ponownego wejścia do misji — bez nadmiarowego odczytu UserDefaults co klatkę.
- Natywny test z urządzeniem jest osobną bramką akceptacji; użytkownik odłożył go na później.
- Nie wydano nowej IPA w tym kroku; brak obietnicy niezweryfikowanego wydania.

## Następne zadanie
Sprawdzić pełną regresję walki na aktualnym commicie. Następnie ukończyć migrację ustawień i testy zmiany profilu między misjami, zapewnić powtarzalne budowanie iOS i nie powodować regresji H55/H71 ani zaakceptowanego HUD.

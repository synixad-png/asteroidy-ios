# O05 — HUD H290, atlas, pauza i OPCJE — źródłowa korekta komunikatów

Data: 2026-11-12. **Obowiązujący, niezmieniony harmonogram**: `Reports/PC602_IOS_H290_STALY_HARMONOGRAM_2026-11-12.md` — `O05`. Użytkownik wyraził zgodę na przejście do następnego etapu przed odbiorem O04 na urządzeniu. O04 pozostaje W TOKU; O01–O12 nie zostały przenumerowane.

## Zweryfikowane oryginalne źródło Windows PC v602

Oryginalny użytkownika ZIP, `Windows/src/Orbit50.cs`, SHA256 `8154038327fd78129cd8678bc482103f78bfa5e5c9756b344790cdba73aee5de`, `DrawOrbit50` (linie 145–159):

- `"STREFA "+OrbitWorld50.Zone(...).ToString("00")` (dwie cyfry).
- `"POSTĘP "+OrbitHud330.Completed(game).ToString("00")+" / "+Game.AtlasMissionCount276.ToString("00")` (postęp **ukończonych** misji, dwie cyfry).
- `courseText=unlocked?(int)Math.Abs(course)+"° "+(course<0?"W LEWO":"W PRAWO"):"NIEDOSTĘPNA"` — brak sztucznego kursu przy zablokowanym celu.
- `if(MissionCompleted50(target))... else if(!unlocked) Text("ODBLOCKUJ POPRZEDNIĄ MISJĘ")`.

**Potwierdzona rozbieżność**: istniejący `PC602HomeWorldPage291.swift` wyświetlał `STREFA 1`, `POSTĘP 0 / 26`, kurs nawet dla zablokowanego celu i brak źródłowej informacji o blokadzie.

## Minimalna poprawka

- Dodano trzy deterministyczne formatujące funkcje do istniejącego `PC602OrbitHud330` i użyto ich bezpośrednio w aktywnym HUD-zie oraz otwieranym atlasie.
- Przy zablokowanym wybranym sektorze przywrócono źródłowy napis `KURS: NIEDOSTĘPNA` oraz `ODBLOCKUJ POPRZEDNIĄ MISJĘ`.
- Dodano sprawdzenia kierunków kursu, ucinania dziesiętnych części, dwóch cyfr, wartości 00 i 26 oraz blokady celu w `Tests/PC602OrbitHud330Tests.swift`.
- **Nie zmieniono** geometrii HUD/F6, położenia planetarium, liczby markerów 26, fizyki, wyboru celów, przycisku OPCJE, pauzy, W3, sterowania dotykowego ani dostępności misji 02–26.

## Stan testów i ograniczenia

Test Swift dotyczący formatu HUD uruchamiany jest w istniejącym workflow `verify-pc602-wreck-dock209.yml`. Kompilacja Swift/Metal i pozostałe kontrakty są nadal odrębne. **O05 W TOKU**: warunki pauzy, menu OPCJE i interaktywny atlas na urządzeniu nie zostały jeszcze odebrane. Nie ogłaszać zgodności 100% bez porównania rzeczywistego ekranu PC↔iOS.

## 12.11.2026 — Klawisze kompaktowego atlasu zgodne z OrbitClick51

Oryginalny `Windows/src/Orbit50.cs:92` `OrbitClick51` obsługuje kliknięcie w dowolny z 26 małych kafelków `OrbitHud330.Hit(x,y)` pod warunkiem `Mode==Orbit` i `MissionUnlocked50(n)`, **bez uruchamiania misji**. W iOS kompaktowa siatka w HUD pokazywała właściwe sektory, ale była nieinteraktywna (`.allowsHitTesting(false)`), w przeciwieństwie do PC. Poprawiono to bez zmiany szerokości kafelków, kolorów i siatki: każdy istniejący kafelek jest teraz przyciskiem wyłącznie do wyboru odblokowanego sektora podczas lotu. Nie dotyczy uruchamiania misji — do tego nadal służy oryginalny warunek wejścia. Duży atlas dotykowy pozostaje dostępny. Dodano kontrakt źródłowy sprawdzający zachowanie obu siatek i brak przełącznika blokującego obsługę dotyku. Test na rzeczywistym iPhonie/iPadzie należy przeprowadzić po utworzeniu IPA; O05 pozostaje W TOKU.

## 12.11.2026 — O05 pauza: porównanie rzeczywistych procedur PC602

Odczytane bezpośrednio z archiwum użytkownika SHA256 `359abd889544c846faa9426fd291df8528951ed2253fe67c47dbb9e9d9f2103b`:

- `Windows/src/BossTunnelGame.cs:48-50`: `Pause()` zatrzymuje żywą orbitę przez `PausedFrom=Mode.Orbit` i `Mode.Paused`; `Resume()` przywraca `Mode.Orbit`.
- `Windows/src/RendererW3Pause317.cs:7-53`: rzeczywista nakładka wstrzymanej gry ma układ 2×3 oraz nazwy `KONTYNUUJ`, `WYJDŹ DO MENU`, `ZAMKNIJ GRĘ`, `ZAPISZ`, `WCZYTAJ`, `WYNIKI`.
- `Windows/src/Program.cs:197-201`: pauza klawiszem akcji 9/ESC, Resume oraz powrót do oryginalnego menu; `Program.cs:110-122`: niezależny widok OPCJI zatrzymuje lot i przy powrocie przywraca poprzedni stan; `Program.cs:36`: utrata aktywności okna zatrzymuje grę.

**Potwierdzona różnica:** aktywny `PC602HomeWorldPage291.swift` miał `OPCJE` i zapisy, lecz nie miał przycisku `PAUZA`, samodzielnej nakładki wstrzymania ani obsługi źródłowego klawisza pauzy w H290. Istniejący XCUITest wymagał przycisku, którego nie było.

**Minimalny port O05:** przycisk PAUZA obok istniejących przycisków atlasu, nakładka oryginalnych sześciu poleceń nad żywą sceną Metal, bez drugiego zegara i drugiego stanu fizyki; dotykowe KONTYNUUJ i WYJDŹ DO MENU, ZAPISZ/WCZYTAJ z powrotem do pauzy; ESC, skonfigurowane klawisze akcji 9 i 27, blokada powtórzonych zdarzeń klawiatury, zatrzymanie po przejściu aplikacji w tło. Powrót do W3 nadal wykonuje istniejący, prawdziwy `App.swift` callback (CaptureResume61/stop/W3), bez atrap.

**Ograniczenia:** `ZAMKNIJ GRĘ` nie jest uruchamiane na iOS (aplikacja nie powinna programowo kończyć procesu), a `WYNIKI` czeka na port źródłowego ekranu wyników: oba przyciski wyświetlane jako niedostępne, nie jako działające atrapy. Pełna obsługa klawiszy na fizycznej klawiaturze/iPhonie oraz rzeczywisty obraz pauzy pozostają do testów urządzeniowych. O05 nadal W TOKU; testy i status kompilacji należy oceniać na nowym SHA, nie dziedziczyć wyniku wcześniejszej IPA.

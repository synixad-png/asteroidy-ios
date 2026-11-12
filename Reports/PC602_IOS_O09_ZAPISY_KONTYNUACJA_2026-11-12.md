# O09 — ASTEROIDY iOS: zapisy i kontynuacja gry (PC v602)

**Źródło referencyjne:** oryginalna paczka użytkownika `Asteroidy_v602_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`, SHA-256 `359abd889544c846faa9426fd291df8528951ed2253fe67c47dbb9e9d9f2103b`. Wyłącznie `Windows/src/`. Wdrażany etap to O09, identyfikator i nazwa w `PC602_IOS_H290_STALY_HARMONOGRAM_2026-11-12.md` pozostają niezmienione; użytkownik polecił przeskoczyć z O05 do O09 bez odbioru O06–O08.

## Potwierdzone oryginalne zachowanie PC602

- `SaveManager61.cs:39,41,43-46`: trzy sloty indeksowane 0–2 (`slot1.sav` ... `slot3.sav`); zapis atomowy i SHA-256; `Snapshot61` zapisuje stan kampanii, sklepu, wyposażenia i lotu. Podczas Orbit/Shop/Intro zapis bieżący, w Playing/Tunnel/Menu ostatni zweryfikowany `checkpoint61`.
- `SaveManager61.cs:48-85`: `ReadSlot61` odrzuca zły rozmiar, podpis, datę, GUID, pola, pozycję, kurs, wyposażenie i dane modułów. Pusty slot i uszkodzony plik to odrębne stany.
- `SaveManager61.cs:86-87`: odtworzenie sprawdzonego zapisu i usuwanie konkretnego slotu.
- `SaveManager61.cs:94-105` i `RendererW3Save316.cs:52-77`: wybór jednego z 3 slotów; operacje `ZAPISZ / WCZYTAJ / USUŃ`; potwierdzenie nadpisania, usunięcia i wczytania do aktywnej gry, z opcją anulowania. Podczas menu wczytanie nie wymaga osobnego potwierdzenia.
- `ProgramW3Native315.cs:221-230`: `NativeContinue358` daje pierwszeństwo poprawnym ręcznym zapisom; jeśli ich nie ma, wywołuje `ContinueActive358`.
- `SaveManager61.cs:25-35`, `Intro41.cs:25-27`: `ContinueActive358` przywraca zweryfikowany aktywny profil i uruchamia kampanię nawet bez ręcznego slotu i bez zapisu ostatnich współrzędnych; nie archiwizuje tego samego profilu przy każdym wznowieniu.

## Potwierdzone rozbieżności sprzed O09

- `PC602HomeWorldPage291.swift`: kafelek slotu wykonywał bezpośrednio zapis albo wczytanie, brakowało odrębnego wyboru akcji, potwierdzenia nadpisania/usunięcia/wczytania i funkcji kasowania.
- `PC602OrbitSave61.swift`: brak funkcji usuwania oraz odróżnienia uszkodzonego pliku od nieistniejącego slotu w ekranie gry.
- `W3MainMenu568.swift`: W3 nie otwierało prawdziwych slotów manualnych i preferowało automatyczne `resume.json`, inaczej niż PC.
- `SourceNewGame568.swift`: przy automatycznej kontynuacji powstawała kolejna kopia aktywnego profilu, czego nie robi `ContinueActive358`. Przy braku poprawnego `resume.json` W3 nie udostępniało kontynuacji mimo istniejącego aktywnego profilu.

## Wdrożone w O09

1. W `PC602OrbitSave61.swift` dodano `slotFileExists`, `deleteSlot`, `hasManualSave`. Usuwanie nie obejmuje automatycznego `resume.json`.
2. Dodano jeden współdzielony `PC602SaveSlots61View.swift` do W3 i H290, zachowując dokładnie trzy sloty i trzy oryginalne akcje. Jest potwierdzenie i anulowanie, także przed nadpisaniem pliku uszkodzonego. Poprawne sloty są odróżniane od pustych i uszkodzonych.
3. `PC602HomeWorldPage291.swift`: dotychczasowe `ZAPISZ LOT` / `WCZYTAJ LOT` wywołują wspólny panel z obecnym sterownikiem, bez nowej kopii fizyki ani sesji.
4. `W3MainMenu568.swift` i `App.swift`: W3 najpierw otwiera ręczne sloty, gdy istnieje prawidłowy zapis, a wczytanie przywraca rzeczywistą sesję H290, profil kampanii i oryginalne źródła lotu.
5. `SourceNewGame568.swift`, `PC602HomeWorldDriver291.swift`: automatyczne wznowienie nie archiwizuje profilu podczas każdego otwarcia. Zapis z innej kampanii nie może automatycznie nadpisać aktualnej. Ręczne wczytywanie zachowuje istniejący mechanizm archiwizowania profilu.
6. `SourceNewGame568.canContinueActive358` weryfikuje rzeczywiste bajty profilu sklepu, stanu H55, wyposażenia i identyfikator bieżącej kampanii przed kontynuacją. Jeżeli nie ma poprawnego `resume.json`, W3 może przywrócić istniejący aktywny profil przez `homeWorld291.start`, zamiast z góry blokować kontynuację.
7. Zmieniono kontrakt `PC602OrbitSave61Contract.py` i dodano ścieżki slotów do prawdziwego `PC602HomeOrbitUITests.swift`. Testy źródłowe nie są dowodem działania na iPhonie.

## Ograniczenia — O09 NIEODEBRANE

- Format iOS nadal jest podpisanym SHA-256 JSON; źródłowy Windows `.sav` `ASTEROIDY-SAVE-369` ma inny format i **nie jest bezpośrednio wczytywany** przez iOS.
- PC `Snapshot61` zawiera więcej pól (m.in. `Score`, `ReplayMission57`, `TarczaEnergy145`, pełną semantykę `TalentState78` i `ModuleState97`) niż obecny częściowy natywny snapshot iOS. Brakuje pełnej zweryfikowanej macierzy pól i odpowiedników dla wszystkich stanów PC.
- Zapis punktu kontrolnego podczas aktywnej rozgrywki CARBONIS 01 (`Mode.Playing/Tunnel`) i odtwarzanie jej pełnego stanu oraz analogiczny zapis `Mode.Shop/Intro` nie są zakończone. Nie wolno deklarować ich gotowości, dopóki nie będą portowane na podstawie źródeł PC v602.
- Weryfikacja fizyczna iPhone/iPad: zapis→zakończenie procesu→uruchomienie→kontynuacja; corrupt/empty/overwrite/delete, odtworzenie i rollback profilu, test PC↔iOS, H55/CARBONIS, pozostają do przeprowadzenia.
- Status testu ARM64 i symulatora należy każdorazowo odczytać z **aktualnego SHA**, nie dziedziczyć PASS ze starszej kompilacji. Nie uznawać ukończonej kompilacji za test sprzętowy. Bez podpisanej IPA nie ma potwierdzonej instalacji na fizycznym urządzeniu.

**Status harmonogramu:** O09 = W TOKU, KOD ROZSZERZONY, PEŁNY ODBIÓR NIEOSIĄGNIĘTY. O01–O08 oraz O10–O12 pozostają bez modyfikacji ich definicji i statusu wynikającego ze stałego harmonogramu.

## O09 — korekta odbioru automatycznego profilu (kolejny commit)

**Zidentyfikowany błąd:** `SourceNewGame568.create` czyści klucze `vitalsKey` i `mechanicsKey` przez istniejące `resetVitals/reset`. Natomiast pierwotna implementacja `canContinueActive358` z O09 wymagała obecności obu kluczy, więc blokowała poprawną świeżą kampanię po restarcie. W PC602 `SaveManager61.ContinueActive358` profil automatyczny nie wymaga ręcznego slotu, a początkowy stan H55 jest prawidłowy.

**Poprawka:** `canContinueActive358` nadal wymaga rzeczywistego identyfikatora kampanii i poprawnie zdekodowanego profilu sklepu. Brak rekordu H55 traktuje jako prawidłowy stan domyślny, zgodnie z `SourceNewGame568.create`; obecny rekord H55 jest rygorystycznie dekodowany i walidowany, a nieprawidłowy `Data`, typ lub niedostępny w porcie iOS model statku skutkują odmową kontynuacji. Dodano regresje do `SourceNewGame568Tests.swift` dla świeżej kampanii, uszkodzenia obecnych rekordów oraz odrzucenia wybranego nieobsługiwanego statku.

**Wersja IPA sprzed tego commita:** artefakt unsigned test z commita `1a813af3bddc9d7dcb22bd981ef2dc641e8967cc` (przekazany użytkownikowi w tej rozmowie) nie zawiera powyższej późniejszej poprawki. Dalszy odbiór O09 wymaga jej kompilacji i testów; stara IPA nie może być przedstawiana jako nowsza.

## Korekta audytu zależności O09 — źródła PC v602

**Poprzednie twierdzenie, że pełną mechanikę zapisów O09 trzeba odłożyć do ukończenia O07/O08, było nieprawidłowe.** Te etapy są potrzebne do testów integracyjnych scen, ale oryginalna mechanika zapisu punktu kontrolnego jest określona w PC v602 i może być wdrażana niezależnie. Kwestie wizualne weryfikuje użytkownik; nie wolno używać ich jako blokady prac programistycznych.

Zweryfikowano bezpośrednio w archiwum użytkownika, gałąź `Windows/src/`:

1. `SaveManager61.cs:42–43` (`ShopLines61`, `Snapshot61`): 17 wartości `meta`, profil sklepu, 11 wartości `orbit` (pozycja, kierunek, prawa oś, yaw, pitch), `TalentState78`, `ModuleState97`, `TarczaEnergy145`, suma SHA-256.
2. `SaveManager61.cs:44–46` (`CaptureResume61`, `RefreshCheckpoint61`, `SaveSlot61`): tryby `Orbit/Shop/Intro` zapisują aktualny zweryfikowany snapshot; podczas `Playing/Tunnel/Menu` zapisuje się **ostatni `checkpoint61`**, nie stan każdej klatki walki. Bez checkpointu zapis jest odrzucany.
3. `Intro41.cs:28` (`BeginLevelIntro`): ustawia `Mode.Intro`, następnie `RefreshCheckpoint61`. Rozpoczęcie misji odświeża stan kontrolny przed walką.
4. `SaveManager61.cs:48–85` (`ReadSlot61`): dekoduje i waliduje dane zapisu; zapisany tryb to `Orbit`, `Shop` albo `Intro`, nawet jeśli zapis wywołano podczas walki.
5. `SaveManager61.cs:86` (`LoadSlot61`): przywraca stan kampanii i w zależności od trybu odbudowuje `Orbit`, `Shop` lub sekwencję `Wave(); BeginLevelIntro()`. Nie odtwarza aktualnej klatki bitwy.
6. `SaveManager61.cs:94–104`: interfejs slotów wywołuje tę samą logikę zapisu/wczytania/usunięcia, niezależnie od renderera.

**Konsekwencje:** w O09 implementować pozostałe pola `Snapshot61`, rejestrowanie punktów kontrolnych i odtwarzanie ich trybów według źródeł bez oczekiwania na pełne O08. Dalsze, jeszcze nieobsługiwane przejścia należy oznaczać jako nieprzetestowane i sprawdzić później integracyjnie. Nie wymyślać stanów walki ani nagród. Bez zmian w wyglądzie gry.

Definicja i numeracja stałego harmonogramu O01–O12 pozostają niezmienione.

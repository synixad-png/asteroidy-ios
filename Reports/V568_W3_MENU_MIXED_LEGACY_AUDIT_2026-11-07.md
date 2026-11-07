# AUDYT: nowe W3 kontra stare menu — ASTEROIDY Windows v568 / iOS
**Data:** 07.11.2026

## Metoda / źródła
Analiza **rzeczywistego** archiwum `Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip` z Biblioteki ChatGPT oraz drzewa `synixad-png/asteroidy-ios`. To nie jest koncepcja interfejsu. Priorytet zachowania istniejącego oryginalnego modelu NewHome290, Vanguard431, wspólnych obrazów W3, gameplay CARBONIS, oryginalnych ustawień i audio.

| Oryginał Windows v568 | Wniosek |
|---|---|
| `Windows/src/RendererW3Home328.cs`, SHA-256 `a696603703583df5e4363106389833d6fd9aaa59fd6b73fa5e1aec3f71f4a966` | HOME z siedmioma oryginalnymi akcjami |
| `Windows/src/ProgramW3Native315.cs`, SHA-256 `27cc2c796ddd621a4a0f84b256851d03b45e5ccca4d643fc0504ba08261b4aa6` | Pełne ekrany W3, nawigacja i historia, osobne NOWA/KAMPANIA, legacy fallback wyłącznie awaryjny |
| `Windows/src/UiW3NativeLayout315.cs`, SHA-256 `f8abca55bcf9ad3191f84005f843d72863f584836c602cb2b5836c7355b76908` | `W3ReferenceTransitionSeconds327=1.25`, 36% cover / 64% uncover, easing źródłowy; 44 ekrany w definicjach W3 |
| `Windows/src/Menu139.cs`, SHA-256 `f7f992529e82b87632c1dd753f4a2eec812489984efd7ad6630bfe4bddadd743` | 17 kategorii USTAWIEŃ w pionowej szynie źródłowej, a nie 6 poziomych kart |
| `Shared/assets/ui_w3_native_layout.audit.json`, SHA-256 `59d96573253e80a67bcea6016ef74032ae767b165daa16a93ae56dae0410d764` | Rejestr 44 nazw ekranów W3 (nie wszystkie są już grywalnymi ekranami iOS) |

## Wykryte przyczyny mieszania starego i nowego menu
1. `W3MainMenu568.swift` pokazywał nowe HOME, ale podstrony otwierał jako stary czarny pełnoekranowy modal na wierzchu HOME, bez źródłowej nawigacji stron W3.
2. `App.swift` utrzymywał drugi niezależny `showCampaign` i osobny `CampaignAtlas556` jako stare `ultraThinMaterial` systemowe okno; wejście z diagnostyki prowadziło do innego interfejsu.
3. `CarbonisVisualSettingsPanel568.swift` miał sześć poziomych kart, zamiast źródłowych 17 kategorii menu W3.
4. Zwykłe HOME zawierało przycisk `SCENA TESTOWA` otwierający starszy HUD / sceny diagnostyczne, czego nie ma w normalnym W3.
5. `NOWA GRA` i `KAMPANIA` korzystały z identycznej podstrony, mimo że źródło rozdziela je na dwa ekrany.
6. Przełączenie ekranu korzystało z uproszczonego iOS fade, nie z oryginalnej zasłony 1,25 s.

## Poprawki wykonane w aktualnym kodzie main
- `W3MainMenu568.swift`: podstrony są renderowane jako osobny ekran natywnego W3 we wspólnym chrome/tle/logo (bez czarnej nakładki na poprzedni ekran). NOWA GRA ma osobny ekran konfiguracji; nie udajemy niezaimplementowanego oryginalnego kasowania profilu i co-op. Wróć/Nowa/Kontynuuj/Kampania korzystają z `navigateW3` i zasłony 0,45+0,80 s.
- `CarbonisVisualSettingsPanel568.swift`: pionowy panel oryginalnych 17 kategorii, z działającymi dotychczasowymi stronami DŹWIĘK, PLANETY, WYBUCHY 3D, STATEK, POSTPROCES, POCISKI; pozostałe **11** uczciwie oznaczone jako oczekujące na przeniesienie źródłowych mechanizmów. Zachowana lokalna i oryginalna persystencja wartości.
- `App.swift`: usunięta druga nakładka `showCampaign`, pozostawiona tylko jednolita ścieżka W3; siatka `CampaignAtlas556` zrezygnowała z systemowego `ultraThinMaterial` i zaokrąglonych iOS kart, teraz jest częścią strony W3, funkcjonalne zabezpieczenia odblokowań bez zmian.
- `SCENA TESTOWA`: dostępna wyłącznie po jawnej fladze diagnostycznej `ASTEROIDY_DEBUG_MENU=1`, niewidoczna w zwykłym menu.
- Zaktualizowano testy regresji kodu i rzeczywiste XCTest iPhone/iPad do nowego routing-u i 17 kategorii. Nie podmieniano oryginalnych assetów W3, NewHome290 ani Vanguard431.

## Ograniczenia, których nie maskujemy
- 44 ekrany źródłowego W3 **nie zostały w całości** przeniesione. Dotąd 7 akcji głównych, wybrane podstrony i 6 funkcjonalnych kategorii ustawień; **11 kategorii nie działa jeszcze** w portowym silniku. Nie należy nazywać portu kompletnym nowym W3.
- Osobna `NOWA GRA` jeszcze nie ma dokładnego oryginalnego startu profilu, wyboru 2 graczy/trudności; `KONTYNUUJ` nie odczytuje pełnych zapisów gry PC, a hangar GLB w dostarczonych źródłach jest pominięty (paczka BEZ_HANGARU). Nie podłączano żadnych zamienników.
- Istniejąca karta kampanii zachowuje realne modele i przejście do CARBONIS, ale nie jest 1:1 rendererem całego W3 Campaign v568; wymaga dalszej portacji.
- Brak testu dotykowego na fizycznym iPhonie/iPadzie. Testy symulatora są oddzielnym etapem i ich wynik podajemy wyłącznie po ukończeniu. Nie tworzono nowego IPA w tym etapie (poprzedni IPA jest sprzed korekty menu).
- Nie zmieniano fizyki, kolizji, AI, spawnowania misji, szkód, GPU eksplozji, CARBONIS, zasobów ani generatora muzyki.

## Kontynuacja zgodna z harmonogramem
Zakres: wyłącznie nowe W3, bez cofania starego. Następne funkcje w tej kolejności po zamknięciu testów obecnego etapu: (1) dokładny ekran W3 NOWA GRA w oparciu o źródłową logikę profili / trudności / coop, (2) ekran KAMPANIA z pełną strukturą W3, (3) KONTYNUUJ tylko po rzeczywistym podłączeniu ładowania zapisu, (4) kolejne funkcjonalne kategorie ustawień z istniejącymi wartościami źródłowymi. Pełny harmonogram 18 zadań i dotychczasowe procenty pozostają niezmienione, dopóki nie zweryfikowano większego zakresu.


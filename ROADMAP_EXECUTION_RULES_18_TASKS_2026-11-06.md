# ASTEROIDY iOS — zasady realizacji zatwierdzonego harmonogramu 18 zadań
Data: 2026-11-06. Uzupełnienie, nie zamiana `PORT_STATUS_18_TASKS.md`.

## Nienaruszalny zakres
Zachowujemy 18 oryginalnych zadań, ich nazwy, numery i postępy odniesienia.
Nie dodajemy nowego zadania „import modelu” jako osobnego etapu i nie
zaliczamy badań zasobów za ukończenie mechanik.

| Nr | Nazwa | Postęp odniesienia | Bramka ukończenia |
|---:|---|---:|---|
| 1 | Kompilacja i infrastruktura iOS | 88% | Powtarzalny build Xcode iPhone/iPad, spójność zasobów; IPA tylko na wyraźne polecenie |
| 2 | Silnik graficzny Metal | 89% | Wierny render źródłowych scen, kamery, geometrycznych efektów; test GPU |
| 3 | Materiały PBR, tekstury i oświetlenie | 25% | Materiały, światła, połysk, cienie względem PC v568, GPU |
| 4 | Statki, planety i zasoby 3D | 20% | Modele i proceduralne generatory 26 planet używane przez PC v568, bez zamienników |
| 5 | Animacje modeli GLB | 35% | Oryginalne animacje GLB/B82S i transformacje części, test wizualny |
| 6 | Fizyka lotu i poruszanie po planetach | 35% | C# v568 ↔ Swift, source regression oraz scena iOS |
| 7 | Kolizje, obrażenia i zniszczenia | 100% | ZAMKNIĘTE implementacyjnie; zawsze utrzymywać regresje |
| 8 | Asteroidy i fale walki | 100% | ZAMKNIĘTE implementacyjnie; zawsze utrzymywać regresje |
| 9 | Wszystkie bronie i efekty trafień | 10% | Wszystkie źródłowo używane bronie, efekty, zachowania, testy |
| 10 | Przeciwnicy i sztuczna inteligencja | 0% | Komplet źródłowych AI i zachowań |
| 11 | Bossowie i ich mechaniki | 0% | Wszystkie 6 typów bossów, oryginalne animacje, AI, obrażenia |
| 12 | Komplet misji planetarnych | 5% | Pełne cele, zdarzenia i przejścia |
| 13 | Kampania — 26 sektorów | 30% | 26 źródłowych sektorów z pełnym wykonaniem celów |
| 14 | Menu W3, HUD i ustawienia | 10% | Oryginalny natywny interfejs, brak WebView |
| 15 | Dźwięki i muzyka | 0% | Źródłowy mapping audio |
| 16 | Zapisywanie i wczytywanie gry | 20% | Stany kampanii i odtwarzanie 1:1 |
| 17 | Sterowanie dotykowe i kontrolery | 35% | iPhone/iPad, sterowanie i kontrolery oraz ustawienia |
| 18 | Optymalizacja i testy urządzeń | 10% | Fizyczne iPhone/iPad, FPS, regresje, pełne testy end-to-end |

**Zbiorczy postęp odniesienia: 27%; pozostało 73%.**
Procent zmieniamy dopiero po zweryfikowanej zmianie funkcjonalnej oraz
adekwatnych testach — bez sztucznego przeliczania 18 wartości na średnią.

## Kolejność operacyjna — grywalne i wizualnie weryfikowalne etapy

**Decyzja użytkownika 06.11.2026:** priorytetem nie jest numer najbliższego
zadania, ale **widoczna, spójna droga gracza: uruchomienie → menu →
wybór misji → wejście na planetę → lot i walka → wynik → powrót**.
Wcześniejsze sekwencyjne „najpierw całe 9, później 10 i 11, menu dopiero
na końcu” jest ZASTĄPIONE poniższym wykonawczym porządkiem. Oryginalne
18 zadań, numery, zakresy i procenty w tabeli wyżej pozostają bez zmian.
**Każdy kamień milowy kończy się widocznym wynikiem w tej samej
natywnej aplikacji**, nie samym importem modeli. W danym momencie
wdrażamy jeden pionowy przebieg end-to-end; wcześniej rozpoczęta część
tego przebiegu musi być sprawdzona przed kolejną.

| Kolejność | Kamień milowy / widoczny stan gry | Numery oryginalnych zadań | Bramka zaliczenia |
|---:|---|---|---|
| A | **Ekran startowy i oryginalne menu** W3, w pełni natywne Metal/Swift, na iPhone i iPad | 14 + zależności 1–3,17 | Uruchomienie → rzeczywiste menu, obsługa dotyku, nawigacja i powrót; autentyczny screenshot + test stanu na obu symulatorach |
| B | **Wybór misji**: ekran kampanii, 26 sektorów z oryginalnymi nazwami/zasadami dostępności (bez sztucznego odblokowania) | 13,14,16 + 1 | Menu → wybór → podgląd/wybór dozwolonej misji → Wstecz; zapis ustawień zgodny z bazą v568; test UI |
| C | **Wejście do pierwszej misji**: ekran ładowania, właściwa planeta/sektor i statek, kamera, oryginalne zasoby | 2–6,12–14 + 17 | Wybór sektora 01 → autentyczna scena Metal → interaktywny lot, pauza i powrót; NIE oznaczać demo jako kompletnej misji |
| D | **Pełna rozgrywka pierwszej misji**: wszystkie jej wymagane obiekty, fale, bronie, kolizje, cele, zakończenie | 6–10,12,14,17 (7–8 tylko regresje) | Scena 01 → gra → osiągnięcie autentycznego celu → wynik → menu; test end-to-end, bez fałszywego komunikatu ukończenia |
| E | **Widoczna rozbudowa świata**: wszystkie pozostałe typy planet i statków, animacje, światło, tekstury | 2–5,13 | Odwiedzenie kolejnych prawdziwych planet i porównanie ich źródłowej geometrii/efektów v568; widoczne różnice, testy GPU |
| F | **Przeciwnicy i 6 bossów**: autentyczne modele, osobne AI, animacje, ataki, zniszczenia | 5,7,9–12 | Grywalny pojedynek z przeciwnikiem/bossem i poprawne zakończenie; nie wystarczy test parsera B82S |
| G | **Kampania 26/26**: pełne cele misji, przejścia, blokady, wynik i postęp kampanii | 12,13,16 | Test przejścia całej kampanii; wszystkie 26 sektorów rzeczywiście uruchamiają się i mają poprawne stany |
| H | **Pełny interfejs i ustawienia**, sterowanie dotykowe i pady, ustawienia obrazu i dźwięku | 14,15,17 | Wszystkie ustawienia działają w misji i poza nią; testy iPhone/iPad i kontrolerów |
| I | **Oryginalne audio i trwałe zapisy** | 15,16 | Muzyka/efekty zgodne z oryginałem, zapis/odczyt po restarcie bez utraty postępu |
| J | **Wydajność, regresje i przygotowanie wydania** | 1–18, ze szczególnym 18 | Kompilacja, testy GPU, pamięci, FPS i end-to-end na urządzeniach; nie deklarować 100% bez ich wykonania |

**Najbliższy aktywny kamień milowy: A — prawdziwe menu.**
Na etapie A nie portować nowych bossów lub kolejnych statków, chyba że
są bezpośrednio wymagane przez ekran menu. Dopiero po zaliczeniu A
przejść do B, następnie C. Zadania 7 i 8 pozostają zamknięte
implementacyjnie i obowiązkowo objęte regresją przy każdym relewantnym
wydaniu. Otwarte zadanie 9 pozostaje otwarte, lecz jego funkcje
wdrażane są w **grywalnym przebiegu D**, gdy menu i wejście do misji już
działają. Nie zwiększać żadnego procentu bez realnych testów.

### Sposób raportowania na każdym etapie

Raport zawsze zawiera jedną stałą tabelę **18 zadań**, z postępem,
zmianą w punktach procentowych i osobnym paskiem dla każdej pozycji;
nad nią postęp zbiorczy 27% / pozostało 73% dopóki dowody nie pozwolą
go zmienić. Ponadto pokazujemy: aktualny etap A–J, wykonane
funkcje widoczne dla gracza, wyniki autentycznych screenshotów lub
testów, czego dokładnie brakuje do zaliczenia etapu, i następny
kamień milowy. Nie podmieniać screenshotów na koncepcje lub cudze gry.

### Rozliczenie dotychczas wykonanych prac spoza aktualnego punktu

- `PlayerShip367`, Vanguard431 i Boreas → techniczna baza zadań 2–4.
  Rzeczywisty GPU PASS na symulatorach iPhone+iPad nie oznacza końca 2–4.
- `alien_scout_173.b82.gz`, jego 88 części i 10×49
  źródłowych klatek → przygotowanie zasobu pod zadania 4–5 oraz 11;
  boss **nadal 0%**, bo nie ma jego renderowania animowanego i walki.
- Nie dokładać kolejnych importerów bossów tylko dla samego liczenia
  plików. Wykorzystać je dopiero, gdy harmonogram wymaga 4/5/11.
- Używać **wyłącznie** źródeł i assetów Windows/SteamOS **v568**
  znajdujących się w czterech SHA-verified ZIP-ach GitHub.
  Nie podstawiać GLB z biblioteki tylko dlatego, że nazwa pasuje.
- `BEZ_HANGARU` nie zawiera `hangar_h55.glb`: zachować ten brak
  w audycie zamiast wymyślać zamiennik.

### Każde zadanie kończyć na mierzalnej bramce

1. Potwierdzić konkretny kod C# i używane pliki w v568; zapisać
   dokładne odwołania i format. Nie zaczynać od ilustracji lub nazwy.
2. Wykonać **jedną spójną funkcję** we właściwym numerze harmonogramu.
3. Uruchomić kontrakt źródłowy i test jednostkowy, następnie CI na
   GitHubie (Swift, Xcode/Metal), test symulatora tylko tam, gdzie
   GPU/obraz to istotna bramka.
4. Naprawić znalezione regresje przed kolejną funkcją; utrzymywać
   PASS zakończonych 7/8.
5. Dopisać raport: co wykonano, co pozostało, następny krok, testy
   niedostępne (fizyczny iOS), postęp zadania i zmiana w pp.
6. Dopiero po spełnieniu bramki przechodzić do następnego punktu.
   Zablokowaną funkcję oznaczyć jawnie jako zablokowaną, bez
   fałszywego 100%.

Nie uruchamiać `build-ios.yml` ani nie tworzyć nowego IPA bez
wyraźnego polecenia. Zachować dotychczas działający kod iOS.

## Najbliższy rzeczywisty zakres: kamień milowy A — menu

Najpierw zweryfikować źródłowy interfejs W3 w aktualnym Windows v568
oraz istniejące widoki i routing `App.swift`. Nie tworzyć nowej
estetyki ani zastępników. Wdrożyć natywny ekran startowy,
menu główne i nawigację iPhone/iPad, przy zachowaniu istniejącego
intro, diagnostycznych widoków i gameplayu (jako osobnych
niedomyślnych ścieżek). Następnie dwa autentyczne screenshoty
symulatorów oraz testy działania przycisków. Dopiero **po teście menu**
rozpocząć etap B — rzeczywistą listę 26 misji i wybór sektora.

Dla kamieni milowych A i B przed kompilacją sprawdzić źródłowo,
czy menu i selektor misji mają rzeczywistą logikę (a nie tylko
grafikę). Nie tworzyć IPA bez osobnego polecenia użytkownika.

## 06.11.2026 — wykonanie kamienia A, pierwsza rzeczywista implementacja

**Stan: W TRAKCIE.** Bez zmiany 18 zadań i bez podnoszenia procentów
odniesienia (27% ukończone, 73% pozostało; nr 14 nadal 10%).

W commitach `9681d18`, `ce74f4a`, `0b70633`, `2c9334a` wykonano
`ASTEROIDYiOS/W3MainMenu568.swift`: natywny SwiftUI/Metal ekran
domyślny z siedmioma rzeczywistymi etykietami v568
(`NOWA GRA`, `KONTYNUUJ`, `KAMPANIA`, `HANGAR`,
`USTAWIENIA`, `AUTORZY`, `WYJŚCIE`), paletą i panelem
radarowym opartym na `RendererW3Home328.cs`, układem adaptacyjnym
iPhone/iPad i ekranami stanu funkcji. Zmieniono punkt wejścia
`App.swift`: zwykłe uruchomienie pokazuje menu, a istniejące
podglądy 3D są dostępne dopiero przez `SCENA TESTOWA`.
`MENU W3` wraca z testu do menu, kasując przytrzymane wejścia.
Tryby simulatorowego dowodu GPU Vanguard431/PlayerShip367
są zachowane jako jawne wyjątki. Oryginalne mechanizmy
kolizji/asteroid nie zostały zmienione.

**Zasada bez pozorowania ukończenia:** oryginalne
`Shared/assets/ui_w3_background.jpg` (806519 bajtów; SHA256
`a8aa28883084657f0c38900dbb011de09e2b0fd461704d370a68858be0178145`)
i `Shared/assets/ui_w3_logo.png` (50257 bajtów; SHA256
`cab4198b953640c787975c5a8436a0fdeaa82502b40e000077ff055cc0709e09`)
są w pełnym ZIP v568, ale **nie** zostały dołączone do wcześniejszego
czteroczęściowego archiwum modeli. Są nadal do przeniesienia do
repozytorium i bundla iOS. Centralna planetarna animacja/proceduralna
geometria z `RendererW3Home328.cs` NIE została jeszcze portowana.
Obecny radar jest jawnym płaskim elementem nawigacyjnym, nie
symulacją oryginalnej planety. Opcje zapisu, hangaru i misji
pokazują stany „brak / podgląd” zamiast fałszywie działać.
`KAMPANIA` i `NOWA GRA` otwierają wyłącznie istniejący,
tylko-do-odczytu atlas 26 sektorów z bazy v556;
przeniesienie realnego wyboru v568 jest kamieniem B.

**Zapisane testy:** `Tests/V568W3NativeMenuContract.py` sprawdza
7 źródłowych etykiet, sposób uruchamiania, bezpieczne przejście do
testu i powrót oraz brak WebView. Natywna kompilacja iOS
`42193391940`: job **Compile iOS source only — SUCCESS**;
pełna ścieżka testów nadal podlega regresjom, a błędne dosłowne
asercje źródłowych testów dopasowano do nowego stanu menu.
Do bieżącej walidacji są uruchomione:
[GitHub Actions W3 iPhone+iPad](https://github.com/synixad-png/asteroidy-ios/actions/runs/42193792251)
— rzeczywiste screenshoty simulatów, oddzielny marker wyświetlenia
widoku i detektor niepustych pikseli (bez IPA).
**Nie oznaczać obu za PASS, dopóki nie zakończą się wynikiem success.**
Test aktywacji i wstecz wszystkich 7 akcji dotykiem w rzeczywistym
symulatorze nadal nie został wykonany.

**Bramka zamknięcia A:** zweryfikowane oryginalne tło i logo
w aplikacji, źródłowa planeta/animacja w centrum, test
przejścia po wszystkich pozycjach, autentyczne screenshoty
iPhone+iPad, regresje 7/8, zgodność z W3 v568
(bez twierdzenia „identyczny pikselowo”, zanim istnieje dowód).
Dopiero po tej bramce etap B — w pełni funkcjonalny wybór misji.

**Nie tworzono IPA.**

### Uzupełnienie etapu A — oryginalne obrazy W3 i ponowienie Apple testu

Z pełnego archiwum PC **v568** przygotowano dokładnie dwa pliki
menu (bez zmian zawartości) w 857501-bajtowym ZIP
`ASTEROIDY_v568_W3_ORIGINAL_MENU_ASSETS.zip`. Ten ZIP **nie
znajduje się jeszcze w repozytorium GitHub**; obecny connector
repozytorium przyjmuje edycje tekstowe, a oryginalnych binarnych
JPEG/PNG nie wgrywano innym kanałem. Paczka jest przygotowana
do jednorazowego ręcznego wgrania do katalogu głównego.
`Tools/prepare_v568_w3_original_assets.py` po jej wgraniu
automatycznie sprawdza CRC i SHA-256 oraz stage'uje oba oryginały
do `ASTEROIDYiOS/Assets`; `SourceW3Images568` zachowuje
jedną współdzieloną parę obrazów i nie akceptuje zamienników.
Test `Tests/V568W3MenuSourceImagesTests.py` weryfikuje
odrzucanie obcych plików i jawnie oznacza brak pakietu.

Poprzedni przebieg autentycznych ekranów
[42193792251](https://github.com/synixad-png/asteroidy-ios/actions/runs/42193792251)
zakończył się niepowodzeniem z powodu
`xcrun simctl install` — **ENVIRONMENT TIMEOUT 85 s**.
Wcześniejsze testy Xcode/Metal i kontraktów menu przeszły.
Nie klasyfikować timeoutu instalacji jako błędu shaderów/SwiftUI.
Skrypt ma teraz twardy limit 300 s na instalację (bez wyłączania
globalnego timeoutu). Uruchomiony jest nowy
[workflow 42194736690](https://github.com/synixad-png/asteroidy-ios/actions/runs/42194736690)
dla obu symulatorów. Nie zaliczać screenshotów, jeżeli joby
nie zakończą się `success` i nie będzie zweryfikowanych PNG.

**Etap A nadal otwarty. Zadanie 14 nadal 10%, zmiana 0 pp.
27% całego projektu, 73% pozostało. IPA nie generowano.**

### Uzupełnienie po wgraniu grafik — 06.11.2026

Użytkownik **wgrał** do głównego katalogu `main` oryginalny
`ASTEROIDY_v568_W3_ORIGINAL_MENU_ASSETS.zip` (857501 bajtów,
blob GitHub `0eb49bd74b1ef0b2d7bfcc93c01e3c99b6b47954`).
Osobno zweryfikowane z archiwum: `W3Background568.jpg` 806519 B,
**2560 × 1440**, SHA256
`a8aa28883084657f0c38900dbb011de09e2b0fd461704d370a68858be0178145`;
`W3Logo568.png` 50257 B, **476 × 138**, SHA256
`cab4198b953640c787975c5a8436a0fdeaa82502b40e000077ff055cc0709e09`.

Zmieniono [.github/workflows/verify-v568-w3-native-menu-once.yml](.github/workflows/verify-v568-w3-native-menu-once.yml):
archiwum W3 jest teraz **wymagane** (`--required`); kompilacja
musi zawierać oba pliki o identycznych SHA256, zanim zostanie
uruchomiona aplikacja w symulatorze. Dowód `onAppear` menu musi
jawnie potwierdzać `hasOriginalW3BackgroundImage=true` i
`hasOriginalW3LogoImage=true`; inaczej screenshot nie zostaje
uznany za zweryfikowany. Oryginalna para jest współdzielona
w kodzie SwiftUI, a nie kopiowana dla każdego ekranu.

Testy kompilacji/regresji po wdrożeniu pierwszej wersji menu
([42194850474](https://github.com/synixad-png/asteroidy-ios/actions/runs/42194850474))
**PASS**. Nowy workflow rzeczywistych obrazów z obowiązkowymi
źródłowymi plikami W3
([42195681068](https://github.com/synixad-png/asteroidy-ios/actions/runs/42195681068))
uruchomiono; wynik należy odczytać po zakończeniu, bez zakładania
sukcesu z samej kompilacji.

**Etap A nadal NIEZAMKNIĘTY:** centrum menu wymaga wiernego
oryginalnego obiektu 3D oraz interaktywnych testów przejść.
Dotychczasowy ekran wykorzystuje rzeczywiste tło i logo, kiedy
są prawidłowo zainstalowane. Numer i zakres wszystkich 18 zadań
pozostają bez zmian; zadanie 14: **10%, +0 pp**, zbiorczo:
**27% zrobione / 73% pozostało**. Brak nowego IPA.

## 06.11.2026 — etap A: oryginalna planeta 3D NewHome290 w menu

**Zaimplementowano w kodzie (weryfikacja GPU trwa):** na podstawie
rzeczywistego `Windows/src/NewHome290.cs`,
`GpuNewHome290.cs`, `GpuW3HomeReal333.cs` i
`RendererW3Home328.cs` dodano:
`Tools/convert_v568_w3_home_planet290.py`,
`Tools/prepare_v568_w3_home_planet290.py`,
`ASTEROIDYiOS/W3HomePlanetMetal568.swift` oraz
`ASTEROIDYiOS/W3HomePlanet290.metal`.

- Wykorzystano **oryginalne dane H290**, a nie kulę zastępczą:
  172208 trójkątów / **516624 źródłowych wierzchołków**,
  dwie oddzielne grupy materiałów, oryginalny strumień float32
  `XYZ normalXYZ RGBA UV`.
- Siatka `home290.mesh.gz` w zweryfikowanych czterech ZIP-ach:
  SHA256 `025a3ad626de24e666bb0c697aa1a8e855401965869ded96f7eee109f0ece278`;
  rozpakowana siatka 24 797 952 bajtów:
  SHA256 `e93a0bbafc9bb50a25726a828ada81f36675bf88d802c5a8f985b89b6dc96c1b`.
  Potwierdzona źródłowa tablica wysokości **512×256**.
- Base JPEG 2048×1024 oraz mapa `home293.glow.png` 2048×1024
  zachowują oryginalne bajty w plikach `.dat`, bez ingerencji
  optymalizatora PNG Xcode. Emisja lawy jest obliczana w tym samym
  przebiegu fragment shader, według źródłowego wzoru
  `GpuToon60.cs` dla `homeGlow293`.
- Widok wykorzystuje ortogonalne parametry podglądu
  `GpuW3HomeReal333.cs`: `halfHeight335=1.72`, przesunięcie
  `z=-6`, podstawowy obrót X `-18°`, osie X/Y.
  Użytkownik może obracać planetę gestem dotykowym; stały
  ruch obrotu wynosi 0,19 rad/s jak w Windows.
- Trwały renderer świata planety oraz źródłowe mechaniki 7/8
  pozostają bez zmian. Oddzielna tekstura GPU dla podglądu
  menu jest tworzona tylko po wejściu do W3; nie jest zamiennikiem
  planet w 26 misjach.
- `Tests/V568W3HomePlanet290Tests.py` sprawdza źródłowy
  parser, materiał 0 i 1, oryginalne pliki, SHA256 i pełny
  proces budowania siatki z prawdziwych indeksów GLB.
- `Tools/run_w3_native_menu_simulator_capture.py` wymaga
  zarówno autentycznego zrzutu iPhone/iPad i rzeczywistych obrazów
  W3, jak również zakończonej komendy Metal podglądu NewHome290,
  potwierdzającej **516624 wierzchołków i 172208 trójkątów**.
  Samo skompilowanie Swift nie wystarcza do zaliczenia GPU.
  Najnowszy test: [GitHub Actions
  42197653964](https://github.com/synixad-png/asteroidy-ios/actions/runs/42197653964).
- Obecne oświetlenie podglądu jest **częściowym portem**:
  nie stwierdzono jeszcze pełnej zgodności światła `FighterLight`
  i oryginalnego postprocessingu z PC. Nie deklarować
  identycznego wyglądu 1:1 bez porównania rzeczywistych obrazów.

**Etap A w trakcie**, dopóki dwa natywne testy GPU, obrazy,
nawigacja i shader nie będą potwierdzone. **Etap B bez zmian
i jeszcze nierozpoczęty.** Główny harmonogram 18 zadań i
dotychczasowe procenty pozostają nienaruszone:
**27% wykonane / 73% pozostało, zadanie 14 nadal 10% (+0 pp)**.
**IPA nie generowano.**

### Weryfikacja ostatniej poprawki — H290 / Metal

Po źródłowo wykrytej niezgodności konstruktora macierzy w
`W3HomePlanet290.metal` zastosowano jawną transformację
normalnych przez oryginalne trzy osie modelu. Potwierdzona
**natywna kompilacja Swift/Metal iOS PASS**:
[GitHub Actions 42198113777](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113777)
(job `Compile iOS source only`, bez IPA).
Cały przebieg testów kolizji/asteroid należy oceniać osobno
po jego zakończeniu.

Bieżący test rzeczywistego menu i planety na symulatorach:
[GitHub Actions 42198113753](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753).
Wymaga **oryginalnych obrazów W3**, **oryginalnego H290 z
dwóch grup**, waliduje sumy SHA256 pięciu zasobów wewnątrz
`.app` i dowód `gpuCommandBufferCompleted=true`
po faktycznym zgłoszeniu obydwu grup renderowania. Uruchomienie
przebiegu nie jest zaliczeniem: do zamknięcia A potrzeba
autentycznych PNG i testu nawigacji wszystkich 7 przycisków.

**Status A: W TRAKCIE. Zadanie 14: 10% / +0 pp;
całość: 27%, pozostało 73%. B nierozpoczęte. Bez IPA.**

### 06.11.2026 — etap A: rzeczywiste testy dotyku menu W3

Do kodu dodano odrębny target Xcode UI testing
`ASTEROIDYW3UITests` w `project.yml` i
`W3MenuUITests/W3MenuNavigationUITests.swift`.
W przeciwieństwie do kontroli źródłowej oraz samego
`onAppear`, XCTest **realnie uruchamia aplikację i naciska**
kolejno siedem przycisków z oryginalnego menu W3, sprawdza
otwarcie odpowiadającego panelu, przycisk `WSTECZ`,
powrót do menu, a dla `NOWA GRA` i `KAMPANIA` jawne
oznaczenie atlasu jako podglądu. Osobny test naciska
`SCENA TESTOWA`, następnie `MENU W3`, weryfikując powrót
bez zmieniania dotychczasowych mechanik walki.

Wprowadzono workflow
[W3 real touch iPhone+iPad XCTest
42200004528](https://github.com/synixad-png/asteroidy-ios/actions/runs/42200004528),
który przygotowuje 5 SHA-verified źródłowych zasobów,
generuje projekt Xcode i uruchamia prawdziwy XCTest w
symulatorze, bez IPA. **Testy zostały uruchomione, ale ich
wynik trzeba sprawdzić osobno.** Dopóki oba urządzenia nie
potwierdzą działania, etap A nie jest zamknięty.

Wcześniejszy rzeczywisty test GPU źródłowego
`NewHome290`, oryginalnych W3 JPEG/PNG i
autentycznych screenshotów:
[42198113753](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753).
Job symulatora iPad **SUCCESS** (GPU, oryginalne 5 assetów,
prawdziwy obraz). Job iPhone podczas dodawania testów
XCTest kończył zapisywanie raportów; jego ostateczny wynik
należy odczytać z Actions. Nie ma jeszcze pełnego
porównania pikselowego z Windows v568, a shader
oświetlenia jest tylko częściowo zgodny z PC.

Postęp 18 zadań pozostaje bez zmian do końcowych
testów etapu: **nr 14 = 10% (+0 pp), projekt 27%,
pozostało 73%.** Kamień B nadal nierozpoczęty.
Nie wygenerowano IPA.

### 06.11.2026 — autentyczna grafika menu W3: iPhone i iPad PASS

**Potwierdzony wynik GitHub Actions:
[42198113753](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753) —
oba joby symulatorów (IPHONE i IPAD) zakończone `success`.**
Oba uruchomiły rzeczywistą aplikację, wykorzystały oryginalne
SHA-pinned W3 background/logo i NewHome290 H290 z dwoma materiałami,
sprawdziły ukończone polecenia GPU dla **172208 trójkątów**
i zapisały autentyczne screenshoty oraz osobne dowody JSON.
Zrzuty z GitHub:
[iPhone artifact #13493952002](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753/artifacts/13493952002),
[iPad artifact #13493651804](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753/artifacts/13493651804).
Techniczne ograniczenia i dowody:
[Reports/V568_W3_HOME_IPHONE_IPAD_GPU_PASS_2026-11-06.md](Reports/V568_W3_HOME_IPHONE_IPAD_GPU_PASS_2026-11-06.md).

Nadal należy ukończyć **realne przejście dotykiem** przez wszystkie
pozycje, oświetlenie względem v568 i zamknięcie
kamienia A. Autentyczne dwa XCTest na Apple simulator są
w [workflow 42200004528](https://github.com/synixad-png/asteroidy-ios/actions/runs/42200004528),
wynik trzeba odczytać po ich zakończeniu.

**Nie uruchomiono B, IPA nie generowano.
Zadanie 14: 10% (+0 pp), projekt: 27% / pozostało 73%.**

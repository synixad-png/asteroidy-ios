# ASTEROIDY iOS — natywny port Swift/Metal (projekt w trakcie rozwoju)

## Aktualna kompilacja IPA — 5 listopada 2026

Na wyraźne polecenie użytkownika uruchomiono **budowanie niepodpisanego IPA dla fizycznego iPhone'a/iPada** z commita `18e18797046dd37807650313990913dce38ab522`:

- [GitHub Actions — build iOS IPA, run 42051262545](https://github.com/synixad-png/asteroidy-ios/actions/runs/42051262545).
- Workflow: `.github/workflows/build-ios.yml` (uruchomiony przez zmianę tego pliku na gałęzi `main`).
- W pierwszej fazie Swift/Linux sprawdza regresje oryginalnego v556. Na macOS kompilowane są źródła przez XcodeGen i Xcode dla **iphoneos arm64**. Dopiero po udanej kompilacji tworzony jest `ASTEROIDY_iOS_UNSIGNED.ipa`, sprawdzany CRC/Info.plist/Mach-O oraz zasoby.
- Artefakt GitHub ma nazwę **`ASTEROIDY-iOS-device-unsigned-ipa`** i jest przechowywany **14 dni**; zawiera niepodpisany IPA, środowisko budowania, sumę SHA256 oraz wynik walidacji.
- **Nie deklarować, że IPA już istnieje, dopóki przebieg nie jest zakończony z wynikiem SUCCESS, a artefakt nie został opublikowany.** Kompilacja to nie test uruchomienia na fizycznym iPhonie.

### Jak pobrać i zainstalować po sukcesie workflow

1. Otwórz [przebieg kompilacji](https://github.com/synixad-png/asteroidy-ios/actions/runs/42051262545) i poczekaj, aż pokaże **Success**.
2. W dolnej części strony, w sekcji **Artifacts**, wybierz `ASTEROIDY-iOS-device-unsigned-ipa`. GitHub pobierze ZIP zawierający `ASTEROIDY_iOS_UNSIGNED.ipa` oraz raporty.
3. Rozpakuj ZIP i wybierz plik IPA w Sideloadly na Windows. **To IPA jest niepodpisane** — instalacja na iPhonie wymaga poprawnego podpisania przy użyciu odpowiedniej metody; sam ZIP nie instaluje gry.
4. Jeśli kompilacja zakończy się błędem, czytaj błąd na poziomie konkretnego zadania, nie traktuj poprzednich udanych buildów jako potwierdzenia tej rewizji.

### Osobne kontrole infrastruktury i renderera

- **Zasoby oryginalnego v556:** `python3 Tools/verify_ios_inputs.py` sprawdza cztery referencyjne SHA-256, formaty AS3D/ASMO, powiązanie animacji z geometrią, `project.yml` i wejścia `Ship.metal`. [GitHub Actions 42053587593 — PASS](https://github.com/synixad-png/asteroidy-ios/actions/runs/42053587593). Nie używa zewnętrznych bibliotek.
- **Kamera Metal:** zmiana `Sphere67.swift`, `MetalRenderer.swift` i `Ship.metal` odtwarza źródłowy `SphereCombat67.cs` i `GpuSphere67.cs`, z orbitującym widokiem nad planetą i prawidłowym wektorem kamery w oświetleniu BRDF. [GitHub Actions 42052748443 — PASS](https://github.com/synixad-png/asteroidy-ios/actions/runs/42052748443). Jest to test matematyczny oraz składni Swift, nie test Metal GPU; dokumentacja w `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`.
- **Wersje:** IPA z uruchomionego run `42051262545` ma SHA `18e187970`. Zmiany kamery i walidatora powstały **później**, dlatego nie wchodzą do tamtej kompilacji. Nie wolno przedstawiać tego IPA jako wydania ze zmianami po tym SHA.

### Niebo planety — autentyczna tekstura z oryginalnego v556

Na podstawie rzeczywistych `Windows/src/GpuAmbient37.cs:5`, `GpuIntro41.cs:23,451–452` oraz `Gpu2DRenderer.cs:68,70,74` przeniesiono proceduralną `StarTexture` 64×64 BGRA PArgb i gwiezdne `IntroHalo`. Widok planetarny zachowuje 1500 kierunków, w tym 206 dodatkowych jasnych halo, w jednym buforze i jednym rysowaniu Metal. Promienie 10/21 px i podstawowe `size*2` oraz `ONE/ONE_MINUS_SRC_ALPHA` wynikają z oryginalnego kodu; nie są wymyślonymi efektami. Testy Swift/Linux i statyczna kontrola pipeline'u: [PASS, run 42065903420](https://github.com/synixad-png/asteroidy-ios/actions/runs/42065903420). **Natywna kompilacja Xcode/Apple Metal i test obrazu są nadal niepotwierdzone.** Mgławice, promienie i czarna dziura są już zaimplementowane w kolejnych commitach, lecz natywna kompilacja Apple GPU pozostaje niepotwierdzona. Szczegóły w [audycie zadania 2](AUDYT_ZADANIE_2_v556_METAL_CAMERA.md).

### Źródłowe promienie słoneczne w Metal — zadanie 2

Obok prawdziwej `StarTexture` 64×64 i gwiazd `IntroHalo` port odtwarza teraz również `GpuIntro41.cs:454`: trzy oryginalne teksturowane poświaty słońca (promienie 130/55/15 px) oraz pięć wachlarzy `SoftRay` z `GpuCosmos39.cs:8–10`. Kod `SphereSolarOverlay556` tworzy łącznie **738 statycznych wierzchołków** i wykonuje jedno rysowanie GPU z oryginalnym premultiplikowanym blendingiem; projekcja `SkyProject55` aktualizuje tylko 16-bajtowy uniform względem sferycznej kamery. [Test Swift/Linux i kontraktów kodu — PASS, GitHub 42068464591](https://github.com/synixad-png/asteroidy-ios/actions/runs/42068464591). Apple Xcode/Metal i fizyczny iPhone **nie zostały jeszcze potwierdzone**; mgławice i czarna dziura są już zaimplementowane, a trzy planety tła z `DrawDeepSpace55` zostały dodane w kolejnym etapie; nadal wymagają testu na urządzeniu. Szczegółowy audyt: [AUDYT_ZADANIE_2_v556_METAL_CAMERA.md](AUDYT_ZADANIE_2_v556_METAL_CAMERA.md).

### Mgławice GpuCosmos39 i GpuIntro41 — oryginalny kod v556

Podgląd planety korzysta teraz z autentycznego generatora `CloudHash` i pięciu oktaw `CloudNoise` w teksturach `NebulaTexture` 256×256. Źródłowe **24 dalekie i 12 bliskich warstw** są renderowane przy użyciu dwóch palet w jednej dwuwarstwowej teksturze, bez tworzenia nowych buforów w każdej klatce; `SkyProject55` wyliczany jest bez translacji kamery. Test oryginalnych wzorów, pikseli BGRA, projekcji wszystkich 36 warstw i statycznego połączenia Metal: **[PASS, GitHub Actions 42071274522](https://github.com/synixad-png/asteroidy-ios/actions/runs/42071274522)**. Apple GPU i fizyczny iPhone nie zostały jeszcze zweryfikowane. Trzy planety głębokiego kosmosu zostały dodane w późniejszym etapie; wszystkie elementy nieba nadal wymagają natywnej weryfikacji GPU. Patrz [AUDYT_ZADANIE_2_v556_METAL_CAMERA.md](AUDYT_ZADANIE_2_v556_METAL_CAMERA.md).

### Czarna dziura z oryginalnego v556 — trzy obrazy i dziesięć warstw

Z `GpuIntro41.cs:62–127` przeniesiono algorytm **3 oddzielnych tekstur 640×640 BGRA/PArgb**: tylnego dysku akrecyjnego, czarnego rdzenia i przedniego dysku zachodzącego przed środek. Przy domyślnie włączonym glow scena korzysta z **3 poświat StarTexture, 4 animowanych promieni i 3 dysków**, rysowanych we właściwej kolejności. Wszystkie obrazy generowane są tylko raz, a shader Metal dostaje w kolejnych klatkach wyłącznie położenie i zmienne animacji. Naprawiono też kolejność mgławic: 24 odległe → obiekty tła → 12 bliskich. **[Swift/Linux + statyczna kontrola Metal — PASS, GitHub 42074436010](https://github.com/synixad-png/asteroidy-ios/actions/runs/42074436010)**. Nadal brak testu uruchomienia na iPhone i wyniku kompilacji Apple Metal dla tego commita. Trzy planety głębokiego kosmosu przeniesiono w późniejszym commicie; działanie na iPhonie nadal wymaga potwierdzenia. [Audyt źródłowy](AUDYT_ZADANIE_2_v556_METAL_CAMERA.md).

### Trzy planety tła z oryginalnego BuildDeepPlanet55 (obecny stan)

Port ma teraz także wszystkie trzy planety 320×220 z `GpuIntro41.cs:27–63`: gazowego olbrzyma z pierścieniami, niebieski świat z chmurami i czapami polarnymi oraz czerwony świat z pasmami i śladami atmosferycznymi. `DeepSkyPlanets55.swift` odtwarza rzeczywistą kolorystykę powierzchni `PlanetShade55`, źródłowe kierunki/animacje `AnimatedSkyDirection55`, poświaty i projekcje. `MetalRenderer` dzieli jeden zasób GPU na trzy warstwy tekstur i wykorzystuje istniejące shadery czarnej dziury, bez ponownej generacji obrazów w każdej klatce. Oryginalny porządek rysowania: **24 dalekie mgławice → trzy planety → czarna dziura → 12 bliższych chmur → gwiazdy i promienie**. [Testy matematyczne Swift/Linux i kontrakt shaderów — PASS, GitHub 42077736535](https://github.com/synixad-png/asteroidy-ios/actions/runs/42077736535).

**Ograniczenia:** pikselowa antyaliasingowa rasteryzacja łuków i pierścieni Windows GDI+ jest przybliżeniem; nie jest gwarantowany wygląd 1:1. Natywna kompilacja aktualnych shaderów Apple Metal i uruchomienie na fizycznym iPhonie **nie zostały jeszcze potwierdzone**. Procent zadania 2 wynosi **64%**, nie 100%. [Pełny audyt](AUDYT_ZADANIE_2_v556_METAL_CAMERA.md) i [harmonogram](PORT_STATUS_18_TASKS.md).

### Stan portowania

Zatwierdzona, niezmienna lista 18 zadań i procenty: [PORT_STATUS_18_TASKS.md](PORT_STATUS_18_TASKS.md). Dotychczas moduły 7 i 8 zamknięto implementacyjnie, ale nadal brakuje pełnej gry i testów dotykowych/Metal na urządzeniu. Do zamknięcia całej aplikacji konieczna jest sekwencyjna realizacja pozostałych etapów, zaczynając od **zadania 1: kompilacja i infrastruktura iOS**.

Pełen wynik poprzedniej udanej kompilacji IPA jest udokumentowany dla commita `596767b`, [run 42027976783](https://github.com/synixad-png/asteroidy-ios/actions/runs/42027976783). **Ten stary IPA nie zawiera obecnych zmian.**

## Historia bazowego portu v18

Instrukcja historycznego przekazania: [START_DRUGI_CZAT.md](START_DRUGI_CZAT.md). Raport ówczesnego stanu: [ASTEROIDY_iOS_v18_RAPORT.md](ASTEROIDY_iOS_v18_RAPORT.md). Poniższy opis dotyczy historycznych etapów v14–v18 i nie jest aktualną informacją o stanie kompilacji.

Poniżej zachowano historyczny opis rozwoju v14–v18.

Baza: ASTEROIDY v556, niezależny port iOS. Nie jest to ukończony port ani podpisany IPA.

Wprowadzono `BoreasMorphRenderer556.swift`, `BoreasMorphBinding556.json` i procedurę reprodukowalnego eksportu `Tools/export_boreas_morph_binding.py`. Renderer Metal w trybie planetarnym aktualizuje geometrię według oryginalnych klatek GLB, interpoluje sześć morph targetów i odtwarza normalne. Przy aktualizacji używa nowego bufora GPU, pozostawiając indeksy bez zmian.

Testy: `python Tests/test_morph_export.py <zip_v556> ASTEROIDYiOS/Assets/Boreas556.asmo` i `python Tests/test_binding_export.py` (ten drugi używa źródeł v556 z archiwum lokalnego). Statyczne sprawdzenie składni Swift i uruchomienie modułu animacji w Swift Linux przeszły, ale kompilacja Xcode oraz wykonanie GPU Metal **nie były dostępne**.

Raport i dokładne ograniczenia: `RAPORT_v14.txt`. Nie utworzono paczki wydaniowej ani IPA.

### v15 — optymalizacja normalnych Boreas (wersja robocza)
W `BoreasMorphRenderer556.swift` normalne przeliczane są tylko dla
27 035 deformowanych wierzchołków i 54 066 ich trójkątów.
Pozostałe 4 320 wierzchołków / 7 488 trójkątów są niezmienne.
Test `BoreasMorphOptimization556Tests.swift` porównuje normalne z pełnym
przeliczeniem w sześciu fazach cyklu. Lokalny test Swift/Linux: PASS.
Kompilacja Xcode i wizualny test GPU Metal: NIE WYKONANO.

### v16 — potrójne bufory animacji (wersja robocza)
- Trzy bufory MTLBuffer są alokowane jeden raz przy ładowaniu Boreas.
- MorphBufferSlots.swift pilnuje, aby zapisy CPU omijały bufory mające niezakończone odwołania GPU.
- Zwolnienie referencji odbywa się w MTLCommandBuffer.addCompletedHandler.
- Gdy nie ma wolnego bufora, pomijany jest upload tej klatki, bez czekania na GPU.
- Test własności buforów i kompilacja modułu pod Swift/Linux: PASS; parse całych źródeł: PASS.
- Brak kompilacji Xcode, brak testu Metal GPU, brak pomiaru FPS iOS.
- Nie dodawano animacji transformacji innych obiektów GLB; pozostaje zadaniem.

### v17 — redukcja kopiowania animacji (wersja robocza)
- Reużywalny scratch wierzchołków, zakresowy upload tylko dynamicznej siatki (27 035 z 31 355).
- Lokalne porównanie Swift/Linux 10 próbek animacji: PASS; brak kompilacji Xcode/Metal i pomiarów FPS.
- Szczegóły: `RAPORT_v17.txt`.

### v18 — rozdzielone pomiary CPU/GPU (roboczo)
Dodano `RenderTelemetry.swift` i `Tests/RenderTelemetryTests.swift`.
Pomiar obejmuje CPU morph, CPU upload, opcjonalnie czas GPU command buffer.
Dla `ASTEROIDY_IOS_PROFILE=1` log diagnostyczny pojawia się co ok. 5 s w trybie planetarnym.
Testy Swift/Linux i zgodności z rzeczywistym GLB v556 przeszły; kompilacji Xcode ani testu GPU nie przeprowadzono.
Pełny wykaz wyników i ograniczeń: `RAPORT_v18.txt`.

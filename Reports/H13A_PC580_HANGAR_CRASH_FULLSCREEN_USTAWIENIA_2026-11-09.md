# ASTEROIDY iOS — H13-A: stabilizacja wczytywania, pełnoekranowy hangar, prawdziwa zakładka ustawień
Data: 2026-11-09 | Zakres: wyłącznie H13-A + korekta nawigacji H05, bez podnoszenia postępu H13.

## Źródła PC v580 (oryginał użytkownika)
Przed modyfikacjami sprawdzono dostępne w Bibliotece **oryginalne archiwum**
`Asteroidy_v580_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip` (1822 pozycje)
oraz oryginalny `hangar_h55.glb` 126419336 B, SHA256
`00e6ba4ab2cce025b1290265052c1e252e149209f6fcbbc50b5d569af4592461`.
Konkretne źródła:
- `Windows/src/Hub90.cs` linie 38–65:
  `EnterMenuHangar397` zmienia tryb gry na `Mode.Hub90`, nie wyświetla panelu podrzędnego W3. `ExitHub90` z wizyty menu wraca do `Mode.Menu`.
- `Windows/src/Menu139.cs` linie 13, 24: dziesiąta zakładka
  `OptionTabs139[9]="HANGAR"`, `OptionGroups139[9]=[140,134,135,136,137,138,139,102,48,49,50,51,52,53]`.
  Wartości są rzeczywistymi opcjami oryginalnego renderera, nie nowymi zastępczymi suwakami.
- `Windows/src/H55Renderer.cs` i `GpuHub90.cs`: oryginalny shader i fallback GPU/OpenGL, a nie automatyczny SceneKit IBL.
- `Windows/src/HubWalk375.cs`: oryginalny spacer, kolizje i punkty startowe — niezmieniane.

## Potwierdzony błąd portu
`W3MainMenu568.swift` umieszczał `H55ScenePage580` w `panel(for:.hangar)`,
więc fragment ekranu zajmowały W3 header i footer. Wejście do ustawień
wymagało wyjścia z hangaru. Tymczasowe suwaki w `H55LightingPanel580`
były nakładką na rozgrywkę, poza oryginalnym `USTAWIENIA → HANGAR`.
W poprzedniej IPA przy każdym otwarciu `H55SceneLighting580` automatycznie
tworzył 8×48 pikseli `UIImage` cube-strip i ustawiało
`scene.lightingEnvironment.contents`, wymagające dodatkowej pracy GPU
podczas pierwszego renderowania; inny potencjalny koszt to
`SCNMaterial.shaderModifiers` dla emisji. **Bez rzeczywistego crash
logu nie udowodniono, który mechanizm spowodował zamknięcie gry.**

## Wdrożenie H13-A
1. `W3MainMenu568.swift`: `page == .hangar` tworzy pełnoekranowy
   `H55ScenePage580` poza W3 header/footer. Powrót działa przez
   istniejącą `navigateW3(nil)`, zgodnie z `Hub90.ExitHub90`.
2. `H55ScenePage580.swift`: pełnoekranowe **USTAWIENIA** dostępne w hangarze,
   z zakładką 9 `HANGAR`, bez usuwania modelu `H55SceneModel580`
   z hierarchii, bez ponownego importu GLB. Zegar i ruch postaci zostają
   zawieszone na czas przeglądania ustawień; po powrocie zegar jest
   wznawiany. Nie ma sliderów na widoku gry.
3. `CarbonisVisualSettingsPanel568.swift`: jedna kanoniczna lokalizacja
   ustawień dla H55 (oryginalny Windows indeks 9). Tymczasowe
   *iOS-specyficzne* korekty fill i red są wyraźnie odróżnione od
   oryginalnych wartości PC. Bezpieczny tryb materiałów domyślnie ON,
   opcjonalny test `KHR_materials_emissive_strength` po świadomym wyłączeniu
   ochrony. Z poziomu USTAWIENIA → HANGAR można udostępnić zapis ostatniego
   etapu ładowania, **również po crashu i ponownym uruchomieniu aplikacji**.
4. `H55SceneLighting580.swift`: **usunięto dynamiczny IBL/cubemap**,
   brak `lightingEnvironment.contents`; pozostaje tylko jeden
   tymczasowy, bezcieniowy neutralny fill SceneKit. Docelowe oświetlenie
   oryginalnego PC, sześć źródłowych lamp i składnik GLSL `albedo*0.24`
   to następny H13-B, NIE deklarować ich jako wykonanych.
5. `H55LightingProfile580.swift`: współdzielony odczyt zapisanych
   wartości wyłącznie z ustawień W3; bezpieczny shader domyślnie ON.
6. `H55LoadDiagnostics580.swift`: mały trwały zapis atomowy
   etapów `01_START...` do `13_PIERWSZY_TICK...`, także dla błędów GLTF,
   dostępny niezależnie od otwarcia hangaru i bez modyfikacji GLB.
   Ostatni etap jest wskazówką diagnostyczną, a nie automatycznym dowodem
   przyczyny awarii.
7. Usunięto nieużywaną nakładkę `H55LightingPanel580.swift`.
   Zachowano oryginalne kolizje, 61 animacji, H70 drzwi, H09/NPC, H12,
   oraz H71 autonomous OFF.

## Weryfikacja
- Regresja Swift `Tests/H55LoadDiagnostics580Tests.swift`: zapis,
  trwały odczyt, zastąpienie poprzedniego etapu.
- Bramka W3/H55: hangar występuje tylko jako pełnoekranowy
  `Mode.Hub90`, W3 `HANGAR` index 9, brak suwaków w widoku sceny,
  brak generowania cube-strip oraz poprawna kompilacja źródeł Swift.
- Bramka H01-H12: fizyka, H70, H09 NPC i H12 bez regresji.
- Kompilacja iPhone/iPad ARM64 i pakowanie IPA: wynik musi być potwierdzony
  odrębnie; nie uznawać sukcesu testowego dopóki nie ma PASS i CRC.
- **Nie wykonano testu na fizycznym iPhonie/iPadzie**, więc nie można
  jeszcze stwierdzić, że awaria jest naprawiona.

## Status harmonogramu
H13 nadal **35%**, wzrost **0 p.p.** do urządzeniowego potwierdzenia
braku crasha. H14 **0%** (nie uruchamiać). H12 **85%** bez autonomicznych
dronów H71. Całość H01–H16 **70,9%**, do końca **29,1%**.
Kolejność: H13-A stabilny import → H13-B światła PC v580 →
H13-C materiały GLSL/SceneKit → H13-D odbiór urządzenia, bez
przechodzenia do H14.

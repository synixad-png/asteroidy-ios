# H13 — audyt materiałów hangaru GLB i sprawdzenie bez regresji (09.11.2026)

## Zakres i źródła
- Obowiązująca baza: PC v580; gałąź iOS feature/ios-h55-v580-native-entry.
- H12 bez autonomicznych dronów H71 pozostaje w 85%: oryginalne animacje H51/H39, turbiny, ramiona, suwnica, H46, H70 i mechanic H09 bez zmian.
- H13 obejmuje światła, materiały i efekty szkła/przezroczystości oraz audio H55. Po uprzednim zgłoszeniu z iPada czerwone H46 zostało już ograniczone do 8 aktywnych lamp. Bez nowego porównania obrazu NIE ma podstaw do modyfikacji intensywności.
- Źródło standardu materiałów: Khronos glTF 2.0. GLTFKit2 0.5.15 konwertuje na SceneKit tryby OPAQUE/MASK/BLEND, alphaCutoff i doubleSided oraz podstawowe PBR. Jego kod zawiera niezaimplementowane/ograniczone przypadki, np. pełny model transmisji szkła i siłę emisji. NIE zakładamy, że występują one w konkretnym H55 bez odczytu jego rzeczywistych materiałów.

## Wykonane
1. Dodano narzędzie \`Tools/audit_h55_materials580.py\`, odczytujące wyłącznie nagłówek oraz chunk JSON z oryginalnego pliku GLB 2.0; bez kopiowania 126 MB binarnej geometrii, bez przepisywania materiałów, bez modyfikacji pliku.
2. Liczone są rzeczywiste materiały, siatki, obrazy, typy OPAQUE/MASK/BLEND, doubleSided, tekstury baseColor i wszystkie nazwy rozszerzeń materiałowych. Raport wskazuje materiały alpha BLEND, KHR_materials_transmission/volume, oraz niepoprawne metadane.
3. Test \`Tests/H55H13MaterialAudit580Tests.py\` używa generowanego małego, poprawnego GLB, weryfikuje liczniki, przeźroczystość, dwustronność, wykrywanie szkła, walidację pól i odmowę uciętego GLB. Dowodzi również, że audyt nie zmienia bajtów źródła.
4. Oddzielny CI \`.github/workflows/h13-material-metadata.yml\`: [H13 metadata 42635666447](https://github.com/synixad-png/asteroidy-ios/actions/runs/42635666447) **PASS**. [No Slop 42635680353](https://github.com/synixad-png/asteroidy-ios/actions/runs/42635680353) **PASS**.
5. Źródła działającej gry, importu GLTFKit2, H55ScenePage580, shaderów, materiałów, świateł, audio oraz poprzedniej IPA **nie zmienione**. To audyt przygotowujący świadomą implementację H13, a NIE wykonany port efektu szkła.

## Rzeczywiste blokady i kolejne prace H13
- Oryginalny \`hangar_h55.glb\` 126 419 336 B (SHA256 \`00e6ba4ab2cce025b1290265052c1e252e149209f6fcbbc50b5d569af4592461\`) nie był dostępny jako plik wejściowy w bieżącym kontenerze, Library ani Drive. Nie ma więc uczciwych wyników dla 358 autentycznych materiałów, 301 obrazów i rzeczywistej przezroczystości.
- Przed korektą renderera: przeprowadzić audyt powyższym narzędziem NA TYM konkretnym GLB i porównać wynik ze źródłowym PC v580 oraz rzeczywistym obrazem iPhone/iPad. Nie dopisywać implementacji transmisji/alpha bez ustalenia, że określone materiały jej wymagają.
- W części audio: zweryfikować źródłowe sygnały i ich wyzwalacze z PC v580. Nie podstawiać dźwięków sektora CARBONIS jako rzekomych dźwięków hangaru. Osobny odbiór pauzy/odblokowania i audio na sprzęcie.
- H14 optymalizacja i H15 pełny E2E nie rozpoczęte.
- H13 **25% (zmiana 0 p.p.)**: przybyło zweryfikowane narzędzie i test, ale nie potwierdzona realizacja kryteriów materiałów/audio/obrazu. Nie ma nowej kompilacji IPA, bo nie zmieniano aplikacji.

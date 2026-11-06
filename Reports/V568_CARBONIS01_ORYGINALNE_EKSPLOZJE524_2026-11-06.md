# ASTEROIDY iOS v568 — rzeczywiste wybuchy w CARBONIS 01

**Wersja źródłowa:** Windows/SteamOS v568 z archiwum `Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip` (pełne oryginalne źródła). **Data:** 6 listopada 2026. **Zakres:** tylko pierwsza grywalna misja CARBONIS 01. Zachowano istniejące sterowanie, fizykę, geometrię i 26-elementowy atlas.

## Udowodnione reguły oryginału

| Zdarzenie | Właściwe źródło Windows v568 | Rzeczywiste efekty |
|---|---|---|
| Nieśmiertelne trafienie asteroidy | `Game.cs:257-258` | 3 krótkie cyjanowe smugi i błysk 0,13 s, bez eksplozji |
| Zniszczenie skały dużej (size3) | `Game.cs:226-229` | 27 cyjanowych smug, pierścień życia 0,9 s, objętościowa eksplozja rodzaju ASTEROIDA o skali 23 i dwa fizyczne mniejsze fragmenty |
| Zniszczenie skały średniej (size2) | `Game.cs:226-230` | 18 smug, pierścień, eksplozja skala 15 i dwa fizyczne mniejsze fragmenty |
| Zniszczenie skały małej (size1) | `Game.cs:226-229` | 18 smug, pierścień, eksplozja skala 9 i 18 oddzielnych krótkotrwałych fizycznych odłamków (`SpawnTerminalShards187`) |
| Trafienie myśliwca bez zniszczenia | `BossTunnelGame.cs:96`, `CombatPieces125.cs:13-25` | 6 iskier kontaktowych, błysk 0,13 s i 3 pomarańczowe smugi |
| Zniszczenie myśliwca typu 0 | `BossTunnelGame.cs:96`, `CombatPieces125.cs:26-35` | 6 iskier, 11 obracających się metalowych tetraedrów 3D, dodatkowe 22 pomarańczowe smugi, błyski 0,72/0,30 s i eksplozja rodzaju PALIWO, skala 14 |
| Ogień/dym i przestrzenne odpryski | `Explosion524.cs:43-123,165-220` | V8.2: 3D ray marching, zanikający ogień, sadza/dym, szum 64×64×64, 13 dużych kłębów, 22 próbki głębi, maksymalnie 3 równoległe wolumetryczne wybuchy w jakości GAMEPLAY oraz 35 lecących fragmentów 3D |

W oryginalnym programie `GpuSphere67.cs:433,442-443` wyświetla odrębnie objętościowe wybuchy, sześcioczęściowe linie ruchomych cząsteczek i rozchodzące się pierścienie. `GpuCombatPieces125.cs:7-29` rysuje metalowe odłamki w 4 trójkątnych ścianach na rzeczywistej powierzchni sfery. To nie są statyczne zdjęcia, sprite'y ani zastępcze modele. 

**SHA256 zweryfikowanych oryginałów:** `Game.cs` `cb0b398ccf47408174b392ea3e5827d53c188e08c293fe8632ac3898c1e25aae`; `Explosion524.cs` `9f088f3e056670e325c704bbd3040ab1c0b1ddce0ce7d0be0594967c1c33eda0`; `BossTunnelGame.cs` `604f2b63331ea18091dae52822be9dce53e01cd3dadf7b4b152ee70378b5038e`; `CombatPieces125.cs` `a0113ce8cb2d77adf86978aa189f7461a107177ec1fcae442d8abb2b32d8b3cd`; `GpuCombatPieces125.cs` `d333daf6583d8eaff45f9cb01228653880acb322a9ae1c34133dd4b3de611977`.

## Rzeczywiście wprowadzone moduły

- `ASTEROIDYiOS/CarbonisDestruction524.swift`: stan, limity, symulacja trwania/pędu, źródłowe wywołania dla trafień i śmierci asteroid oraz myśliwców, niezależnie od kolizji i nagród.
- `ASTEROIDYiOS/CarbonisExplosionNoise524.swift`: generator **bajtowo zgodnych z oryginałem 262144 bajtów** Xorshift32; SHA256 `c871908c11577720bcb4e9af0dd3549d09cb03096c14cb4f7ebfce97f65051a2`.
- `ASTEROIDYiOS/CarbonisExplosion524Meshes.swift`: geodezyjne smugi, pierścienie, fizycznie poruszane tetraedry metalowe i 35 wyrzucanych trójkątnych szczątków na realnej powierzchni planety.
- `ASTEROIDYiOS/Sector01Explosion524.metal`: przepisane z GLSL V8.2 pole gazowe/termiczne i 3D extinction dla oryginalnych typów PALIWO/ASTEROIDA/REAKTOR.
- `ASTEROIDYiOS/CarbonisExplosion524Renderer.swift`: jeden współdzielony szum GPU i jedna potokowa konfiguracja Metal, frontowe przestrzenne ograniczniki i niezmienione buforowanie głębi, budżet maksymalnie trzech równoczesnych efektów.
- `ASTEROIDYiOS/CarbonisCombat568.swift` i `ASTEROIDYiOS/Sector01CarbonisPreview568.swift`: połączone bezpośrednio ze zdarzeniami prawdziwych trafień i zniszczeń, bez fałszywego odtwarzania na podstawie obrazów czy timerów. Poprzedni system `splitRock`, obrażeń, punktacji, żetonów, FinishLevel oraz pierwszego statku zachowano.

## Testy, których wynik jest zweryfikowany

**[GitHub Actions 42276790554](https://github.com/synixad-png/asteroidy-ios/actions/runs/42276790554): `verify-combat-no-ipa` — SUCCESS.**

- **PASS 45** źródłowych kontroli: wielkość i typ rozbłysku, liczba/kolor cząsteczek, 6 iskier/11 metalowych odłamków u myśliwca, ograniczenia pojemności, czas zanikania, brak błędów NaN i siatki 3D.
- Test szumu GPU weryfikuje 16 pierwszych bajtów i sumę 262144 bajtów, przeliczoną na podstawie oryginalnego C#.
- Przeszły też wcześniejsze testy fizyki, pocisków, AI, kontraktów UI, sygnału zwycięstwa i przejścia całej pierwszej misji (18 testów integracyjnych, 335 kroków).
- **NIE** przeprowadzono jeszcze prawdziwego renderowania w Metal na iPhonie/iPadzie, pomiaru GPU ani wizualnego porównania z Windows. Przepuszczenie testów Swift na Linux nie jest dowodem na kompilację nowego shadera MSL.

**[Nowa próba IPA z tymi modułami](https://github.com/synixad-png/asteroidy-ios/actions/workflows/build-ios.yml)** uruchomiona po dodaniu testów do pre-IPA. Weryfikację artefaktu i konkretnego przebiegu wykonać na podstawie GitHub Actions, bez ogłaszania pliku przed powstaniem.

## Następne działania

1. Zweryfikować zakończenie macOS Xcode i nowy niepodpisany IPA, usunąć konkretnie wykazane przez kompilator MSL/Swift błędy.
2. W samym CARBONIS 01 sprawdzić wybuch w trzech rozmiarach asteroid, zwykłego przeciwnika i wielokrotnego trafienia w iPhone/iPad, z pomiarami GPU.
3. Dopiero po potwierdzeniu przez źródła i wizualną kontrolę uznać odtworzenie pełnych efektów za zweryfikowane. Nie zmieniać reszty kampanii ani nie traktować źródłowych testów jako gwarancji 100%.

**Łączny harmonogram portu pozostaje na 38% / 62%.** Nowe efekty uzupełniają brak pierwszej misji, nie stanowią dowodu ukończenia całej gry.

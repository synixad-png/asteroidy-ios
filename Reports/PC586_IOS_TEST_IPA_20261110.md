# ASTEROIDY iOS — PC v586 test IPA / 2026-11-10

## Dokumentowane rzeczywiste wydanie testowe
- Zatwierdzona baza PC: `Asteroidy_v586_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`; SHA-256 `8fad7f8444321ff91b77bd0dc7bdf50491cad65870df794151ffc586e27c06ff`.
- Repo: `synixad-png/asteroidy-ios`, branch `feature/ios-h55-v580-native-entry`.
- Dokładny commit **skompilowanego kodu**: `95088adf2ec59e3f33edaaf489bee8245e1f9d7b`. Dalsze commity w gałęzi dotyczą skryptów budowania/weryfikacji, nie zmian tego binarnego kodu.
- GitHub Actions: [42778031797](https://github.com/synixad-png/asteroidy-ios/actions/runs/42778031797), **SUCCESS**, regresja H55/H71 PASS, Xcode 16.4 Release iPhoneOS ARM64 PASS.
- IPA: `ASTEROIDY_iOS_PC586_4GLB_RECE_BRON_TEST_UNSIGNED.ipa`, **44 045 678 B**, SHA-256 `bdfffef66312feb7f542e3af17677b3dab0f9317e517261c8d8516d6340183bd`.
- IPA jest niepodpisana, wymaga podpisania do instalacji przez użytkownika.

## Weryfikacja finalnej IPA
- ZIP / CRC PASS, dokładnie jedna aplikacja `com.synixad.asteroidyios`.
- Właściwy plik wykonywalny: **thin ARM64 Mach-O**. Oryginalny EXE z GitHub Actions identyczny bajtowo z EXE w wynikowym IPA.
- W skompilowanym `default.metallib` znajdują się `sector01PickupVertex586` oraz `sector01PickupFragment586`, **PASS**.
- Wbudowano trzy modele H55: `gloves_parted.glb` (TRIPO), `gloves_combined.glb` (MONOLIT), `EXP01_SOURCE_v601.glb` (broń) z dokładnymi SHA i rozmiarami oryginałów.
- Wbudowano 12 oryginalnych zasobów PC v586: `shield/boost/energy/bomb` w postaci oryginalnego GLB, zweryfikowanego strumienia trójkątów Metal (`.mesh`) i identycznego osadzonego JPEG (`.jpg`). Wszystkie SHA-256 i liczby wierzchołków PASS.
- Łącznie 15 nowych plików; pozostałe zasoby aplikacji niezmienione po osadzaniu.

## Faktycznie zintegrowane funkcje PC v586
- Jeden katalog oryginalnych modeli z SHA-256; jeden zestaw zbuforowanych siatek i tekstur na typ przedmiotu w rendererze Metal.
- Oddzielny `SourceCombatSupply586`: deterministyczny seed i jeden roll; prawdopodobieństwa zgodne z PC; limit 96; czas 26 s; wspólna ścieżka fizyki i pickupów.
- Energia zasila istniejący `ionAmmo` (+40 do 300), bomba istniejący `bombs` (+1 do 3). Nie powielano mechaniki zasobów.
- W ustawieniach W3 → ROZGRYWKA: jasność 0–400%, domyślnie 180%; osobne rozmiary Shield 60%, Boost, Energy, Bomb i żetonów po 78%, ustawienia trwałe.
- Zachowana istniejąca animacja, kolizje, audio, HUD, hangar H55 i drony H71. **Nie dodano** zmian HUD z PC v587–v589.

## Rzeczywiste ograniczenia / niezaliczone testy
- **Nie przeprowadzono interaktywnego testu na fizycznym iPhonie ani iPadzie**. Nie można potwierdzić wyglądu modeli ani utrzymania 60 FPS w tych warunkach na podstawie samego binarium i testów źródłowych.
- Model GLB jest technicznie podłączony do renderera, ale pierwotne źródłowe umiejętności Shield/Tarcza145 i Boost71 nie zostały jeszcze w całości portowane do CARBONIS 01; nie twierdzić, że te dwa typy obecnie faktycznie wypadają.
- System 60 akcji, router wejścia, menu 65 pozycji i pełna migracja ustawień pozostają do wdrożenia zgodnie z harmonogramem.
- Nie podniesiono numeru wersji gry ani nie ogłoszono ukończenia całego portu.
- **Cztery oryginalne modele PC v586 nie są jeszcze w binarnych blobach repozytorium GitHub.** Są w zatwierdzonej paczce Biblioteki i finalnej IPA. Odtworzenie wymaga zatwierdzonego ZIP-a PC i skryptów `Tools/prepare_pc586_runtime_resources.py`, `Tools/pack_pc586_complete_test_ipa.py`; nie zakładać, że sam `git clone` zawiera ich bajty.

## Odstępstwo od źródła iOS / potwierdzenie testów
Poprzedni test Release Xcode 16.4 wykrył konflikt literalnych `Double` i `Float` w kolorze żetonów. Commit `95088ad...` poprawił deklarację, po czym **pełny Release ARM64 przeszedł**. Zaliczone testy źródeł i regresje H55/H71 są odrębne od niewykonanych testów na urządzeniach.

## Następny krok
Doprowadzić do potwierdzenia rzeczywistego wyświetlania i zbierania Energia/Bomba na urządzeniu, FPS i interakcji. Następnie kompletować pierwotne rodzaje Shield/Boost i pozostały harmonogram PC v586 (sterowanie 60 akcji, menu 65 pozycji, migracja, pełne testy). Przyszły raport musi nadal odróżniać **test source/compile** od **test physical iPhone/iPad**.

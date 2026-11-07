# ASTEROIDY iOS v568 — REDUKCJA EFEKTÓW dla FPS (07.11.2026)

## Cel i zakres
Użytkownik potwierdził brak poprawy realnego FPS po wcześniejszych optymalizacjach indeksowania GPU. Zamiast sugerować zmierzony wzrost wydajności, wdrożono nowe **rzeczywiste cięcia wizualne** w działającej ścieżce `Sector01CarbonisPreview568.swift` (CARBONIS C279), zachowując niezmienione źródłowe parametry rozgrywki, kolizji i ekwipunku.

## Cięcia w domyślnym trybie iOS
| Parametr renderowania | Pełne oryginalne efekty | Domyślne oszczędne efekty iOS |
|---|---:|---:|
| Jednocześnie rysowane wolumetryczne wybuchy 3D | 3 | 1 |
| Próbki głębokości raymarch/wybuch | 22 | 10 |
| Obliczane kłęby gazu | 13 | 7 |
| Maksymalny czas rysowania wybuchu | 4,2 s | 1,9 s |
| Warstwy światła pocisku na planecie | 4 | 1 (warstwa źródłowa nr 2) |
| Segmenty tej warstwy światła | 22 | 12 |
| Zewnętrzna aureola pocisku | tak | nie |
| Cząstki efektów rysowane w klatce | do 512 | do 96 |
| Metalowe odłamki rysowane w klatce | do 160 | do 48 |
| Odłamki wolumetryczne na wybuch przy ustawieniach domyślnych | 35 | 12 |

Liczba i zachowanie wystrzelonych pocisków w symulacji nie są ograniczone. Nadal widoczne są ich rdzenie i dwie wewnętrzne warstwy oraz smugowe linie. Rzeczywiste zdarzenia zniszczenia i ich koszt fizyczny/obrażenia pozostają bez zmian; ograniczono wyłącznie rysowanie.

**Szacunkowa redukcja pracy samej kosztownej pętli kłęby×próbki przy trzech jednoczesnych wybuchach:** przed `3 × 22 × 13 = 858`, teraz `1 × 10 × 7 = 70`, czyli 91,84% mniej potencjalnych iteracji tej części shaderów. Jest to porównanie górnych limitów **nie pomiar GPU ani rzeczywistych FPS**. Wykonywanie fragment shaderów obejmuje też inne koszty.

## Rzeczywiste pliki zmian
- `ASTEROIDYiOS/CarbonisIOSFXBudget568.swift` — osobny trwały profil oszczędny iOS. Domyślnie włączony nawet po aktualizacji starej instalacji; pełny tryb `.original` zachowuje wszystkie wartości.
- `CarbonisVisualSettingsPanel568.swift` — działający przełącznik `USTAWIENIA → GRAFIKA`, osobna jawna etykieta odróżniająca nową opcję iOS od oryginalnych opcji Windows.
- `CarbonisProjectileFX69.swift` — w ekonomicznym trybie jedna warstwa gruntowego światła/12 segmentów, przy pełnej jakości cztery źródłowe warstwy bez regresji.
- `CarbonisExplosion524Renderer.swift` — wydajne przycięcie liczby widocznych wolumenów, ich czasu, próbek i gazowych kłębów przy zachowaniu oryginalnego 3D shadera i pełnej jakości po wyłączeniu trybu.
- `CarbonisExplosion524Meshes.swift` — cząstki, fragmenty i odłamki cięte na poziomie renderowanej geometrii, nigdy poziomu symulacji.
- `Sector01CarbonisPreview568.swift` — ścieżki prawdziwych render passów Metal używają zapisanego budżetu od utworzenia renderera nowej misji. Przy wyłączeniu trybu wszystkie oryginalne parametry wracają.

## Testy przeprowadzone
- `Tests/CarbonisIOSFXBudget568Tests.swift`: rzeczywisty limit wybuchów, kłębów, próbek, poświat i liczby wizualnych elementów; przywracanie pełnych wartości; zapis i odczyt UserDefaults, PASS.
- `Tests/CarbonisIOSFXBudgetSourceContract568.py`: prawdziwe połączenie funkcji z rendererem Metal i zachowanie pliku rozgrywki CarbonisCombat568, PASS.
- Rozszerzone `CarbonisProjectileFX69Tests.swift` i `CarbonisDestruction524Tests.swift`: zmniejszone rzeczywiste siatki, zachowanie pierwotnych danych symulacyjnych, PASS.
- Pełna regresja Linux, kod źródłowy gry oraz natywna kompilacja Xcode/Metal iPhoneOS ARM64, **GitHub Actions 42371950545 — SUCCESS 4/4**.
- Realne urządzenia: **NIE TESTOWANO**. Nie ma jeszcze wiarygodnego pomiaru, czy spadki z 60 do 35 FPS zostały usunięte.

## Wydanie
- Commit kodu: `62a508593c7d3b4a6f2599baea1e53c75dc83327`.
- Run: https://github.com/synixad-png/asteroidy-ios/actions/runs/42371950545
- Artifact: https://github.com/synixad-png/asteroidy-ios/actions/runs/42371950545/artifacts/13574511452
- `ASTEROIDY_iOS_UNSIGNED.ipa`: **28 415 845 bajtów**.
- SHA-256: `3c7975f9224144105bbc66be45fea85855ab85d2af1d511b6a7fabbde4b19711`, zgodny z `reports/SHA256SUMS.txt` w pakiecie wydania.
- CRC ZIP i IPA: PASS. Mach-O: ARM64, bundle `com.synixad.asteroidyios`, `UIDeviceFamily [1,2]`, iOS 17.0+.
- IPA niepodpisany: wymaga podpisania przed instalacją.

## Dalsze działania
Na tym samym fizycznym iPhonie/iPadzie rozegrać porównywalne intensywne starcie przy włączonym oryginalnym liczniku FPS (`USTAWIENIA → GRAFIKA → POMIAR FPS`). Zarejestrować minimalny/stabilny FPS i przetestować obie wartości przełącznika trybu wydajności, z nowym wejściem w misję między zmianami. Jeśli po mocnych cięciach nadal wynosi około 35 FPS, należy profilować wąskie gardła CPU renderera i osobnego scenicznego pipeline'u, aby nie zgadywać kolejnych ograniczeń.

Harmonogram stały: 18 zadań, **38% / 62%**, zadanie 14 **26% (0 pp)**.

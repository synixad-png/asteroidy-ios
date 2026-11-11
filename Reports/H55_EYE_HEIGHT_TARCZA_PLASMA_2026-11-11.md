# ASTEROIDY iOS — H55 wysokość oczu i powłoka plazmowa Tarcza145
Data: 2026-11-11

## Baza
- Rozwijana gałąź iOS: `feature/ios-h55-v580-native-entry`.
- Referencja użytkownika: PC v602; istniejące H55 moduły bazują na `HubWalk375.cs` (H55 iOS v580), a aktywna tarcza na `Tarcza145.cs`.
- Oryginalne H55 `H55Walk580.eyes = 1.80 m`, fizyczny korpus 2 m, promień 0.34 m, nieskorygowany fizyczny krok i wysokość skoku.

## 1. Kalibracja H55
- `H55EyeHeight580.swift`: nowy **wyłącznie wizualny** profil 1.55–2.15 m, fabrycznie 1.80 m. Jedno własne zapisane ustawienie UserDefaults z walidacją, resetem i testem wolnej przestrzeni kamery przed ustawieniem wysokości. Suwak nie rusza wysokości fizycznych stóp.
- `H55ScenePage580.swift`: w renderowaniu używa istniejącego `movement.cameraFeet` i nadal źródłowych animacji bob/sway; wybiera zweryfikowaną pozycję kamery z `physical.cameraClear406`. Przy braku bezpiecznego miejsca wraca do bazowej wartości.
- `CarbonisVisualSettingsPanel568.swift`: zakładka HANGAR zawiera suwak i przycisk resetu; ustawienia wchodzą w życie w aktualnym H55 po powrocie z pauzy. Stan H55/kolizje/NPC/ręce/bron pozostają niezmienione.

## 2. Widoczna tarcza w misjach
- Oryginalna, już działająca `SourceTarcza145`: 60/100 energii początkowej, zużycie 12/s, koszt trafienia 35, flash 0.37s. Żadnych zmian w tej strukturze, sposobie przechwytywania obrażeń ani w pasywnych kupowanych osłonach.
- `SourceShieldShell145.swift`: przy inicjalizacji mierzy granice **prawdziwego źródłowego modelu Vanguard431** z jego SHA-zweryfikowanego bufora, tworzy jeden stan pipeline. W każdej klatce z aktywną `session.game.tarcza145.active` rysuje jedną geometrię powłoki z macierzą **tego samego statku**, bez dodatkowego świata/kolizji.
- `SourceShieldShell145.metal`: natywna 48×24-siatka z niejednorodnymi smugami, przepływem plazmy, Fresnelem oraz impulsem przy trafieniu. Przezroczystość blend source-alpha i wyłączony zapis głębi. Brak dodatkowych render targetów, tekstur, dynamicznych tablic i uploadów per-frame.
- `Sector01CarbonisPreview568.swift`: pipeline i rozmiar powłoki powstają raz; shader jest uruchamiany tylko przy prawdziwie przytrzymanej aktywnej Tarcza145; brak zmian w HUD, ruchu statku, strzelaniu i animacji planetarium.

## Weryfikacja
- `Tests/H55EyeHeightAndTarczaPlasmaContract.py`: sprawdza powiązanie ustawień, zabezpieczenie nad kamerą, oryginalną symulację tarczy i realne uruchomienie powłoki w tym samym rendererze.
- Workflow HUD: test źródeł i kontrola składni/typów Swift.
- Workflow wydania: testy źródeł, Xcode ARM64, kontrola oryginalnych zasobów, CRC i publikacja niepodpisanego IPA.
- Natywny test interaktywny H55/aktywnej tarczy na fizycznym iPhonie/iPadzie **nie został jeszcze wykonany**; pełna kompilacja w chwili sporządzenia raportu trwa.

## Granice implementacji
- Podniesienie kamery jest ograniczone dostępnością wolnej przestrzeni w aktualnym oryginalnym hangarze GLB. Nie może zastąpić naprawy błędnego poziomu podłogi.
- Powłoka to nowy efekt wizualny iOS, nie twierdzenie o identyczności pikselowej z Windows. Bazowe koszty i stan Tarcza145 pozostają źródłowe.

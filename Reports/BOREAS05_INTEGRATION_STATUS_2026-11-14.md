# ASTEROIDY iOS — BOREAS 05 / weryfikowalny stan integracji

Gałąź: `feature/ios-boreas-planet05`. Zakaz: nie zmieniać `main`, nie scalać bez odrębnej zgody, nie modyfikować działającej sceny CARBONIS 01 ani jej edytora HUD.

## Wdrożone w źródłach gałęzi

- Rzeczywisty wybór sektora 05 w odblokowanej kampanii, niezależnie od zachowanego wizualnego testu W3.
- Jedna fala `MissionWave568.generate(level: 5)`, wszystkie pierwotne asteroidy, myśliwce, roboty i limity posiłków zachowane w stanie startowym; wymagany cel `.defend`.
- `CarbonisCombat568` wykorzystuje numer faktycznego sektora; pierwsza misja nadal wykorzystuje identyczne formuły poziomu 01.
- `CarbonisSession568` jest jedynym źródłem stanu walki, obrażeń, ruchu, punktów, pocisków i HUD-u sceny 05.
- `MetalRenderer` korzysta z oryginalnego zweryfikowanego BOREAS wraz z animacją 5 s i oryginalnymi 96 kanałami węzłowymi; rysuje rzeczywiste pozycje myśliwców i asteroid z tej samej symulacji, a nie z dodatkowego losowego sandboxu.
- Oryginalne siatki `CarbonisShooterMesh71` typów 0/1 i 80 wariantów `CarbonisRockGeometry568`, bez octahedron placeholder w rozgrywce sektora 05.
- Zachowane SHA-weryfikowane modele wybranego KESTRELA, VANGUARDA i BASTIONA; brak modelu wybranego statku powoduje jawny błąd, a nie podszycie się innym.
- Wspólne sterowanie dotykowe, pauza z PC586 remap, plazmowy HUD, tarcza, dopalacz, bomba, zabezpieczenie powrotu i postępu kampanii.
- Zmiany w `Sector01MissionSummary568` i HUD są współdzielone; ścieżka poziomu 01 pozostaje logicznie bez zmian.

## NIEukończone i zabronione do reklamowania jako pełna misja

1. **RobotSnake70:** oryginalny generator umieszcza przynajmniej jednego wężowego przeciwnika w sektorze 05. Brak jeszcze aktywnego przeniesienia source AI, obrażeń, kolizji i renderowania całego łańcucha. Stan robotów jest zachowany, więc obecna rozgrywka **nie może poprawnie zaliczyć misji**. Nie usuwać robotów ani nie tworzyć pozornego zwycięstwa.
2. Dalsze modele/FX i 3D przedmiotów oraz pełne wizualne odwzorowanie HUD nie zostały jeszcze potwierdzone na iPadzie.
3. Pełna, zgodna z PC misja 05 wymaga przetestowanego zakończenia obrony, przeciwników i nagród.
4. Nie wykonano po tych zmianach rzeczywistej kompilacji Xcode/Metal iOS ani fizycznego testu iPad/iPhone. **Poprzedni zielony workflow na SHA `eef37fe6` nie dowodzi działania obecnego HEAD.**
5. Nie potwierdzono rzeczywistej wydajności GPU/FPS, jakości animacji ani możliwości instalacji IPA po nowych commitach.
6. Oryginalne źródła PC v609 ZIP są widoczne w Bibliotece ChatGPT, lecz nie uzyskano w tym środowisku autoryzowanego dostępu do bajtów tego archiwum w celu odczytania dokładnej logiki RobotSnake70. Nie zastępować jej wymyśloną implementacją.

## Kontrola regresji i kolejny warunek odbioru

- `Tests/BoreasTestPlanet05Contract.py` kontroluje poprawne bramki sektora 05, źródła GLB/ASNT, brak fałszywej nagrody z W3 i ścieżki wejścia/wyjścia.
- `Tests/MissionWave568Tests.swift` sprawdza oryginalne liczności i typ celu dla sektora 05 bez zmiany asercji dla CARBONISA.
- Statyczny audyt obecności 15 kluczowych niezmienników wykonany w środowisku integracji GitHub: 15/15 pozytywnych. To nie jest uruchomienie testów Swift/Python, kompilacja Xcode ani test gry na urządzeniu.
- `main`, `Sector01Scene568.swift`, zatwierdzony edytor HUD, H55 i pozostałe planety nie zostały zmodyfikowane.

Przed wydaniem jako pełna misja: oryginalna logika robotów, test źródłowy i mechaniczny, kompilacja Swift/Metal dla iPhone/iPad, kontrola IPA i test interaktywny iPad. Scalenie wyłącznie za nową, oddzielną zgodą użytkownika.

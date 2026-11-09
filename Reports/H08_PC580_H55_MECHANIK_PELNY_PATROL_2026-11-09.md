# ASTEROIDY iOS — H08 / oryginalny patrol mechanika H55 (PC v580)
Data: 2026-11-09. Baza: wyłącznie PC Windows v580 i oryginalny hangar_h55.glb. PR #28, gałąź feature/ios-h55-v580-native-entry.

## 1. Źródło prawdy
Archiwum użytkownika Asteroidy_v580_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip, sprawdzony oryginalny Windows/src/H55Renderer.cs:
- NpcRouteX525/Z525: 28 punktów (start/koniec 9.9248,12.155; warsztat indeks 11 = 45.817,8.150).
- PrepareNpc525 / v531: walidacja całej trasy co 0.08 m, na oryginalnym H55FullCollision379 (trójkąty + bryły), bez omijania zmienionego GLB.
- NpcGround526: podpora [foot−0.10, foot+0.12], odchyłka od foot ≤0.12 oraz od 0.10 ≤0.16; wymagana fizyczna kolizja BodyClear.
- NpcGround530 / NpcSafeWalk530: dwustronne punkty podporowe ±0.045 i ±0.07 m; różnica wysokości <0.045, potwierdzona podpora obu stron i BodyClear środka. Brak sztucznej podłogi.
- NPC v528/530: szybkość max 1.18 m/s, przyspieszenie 1.75, hamowanie 2.80, zatrzymanie w warsztacie na dokładnie 5.0 s, skręt 2.35 rad/s i powrót yaw=0 z limitem 2 rad/s.
- NPC v532/535/537: A* wyłącznie dla blokady przez gracza, nigdy przez zamkniętą śluzę lub stałą przeszkodę; natywne zakręty w tym samym kroku, bez fikcyjnego pośredniego idle. NPC v544: pełna współpraca z dwiema autonomicznymi śluzami H70, przerwanie patrolu po nieprzerwanej blokadzie drzwi przez >2.5 s.
- Bind-pose źródłowego GLB, stopy _foot_l/_ball_l i _foot_r/_ball_r: niezależnie pomierzony kierunek anatomiczny −2.32326389 rad. Realne położenie węzła GLB: [9.9248,0.1095,12.155].

## 2. Integracja
- Nowy ASTEROIDYiOS/H55NpcSurface580.swift: jedno źródło bezpiecznego przejścia po posadzce, sprawdzane w tle przed importem SceneKit. Odrzuca scenę z przerwaną trasą, bez zgadywania, przenoszenia NPC lub zastępczej kolizji.
- ASTEROIDYiOS/H55Mechanic580.swift: wczytanie source GLB root/foot, zastosowanie zmierzonej wysokości podparcia po każdym ruchu, licznik faktycznego przemieszczenia, powrót do oryginalnego yaw po zakończeniu trasy, liczniki blokowania przez gracza i komunikaty A*. Zachowana wsteczna zgodność testów starszych metod step.
- ASTEROIDYiOS/H55ScenePage580.swift: wywołanie preflight równolegle z oryginalnym importem H02–H04; sprawdzenie zgodności root TRS z oryginalnym GLB, przekazywanie fizycznej podpory do rzeczywistego ruchu NPC i ustawianie SceneKit root [x,y,z] z rzeczywistej wysokości. Źródłowe H07 airlock oraz H06 gracz są nienaruszone.
- Testy w Tests/H55H08SourceTests.swift oraz Tests/H55H08PatrolRealGLBTests.swift; stały H01–H16 harmonogram i PR #28 pozostają bez zmian.

## 3. Przeprowadzone testy
Oryginalny GLB: 126 419 336 B; SHA256=00e6ba4ab2cce025b1290265052c1e252e149209f6fcbbc50b5d569af4592461.
Z tego źródła pobrano 803 538 trójkątów i 233 kolizyjne bryły, przeprowadzono **1136 próbek** zatwierdzonej trasy:
- bez gracza na trasie: wizyta w warsztacie ok. 41.01667 s, pięciosekundowy postój, powrót dokładnie do [9.9248,12.155] po **82.03334 s**; obie H70 śluzy otwarte/zmienione w odpowiednich stanach, bez przenikania; kompilacja swiftc -O, wykonanie PASS;
- gracz blokujący poszerzony odcinek w [11.908,17.119]: lokalny plan A*, **1 bezpieczne obejście**, powrót po **81.98334 s**, pełny postój 5 s, bez przenikania; PASS;
- wymuszone zamknięcie śluzy H70 w X=24.36: NPC nie przenika, nie używa A* przez skrzydło, przerywa patrol po 2.5 s nieprzerwanej blokady; PASS;
- gracz pozostaje obok mechanika po dialogu: NPC czeka do odejścia poza 2.5 m; PASS;
- podmieniona geometria nie zawierająca dalszej trasy: preflight odrzuca scenę; PASS;
- po ukończeniu NPC nie startuje sam ponownie, yaw wraca do 0; PASS;
- Testy H08 CI: https://github.com/synixad-png/asteroidy-ios/actions/runs/42568810523 PASS, w tym kompilacja testu z rzeczywistym GLB do wykonania poza CI. Na GH jest niezmieniony kompletny kod źródłowy testu.

## 4. Ograniczenia
Nie wykonano interaktywnego testu na fizycznym iPhonie/iPadzie (H15); ukończenie source H08 ≠ wizualny odbiór SceneKit, GLTFKit2 i ruchu NPC na sprzęcie.
Złożone animacje kości, Foot IK, blendowanie i dystansowe odtwarzanie chodu pozostają H09; nie oznaczać ich jako ukończone w H08. Zakładka H08 jest ukończona w zakresie bezkolizyjnej nawigacji, orientacji root i source parity, ale na 100% końcowego odbioru czeka test urządzenia H15 oraz zależność H09 dla obrotów kości.
Kompilacja IPA wymaga oryginalnej binarnej zależności GLTFKit2 0.5.15; GitHub pobierając z oficjalnej paczki otrzymywał HTTP 504. Dedykowany workflow .github/workflows/h08-test-ipa.yml ponawia pobranie maksymalnie pięć razy bez zmiany wersji pakietu. Nie należy deklarować gotowej IPA, dopóki GitHub Actions nie zwróci rzeczywistego wyniku PASS i poprawnego artefaktu.
Kod PC source Windows v580 i kontrolne mechanizmy H01–H07 nie zostały zastąpione, H09 nie został rozpoczęty.

## 5. Następne w harmonogramie
Po przejściu bramki H08 i dołączeniu raportu wydania: H09 — oryginalne klipy mechanika, Foot IK, fizyka 110kg/15 kości, blend i odtwarzanie animacji przez faktyczny dystans. H15 niezależnie potwierdza realne urządzenia i FPS.

## 6. Zweryfikowane wydanie H08 dla iPhone/iPad
- GitHub Actions 42569096340 (https://github.com/synixad-png/asteroidy-ios/actions/runs/42569096340) PASS: source H01–H08, oficjalna przypięta GLTFKit2 v0.5.15, natywna kompilacja ARM64, 13/13 zasobów Carbonis/W3, CRC IPA i raporty.
- Commit gry/IPA: 06c29d80c611c5a672595e2194cd96f4e99d3bb6. Później tylko raporty i harmonogram, brak zmiany aplikacji.
- IPA ASTEROIDY_v580_H08_MECHANIK_PELNY_PATROL_TEST_UNSIGNED.ipa: 29919699 B, SHA256 d90a7feb4d0326e1a50444aef3c60190248dfbd2d21ed843f44329a9aa214c56, zgodny z SHA256SUMS.txt z macOS. Lokalnie niezależnie: CRC PASS, 73 rekordy, 13/13 zasobów, Payload app/Info.plist, arm64, minimum iOS 17.0.
- GitHub artifact id 13653230471 ZIP z tą samą IPA i raportami, rozmiar 29280114 B, CRC ZIP PASS.
- Google Drive plik odczytany po zapisaniu: https://drive.google.com/file/d/1SUCpfb-3Kmnqw00MVNm9a79KGf1skGNx/view?usp=drivesdk, rozmiar 29280114 B.
- Niepodpisane IPA; oryginalny hangar GLB wymaga importu z Plików iOS. Fizyczne sprawdzenie chodzenia NPC/SceneKit i Foot IK H09 nadal nieprzeprowadzone, H15 otwarty. Nie utożsamiać udanej kompilacji z odbiorem interaktywnym.

## 7. H08 — dodatkowa naprawa odkryta w teście blokowania drogi powrotnej (09.11.2026)

**Potwierdzona luka oryginalnego PC v580:** `Windows/src/H55Renderer.cs`, procedura `NpcPlanPlayerBypass532`, linie źródłowe ~1768–1800: przy zajęciu waypointu zmienna `limit` jest zawsze ograniczana `Math.Min(NpcWorkshopIndex530-1,routeIndex+3)`. Działa tylko na trasie wychodzącej (indeksy 0–10). Na drodze powrotnej (indeksy 12–27) `limit<routeIndex+1`, więc NPC nie może wybrać żadnego dopuszczonego punktu obejścia. To źródłowa usterka, nie nowa wymyślona geometria.

**Dowód E2E przed zmianą:** na oryginalnym SHA-zweryfikowanym GLB, ze stałym graczem po 5 s w miejscu `(X=14.2,Z=11.181)`, NPC omija gracza na wyjściu (`detoursBuilt=1`), dochodzi do warsztatu, czeka dokładnie 300 klatek, przechodzi obie H70, wraca do celu 23 i **zatrzymuje się na stałe w (15.00908,11.314705)**. Symulacja 15000 klatek 60 FPS kończy się `TIMEOUT blocked`. Nie uznawano tego za sukces.

**Zminimalizowana poprawka** `ASTEROIDYiOS/H55NpcDetour580.swift`: wybór końca bieżącej nogi podróży: `goalIndex <= workshopIndex ? workshopIndex-1 : routeX.count-1`; nadal bezwzględnie obowiązują: źródłowe 28 punktów, limit maks. 3 kolejnych waypointów, dystans sprawdzania 6m, A* 0.24m, oryginalne próbkowanie segmentu 0.08m oraz kolizje gracza/GLB. Cel warsztatowy (indeks 11) nadal jest obowiązkowym postojem i **nigdy nie wolno go przeskoczyć**. Jest to jawna naprawa rozbieżna z błędnym PC, a nie deklaracja dokładnej zgodności 1:1 dla tej sytuacji.

**Testy po poprawce, bez fałszywej posadzki**: oryginalny `hangar_h55.glb` 126419336 B SHA256 `00e6ba4ab2cce025b1290265052c1e252e149209f6fcbbc50b5d569af4592461`, 803538 trójkątów i 233 kolidery, 1136 próbek trasy. Test `Tests/H55NpcRealRoute580Tests.swift` przeprowadzony natywnie z aktualnymi źródłami po poprawce `<=`:
- Bez gracza na trasie: **4922 klatki, 87.38785 m**, 300 klatek postoju, dwie H70 otwarte i przekroczone, root wraca do źródłowej pozycji, brak auto-restartu: **PASS**.
- Gracz w (14.2,11.181) od klatki 300: **5102 klatki, 2 rzeczywiste obejścia A*** (wyjście i powrót), 300 klatek postoju, obie H70, root z powrotem dokładnie `(9.9248,12.155)`, fizyczny test pozycji Y, 4-sferowe `BodyClear` wzdłuż trasy: **PASS**.
- W obu wariantach stosowano oryginalnie zmierzony z obu łańcuchów stóp GLB `anatomicalHeading=-2.323263891`. Żadne testy syntetycznej podłogi nie zastępują raportowanych realnych testów.

**Wyniki CI**: repozytoryjne H08 źródła/test oryginalnego GLB `Tests/H55NpcRealRoute580Tests.swift`, przepustki `.github/workflows/h08-npc-route.yml`, `.github/workflows/h08-parity-check.yml`, `.github/workflows/h08-test-ipa.yml` skompilują i kontrolują nowy scenariusz. GitHub Actions jest raportowany oddzielnie po zakończeniu przebiegów. `main` pozostaje niezmienione; źródła H01–H07, H09 i inne moduły gameplay pozostawiono bez zmian.

**Odbiór**: źródłowa funkcjonalność H08 + realne GLB z naprawionym powrotem PASS; nadal nie wykonano interaktywnego testu iPhone/iPad z renderowanym NPC/SceneKit (H15). H09 Foot IK/animacje kości to osobny etap i nie mogą automatycznie zwiększać procentu H08. Nie wolno twierdzić, że usterka A* w oryginalnym PC została naprawiona — zmieniono wyłącznie port iOS.

## 8. Wydanie po naprawie powrotnego A* — prawdziwa nowa IPA (09.11.2026)
- **Aktualny build źródłowy H08 z naprawą A*:** GitHub Actions [42570295910](https://github.com/synixad-png/asteroidy-ios/actions/runs/42570295910), ponowiona próba nr 2, ostatecznie **PASS**. Commit gry/IPA `05f2f1f546533814f80fbc4d6f5e00e306915fdf` zawiera zmianę `goalIndex<=workshopIndex` i pełny test autentycznego GLB; później zmieniono tylko testy, skrypty CI, raporty i harmonogram.
- Pierwsza próba zablokowana wyłącznie przez oficjalny serwer GLTFKit2 v0.5.15 HTTP 504 po 5 próbach, nie przez błąd Swift. Druga próba pobrała dokładnie tę samą przypiętą wersję i zbudowała aplikację ARM64, bez zmiany biblioteki.
- Właściwy **nowy plik IPA** `ASTEROIDY_v580_H08_NAPRAWA_POWROTU_MECHANIKA_TEST_UNSIGNED.ipa`: `29 919 744` B; SHA256 `18179a71781d48d3c74a5223710354f70b84ecbba3ddbbe4f42f6a4fc61053e0`; identyczna suma z macOS `reports/SHA256SUMS.txt`. Nazwa zmieniona wyłącznie dla odróżnienia poprawki, zawartość IPA bez modyfikacji.
- Niezależna weryfikacja po pobraniu: **ZIP/IPA CRC PASS**, `73` rekordy, 13/13 oryginalnych zasobów W3/Carbonis PASS, `Payload/ASTEROIDY iOS.app/Info.plist`, architektura `arm64` PASS, rodzina urządzeń `[1,2]` (iPhone/iPad), minimalna wersja iOS `17.0`. GLB nie jest wbudowany i nadal wymaga importu z Plików. Plik jest niepodpisany.
- GitHub artifact id `13653028414`, ZIP z tym IPA + raportami, `29 279 897` B, CRC PASS. Zweryfikowana kopia Google Drive: https://drive.google.com/file/d/1Ep8aEv9pJ0rUYHX3qLj-J4sOTrAKUHbU/view?usp=drivesdk (odczytano metadane nazwy i rozmiaru).
- CI `42570767989` pełna regresja rozgrywki, iOS Swift/Metal **PASS**; `42570764204` H08 parity **PASS**, No Slop **PASS**. Ogólny source-only CI po wcześniejszym HTTP 504 dostosowano do pięciu prób pobrania przypiętego GLTFKit2; nowy CI jest raportowany osobno.
- Fizyczne testy iPhone/iPad/SceneKit pozostają otwarte jako **H15**; H09 (Foot IK i animacje kości) jest osobnym zadaniem. Nie twierdzić, że naprawiono oryginalny PC v580; poprawka jest tylko w iOS.

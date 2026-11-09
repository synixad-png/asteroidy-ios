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

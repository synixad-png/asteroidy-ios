# ASTEROIDY iOS — BOREAS 05 (tymczasowa planeta testowa)

Data: 13 listopada 2026. Gałąź: `feature/ios-boreas-test-05` (PR #33). Baza: `feature/ios-kestrel-pc609`.

## Model źródłowy

`PortingResources/v568/Shared/assets/planets/boreas_ferrofluid.glb` z czterech pakietów źródłowych GitHub; źródło PC v568 i PC v609 jest bajtowo identyczne:
- GLB: 2 899 120 bajtów, SHA256 `cdd6417889452b60dd36fe9b2a4931259826852e613d84766b18165759ead759`.
- 49 węzłów, 3 współdzielone siatki, 1 autorski klip `FERROFLUID_KAZDY_KOLEC_INACZEJ_5s_LOOP`.
- 97 kanałów glTF: jeden `weights` (6 morph targets), 48 `translation` i 48 `scale`. Pozostałe 48 węzłów to 24 metalowe krople i 24 filamenty.
- 912 oryginalnych klatek kluczowych TRS (bez interpolacji przy eksporcie), wszystkie z `LINEAR`, czasy 0–5 sekund.
- Lokalna siatka planetarna na poziomie AS3D (31 355 wierzchołków), 4 320 wierzchołków 48 ruchomych węzłów, 27 035 wierzchołków deformacji morfologicznej.

## Architektura portu

Nie dodano drugiego renderera, „cząstek” proceduralnych ani dodatkowej sceny 3D. Użyto tego samego źródłowego `MetalRenderer`, 30-Hz limitu aktualizacji deformacji, trzech buforów wierzchołków i jednego zegara animacji. W odpowiednich zakresach jednego bufora GPU aktualizowane są morph targets i 48 węzłów TRS.

- `BoreasMorphRenderer556.swift`: dotychczasowe deformacje, bez modyfikacji.
- `BoreasNodeTracks556.swift`: odczyt 48 węzłów i 912 oryginalnych klatek, próbkowanie linearnych translacji i niejednorodnych skal oraz przekształcanie lokalnych normalnych według źródłowego kwaternionu.
- `Tools/export_boreas_node_tracks556.py`: odtwarzalny eksporter oparty wyłącznie na standardowej bibliotece Pythona i czterech oryginalnych archiwach z GitHub. Dokładny ASNT v1: 21 218 bajtów SHA256 `bdf22733cfe6a1314517537e2400019a97c3a83507b8f654fd1307dbf9809edc`.
- `AnimatedPlanetTestSlot556.swift`: wspólna konfiguracja zasobów, SHA256 i identyfikatora 05; przy przyszłej wymianie modelu należy zmienić tę konfigurację i dane nowego modelu bez naruszania trybu gry.
- `AnimatedPlanetTestPage556.swift`: odrębna scena dostępna z atlasu W3 przyciskiem `BOREAS 05 · TEST ANIMOWANEJ PLANETY GLB` z powrotem do atlasu.

## Granice funkcjonalne

BOREAS 05 jest wyłącznie **testem wizualnym iOS**. Nie odblokowuje sektora 5, nie zalicza misji, nie zapisuje ręcznego slotu, nie zmienia postępów ani waluty, nie zastępuje CARBONIS czy planety głównej H290. Test udostępnia renderowany model i istniejącą demonstracyjną scenę lotu, **nie pełną piątą misję z PC**.

W źródłowym GLB pierwsza i ostatnia klatka kanałów TRS nie są identyczne; port odtwarza rzeczywiste klatki i oryginalną pętlę pięciosekundową bez sztucznego wygładzenia ich końców. Wymagane są testy wyglądu / wydajności na rzeczywistym iPadzie. Sama kompilacja Swift/Metal, CRC IPA, SHA256 źródeł i testy wykonywalne nie zastępują testu graficznego Apple GPU.

## Kontrole wydania

- Odtworzenie `Boreas556.asnt` z czterech archiwów SHA256 i weryfikacja zawartości oryginalnego `.glb`.
- Test `Tests/BoreasNodeTracks556Tests.py`: 48 węzłów, 96 transformacji, 912 klatek, zakresy, float32 i SHA256.
- Test `Tests/BoreasTestPlanet05Contract.py`: integracja z jednym rendererem, pełna pętla animacji, izolacja postępu i nawigacja W3.
- Kontrola w IPA wszystkich czterech oryginalnych zasobów Boreas (AS3D, ASMO, JSON, ASNT), pełnego źródłowego zestawu gry PC609, testy HUD, broni, osłon v608, regeneracji pancerza v609 i statków.

Status działań CI i iPad należy podawać osobno i aktualizować na podstawie rzeczywistych przebiegów GitHub Actions — nie zakładać PASS przed ich ukończeniem.

# ASTEROIDY iOS — H02 ZAKOŃCZONY: port oryginalnej geometrii kolizji PC v580
Data: 2026-11-08
Baza iOS: PR #28, `feature/ios-h55-v580-native-entry`.

## Status i zakres
- **H02: 100% implementacji i możliwych do wykonania testów geometrii źródłowej.**
- **Brak regresji w kodzie gry:** moduł `ASTEROIDYiOS/H55CollisionGeometry580.swift` jest osobnym producentem danych. Nie podłączono go przedwcześnie do ruchu ani SceneKit. Podłączenie odbędzie się w H03/H04, po portowaniu indeksu oraz pełnego odpytywania kolizji.
- Punkty H01, H03–H16 pozostały bez zmian funkcjonalnych. Nie wydano nowego IPA.

## Jedyna podstawa implementacji
- `Windows/src/HangarCollision441.cs` (PC ASTEROIDY v580, 203 linie), `Windows/src/H71DroneImports461.cs`.
- Wskazana przez użytkownika rzeczywista scena `hangar_h55.glb`, **126419336 bajtów**, SHA256 `00e6ba4ab2cce025b1290265052c1e252e149209f6fcbbc50b5d569af4592461`.
- Żadne współrzędne, trasy, kolidery, wyjątki czy progi nie zostały wymyślone ani oparte na starym `GpuHangar91/99`.

## Zawartość H02, portowana 1:1 względem reguł oryginału
1. Walidacja nagłówka GLB2, struktury aktywnej sceny, referencji i indeksów.
2. Odtwarzanie hierarchii węzłów, transformacji column-major TRS/matrix, wykrywanie cykli i błędnych dzieci.
3. Parsowanie i cache POSITION float32/uint16/int16/uint8/int8 z normalizacją `KHR_mesh_quantization`, indeksy uint32/uint16/uint8, stride i offsety view.
4. Światowa siatka statycznych trójkątów bez degeneratów oraz z oryginalnym wyjątkiem dekoracji wąskiego korytarza.
5. Zgrupowane bryły prefabów na podstawie `hangarLabPrefabId` (także dziedziczonego po przodku), z fallbackiem nazw zgodnym z PC i odróżnieniem duplikowanych instancji.
6. Zweryfikowane dwa ruchome drony przed mechanikiem wyłączone z nieruchomych koliderów; trzeci importowany dron pozostaje elementem statycznej sceny. Ruchomy, oskórowany mechanik wyłączony.
7. Oryginalne wykluczenie sterowanych animowanych paneli H70 z **nieruchomej** geometrii; zachowanie ich zasięgu w danych aktywnej sceny (zgodnie z oryginałem).
8. Puste ramy portali mierzone z rzeczywistych punktów świata i rozcinane na dwa filary i górną belkę wyłącznie po spełnieniu progów oryginału; brak zgadywanego otworu, jeśli brak pomiarów.
9. Oryginalny, sześciotrójkątowy mostek korytarza `HangarCollision441.cs:188`.

## Zweryfikowany wynik na prawdziwym GLB
Porównanie przeprowadzono dwoma niezależnymi odczytami geometrii: kodem Swift na bazie dokładnej procedury PC i niezależnym odtworzeniem algorytmu C# w Python/NumPy na tym samym GLB. Nie stosowano sztucznych danych ani wyłącznie sprawdzania kompilacji.

| Metryka | Swift H02 | Niezależny odczyt PC | Wynik |
|---|---:|---:|---|
| Aktywne węzły | 2502 | 2502 | PASS |
| Źródłowe trójkąty (w tym grupy prefabów) | 17033549 | 17033549 | PASS |
| Trójkąty przypisane grupom prefabów | 16228108 | 16228108 | PASS |
| Trójkąty rzeczywistej geometrii statycznej | 803538 | 803538 | PASS |
| Współrzędne rzeczywistych trójkątów | 7231842 | 7231842 | PASS |
| Grupy prefabów przed podziałem portali | 217 | 217 | PASS |
| Końcowe fizyczne bryły prefabów | 233 | 233 | PASS |
| Hollow portal frame → jambs/header | 8 ram podzielonych | 8 ram podzielonych | PASS |
| Granice X/Z | (-29.028847,51.95) / (-18.428425,19.965) | identyczne z zaokrągleniem | PASS |
| Dopasowanie nazw 233 brył | 233/233 | 233/233 | PASS |
| Maks. różnica wartości dla 233 brył | 0.00000185 m | próg 0.001 m | PASS |
| Maks. różnica na 7231842 współrzędnych | 0.0000009537 m | próg 0.0001 m | PASS |
| Liczba błędnych współrzędnych > 0.00001 m | 0 | 0 | PASS |

Wyniki nie wymagają zapisywania 126 MB sceny w GitHub ani duplikowania danych binarnych w paczce IPA.

## Testy automatyczne / regresja
- `Tests/H55CollisionGeometry580Tests.swift`: syntetyczny poprawny GLB2 z 10000 trójkątów architektury, normalizowanymi uint16, dziedziczonym prefab instance ID, dwoma ruchomymi dronami, trzecim statycznym dronem, animowanymi drzwiami, dodatkowymi mostkami i transformacjami; odrzucanie uszkodzonego pliku.
- Test konstrukcyjny i kompilacja Swift na Linux: PASS.
- Kompilacja iOS source-only, kontrola jakości, pozostała regresja: wyniki CI należy raportować oddzielnie zgodnie ze stanem danej kompilacji.
- Realny iPhone/iPad, dynamiczne H03/H04 BodyClear, wejście do hangaru H05: **NIE TESTOWANE W RAMACH H02**.

## Następny punkt stałego harmonogramu
**H03: oryginalne `H55FullCollision379` 2-metrowe wiadra, `Support`, `SupportLowest403`, prefaby, bryły statku oraz rzeczywiste granice `H72Bounds392`.**
H04 (cztery sfery / Dist2) i H05 (wejście przy czterech poziomach) pozostają zależne od H03; nie wolno ich zaczynać na uproszczonym raycast SceneKit.

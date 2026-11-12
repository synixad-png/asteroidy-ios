# O02 — VANGUARD na H290: oryginalne zakupione ulepszenia w aktywnym locie

**Harmonogram:** O02 „Lot i sterowanie VANGUARDA na H290”, bez zmiany numeracji O01–O12. **Źródło prawdy:** oryginalny PC v602 ZIP o SHA256 359abd889544c846faa9426fd291df8528951ed2253fe67c47dbb9e9d9f2103b.

## Jedyna poprawiana, potwierdzona rozbieżność

- W PC: `Windows/src/Campaign37.cs:11–13` trzy **bieżące** właściwości `Acceleration`, `TopSpeed`, `TurnSpeed` zależą od `EngineLevel`, `ThrusterRank97` i `StabilizerLevel`. Na VANGUARDZIE (typ 1, masa 3.4): przyspieszenie = `245·(1+.06·engine)·(1+.045·thruster)`; prędkość = `390·(1+.035·engine)·(1+.025·thruster)`; obrót = `3.8·(1+.04·stabilizer)`; `Physics68.cs:9` `SurfaceSpeed68=TopSpeed·.40`. `FlightDynamics298.cs:14–24` aktualizuje `control` i prędkość płynnie, bez teleportowania i zerowania pędu.
- W iOS wcześniej: `PC602HomeWorldDriver291.start/loadOrbitSlot61` tworzył `Equipment(craft:.vanguard)` z trzema zerowymi rangami, chociaż legalne zakupy `H55SourceMechanics580.State` już zawierają `engine`, `thruster`, `stabilizer`.
- **Poprawka:** jedna źródłowa fabryka `vanguardEquipment291` odczytuje te trzy rzeczywiste wartości (0–2) z istniejącego profilu. Przy tworzeniu H290 i po wczytaniu zapisu używany jest ten wyposażony VANGUARD. Po powrocie z H55 i po rozliczeniu Carbonis 01 odświeżana jest **jedynie** konfiguracja bieżącego `FlightDynamics556`, bez zmiany pozycji, wysokości, pędu, kamery, HUD, mechaniki strzelania lub historii gry. Nie włączono żadnych innych statków.
- Jeśli `selectedShip!=1`, nie podstawiać pod spodem VANGUARDA pod inną nazwą: port odrzuca nierozpoznaną konfigurację i jawnie informuje o obsługiwanym modelu.
- **Dowód formuł:** `Windows/src/Campaign37.cs` SHA256 `7418d8622bbe2a7b68c33823698572ebc011879c4576922bb58128c000b68874`; `Physics68.cs` `SurfaceSpeed68`; `FlightDynamics298.cs` SHA256 `111420ecfa889d360bc5557a56b3be8cab1846ed54fa6f30184da78b9a1e5fd0`.

## Testy i status odbioru

- Test `Tests/PC602HomeFlight291Tests.swift`: **27** kombinacji oryginalnych legalnych rang 0–2; wartości przyspieszenia, prędkości, obrotu i współczynnika sterowania; wynik jednego kroku dla równania `DirectMotion298` przy `dt=1/60`.
- Test żywej podmiany konfiguracji: przed zmianą identyczne stany, po zmianie **natychmiast** zwiększona odpowiedź ruchu, przy niezmienionej pozycji/prędkości/kierunku/czasie w momencie zakupu; odmowa zastąpienia VANGUARDA inną jednostką.
- Test `PC602HomeWorldSession291Tests.swift`: przekazanie rang po zakupie bez restartu fizyki i negatywny test nieobsługiwanego statku.
- Potrzebne nadal: wieloklatkowa, niezależna symulacja PC C# ↔ Swift na tych samych danych, test dotykowy i pomiar na fizycznym urządzeniu. Dlatego **O02 nadal W TOKU; nie deklarować 100% ani pełnego odbioru**. Pozostałe zagadnienia O02 (kompletny sterownik i kamera) pozostają do niezależnej weryfikacji.

**O01 odebrano tylko jako audyt źródłowy. O03–O12 nie zmieniono.**
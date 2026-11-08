# H03 — PC v580 `H55FullCollision379`: indeksowanie i podpory
Data: 2026-11-08. Gałąź: PR #28. **Nie wydano IPA.**

## Źródła (nie domysły)
Oryginalny `Windows/src/HubWalk375.cs` z przesłanego archiwum ASTEROIDY PC v580, klasa `H55FullCollision379`: `Build`, `BuildProxies441`, `ProxyNear441`, `ProxyCapsule441`, `H72Bounds392`, `Support`, `SupportLowest403`; geometria z ukończonego H02 (`H55CollisionGeometry580.swift`) oraz rzeczywisty `hangar_h55.glb` SHA256 `00e6ba4ab2cce025b1290265052c1e252e149209f6fcbbc50b5d569af4592461`.

## Zmiany
- `ASTEROIDYiOS/H55SpatialSupport580.swift`: indeksowanie wszystkich rzeczywistych statycznych trójkątów do trójwymiarowych komórek 2 m dokładnie z kodem źródłowym PC oraz zgodnym 64-bitowym kluczem.
- Osobny 2-metrowy indeks prefabowych AABB, margines 0,4 m, blokada zakresów szerszych niż 64 komórki, źródłowe 3D `ProxyNear441` i czteropunktowe `ProxyCapsule441`.
- `Support` i `SupportLowest403`: barycentryczne wysokości podłóg i ramp, oryginalny filtr kwadratu normalnej (niezależny od winding), wybór najwyższej lub najniższej podpory z danego przedziału Y.
- `H72Bounds392`: rzeczywiste granice zewnętrznego GLB ±0,5 m, oddzielnie oryginalne zakresy wbudowanej sceny H71; blokowanie bryłą statku o promieniu 3,95 m, w oryginalnym przedziale pionowym.
- `Tests/H55SpatialSupport580Tests.swift`: test komórek przy współrzędnych ujemnych, odwróconych normalnych, dwóch wysokości nakładających się podłóg, braku podpory, warstw prefabu i granic.

## Wyniki porównania na rzeczywistym 126 MB GLB
- **803538** statycznych trójkątów H02; **233** bryły kolizyjne.
- **3646** zajętych 3D komórek trójkątów; **388** dwuwymiarowych komórek prefabów.
- **468** punktów/zasięgów testowych × `Support`/`SupportLowest403` = **936** niezależnie zweryfikowanych wyników, **0 rozbieżności** powyżej 0,0002 m; maksimum różnicy **0,000000229 m**.
- Dodatkowo **468** obliczeń czteropoziomowej energii kontaktu z AABB prefabów, maksimum różnicy **0,000000086 m²**, **0 rozbieżności**.
- Oracle: dwie niezależne implementacje projekcji barycentrycznej i kolizji AABB w Swift oraz NumPy na **tym samym rzeczywistym GLB**. Test sztucznych danych nie był jedynym dowodem.

## Granice ukończenia
H03 kończy obliczanie indeksu, podpor i granic; H03 **nie** zmienia jeszcze interaktywnego chodzenia. W H04 musi powstać dokładny `Dist2` i `BodyClear` trójkątów/sfer, dopiero później H05 może korzystać z rzeczywistych reguł wejścia. Brak testu na fizycznym iPhonie/iPadzie; będzie obowiązkowy w H15. H01/H02 i wszystkie istniejące mechanizmy zachowane. Brak nowego IPA.

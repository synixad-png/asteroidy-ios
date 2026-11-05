# ASTEROIDY iOS — zadanie 2 / silnik graficzny Metal: kamera sferyczna

**Data:** 2026-11-05.
**Oryginał:** wyłącznie ASTEROIDY v556 z oryginalnego archiwum `Asteroidy_v556_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`, SHA256 `d0f6b83659d080fcd9084a0d1618ef53feb29c51aeea476feb90457030787d08`.

## Potwierdzony problem

W dotychczasowym `MetalRenderer.swift` iOS `sphereFlight.camera` był aktualizowany zgodnie z `SphereCombat67`, ale renderowanie wszystkich scen wybierało stałą macierz `perspective * translation(0,0,-4)`. Shader `Ship.metal` dodatkowo zakładał, że kamera jest zawsze w `(0,0,4)` podczas liczenia odbicia Cooka–Torrance'a. Oznaczało to rozbieżność między pozycją statku/obliczaną orientacją kamery a rzeczywistym renderingiem sferycznym.

## Weryfikacja w źródłach C#

1. `Windows/src/SphereCombat67.cs:62` — `UpdateSphereCamera67` aktualizuje `SphereFocus67`, `SphereRight67` i `SphereUp67` (własny układ orientacji przenoszony równolegle nad planetą) z wygładzaniem `1-exp(-dt*9)`.
2. `Windows/src/GpuSphere67.cs:414` — `sphereEye67 = g.SphereFocus67 * (310 + ...)` w normalnym locie, `OrbitWorld50.View(sphereEye67,new IP(),g.SphereUp67,introView)`. Dodatki 65 dla aktywnego bossa i rozdzielenie kooperacji należą do przyszłych etapów 10–11, NIE są tutaj włączane na podstawie zgadywania.
3. `Windows/src/GpuPlanetGltf463.cs` — `HomeWorldOuterRadius523 = 100f * HomeOuterRadius523`, `HomeOuterRadius523 = 1.4419674`. W porcie na znormalizowaną jednostkową planetę pozycja kamery to `310/(100*1.4419674)` od środka, a nie stałe 4.
4. Wektor oka w lokalnym shaderze należy brać z tej samej macierzy widoku, której użyto do `MVP`. Materiały, lampy i współczynniki PBR nie są przy tym modyfikowane.

## Implementacja i brak regresji

- `ASTEROIDYiOS/Sphere67.swift`: `SphereCameraView556`, niezależny od Metal, oblicza źródłowy promień oka, wektory `right/up/back` i współrzędne kamery.
- `ASTEROIDYiOS/MetalRenderer.swift`: w trybie planety oblicza orbitującą macierz widoku z `sphereFlight.camera`; w płaskim trybie pozostawia stary `translation(0,0,-4)`. W istniejące `SceneUniforms.lighting.yzw` podaje pozycję oka bez zmiany rozmiaru bufora / jego struktury.
- `ASTEROIDYiOS/Ship.metal`: BRDF pobiera pozycję oka z uniformu, zamiast z nieprawidłowej stałej `float3(0,0,4)`. Wartości PBR, efekty, geometria, `.as3d` i oryginalny kod Windows/SteamOS są bez zmian.
- `Tests/SphereCameraView556Tests.swift`: osiem pozycji w różnych punktach planety (w tym okolice biegunów), ortonormalność układu, położenie środka i jednostkowego kadłuba, stabilność osi prawa/góra/tył oraz 240 kroków śledzenia statku.
- Workflow `.github/workflows/verify-metal-camera.yml` tylko na Linux — **PASS**, [GitHub run 42052748443](https://github.com/synixad-png/asteroidy-ios/actions/runs/42052748443), w tym parsing `MetalRenderer.swift` i `App.swift`.

## Czego ten test NIE potwierdza

- Nie jest to natywna kompilacja Xcode źródeł `MetalRenderer.swift` / `Ship.metal` po tej zmianie.
- Nie obejmuje wizualnego sprawdzenia na fizycznym iPhonie ani pomiaru FPS, sterowania dotykowego, tekstur i pełnej kampanii.
- Nie poprawia sztucznej inteligencji, orbit bossów ani wszystkich efektów oświetlenia, które mają odrębne zadania w zatwierdzonym harmonogramie.
- Osobny workflow IPA `42051262545` wystartował wcześniej z SHA `18e18797046dd37807650313990913dce38ab522`, więc **nie zawiera nowego kodu kamery**.

## Weryfikacja macierzy i pola widzenia — 05.11.2026

Dodatkowo porównano faktyczne definicje źródłowe, **bez wymyślania wartości**:

- `Windows/src/Orbit50.cs:32`: `OrbitWorld50.View` zapisuje kolumnowo macierz `(right, up, -forward)` i translację `(-dot(right,eye),-dot(up,eye),dot(forward,eye))`. `SphereCameraView556.viewColumnMajor` jest obecnie **jedynym** obliczeniem tej macierzy; `MetalRenderer.sphereView` bezpośrednio kopiuje jej 16 wartości do `simd_float4x4`. Usunięto wcześniejszą duplikację wzoru między testem a rendererem.
- `Windows/src/GpuIntro41.cs:455`: `IntroProjection()` używa `frustum(-.35555556,.35555556,-.2,.2,.4,1600)`; `GpuSphere67.cs:420` rzeczywiście wywołuje tę projekcję w trybie planety. Pionowy FOV wynosi `2*atan(0.2/0.4)≈53.1301°`, a nie poprzednie `36°`. Dodano `SphereProjection556` i dynamiczną wartość pionowej skali do renderera **tylko w trybie planety**. Płaska arena pozostaje przy swoim wcześniejszym ustawieniu kamery i FOV.
- W znormalizowanym Metal na iOS zachowano `near=0.1`, `far=20` dla lepszej precyzji głębi, zamiast naiwnie używać oryginalnych jednostek frustum świata w przestrzeni o promieniu planety `1`. To świadoma różnica renderowania, nie zmiana mechaniki.
- `Tests/SphereCameraView556Tests.swift`: sprawdza dokładne 16 elementów oryginalnej macierzy w punkcie referencyjnym oraz źródłowe `53.1301°` i dwie proporcje obrazu. Natywnego Apple/GPU testu nadal **nie przeprowadzono**.

**Automatyczne sprawdzenie**: [GitHub Actions 42055630937](https://github.com/synixad-png/asteroidy-ios/actions/runs/42055630937) — `source-camera-linux` **PASS**, sprawdzenie składni zmienionych plików SwiftUI/Metal **PASS**. Nie zastępuje to kompilacji z Xcode/Metal GPU.

## Integracja oryginalnego StampSphere67 dla statku i skał — 05.11.2026

Źródła odczytane bezpośrednio z oryginalnego archiwum C# v556, bez innej gry:

- `Windows/src/GpuSphere67.cs:4`: `Shell67=HomeWorldOuterRadius523+15f` oraz `Scale67=Shell67/Sphere67.Radius`; `HomeWorldOuterRadius523` z `GpuPlanetGltf463.cs` to `100*1.4419674`. Dla importowanego modelu Boreas o promieniu jednostkowym: `normalizedShellRadius=(outer+15)/outer`, `normalizedScalePerArcUnit=normalizedShellRadius/Sphere67.radius`.
- `GpuSphere67.cs:63`: `StampSphere67` buduje macierz modelu **col0=Cross(forward,normal)**, **col1=Sphere67.Vector(point,Game.Direction(angle)).Unit**, **col2=normal**, przesunięcie `normal*(Shell67+lift)`. Port wcześniej rysował statek i skały przez `translation(point)*scale` i obracał skały w osi globalnej — niezgodnie z oryginałem.
- `GpuSphere67.cs:133–134`: skały korzystają ze źródłowego `StampSphere67(rock.P,rock.Angle,rock.Radius*Scale67,...)` i obrotów `shipRotate(rock.Angle*41,1,0,0)`, `shipRotate(rock.Angle*23,0,1,0)`. Sektor 25 zachowuje nieobracany dodatkowo stempel i `BounceHeight265` jako radialny `lift`.
- `GpuSphere67.cs:368`: kadłub statku korzysta z `StampSphere67(ship,visualHeading,Game.ShipContactRadius*Scale67*.65)`, z obrotem przechyłu wokół Y i pochylenia wokół X. `Renderer.cs:193` przelicza `MissionShipScale472` ze skali procentowej na współczynnik; domyślnie jest to `1.0`.
- `Tools/export_vanguard.py` przeniósł oryginalną geometrię Vanguard z orientacji GLB na lokalny układ płaszczyzny XY o osi Z normalnej: dopiero `StampSphere67` mapuje te lokalne osie na rzeczywistą styczną powierzchni Boreas.

Zmiany wdrożone:
- `Sphere67.swift`: niezależny od Metal `SphereSurfaceStamp556` z oryginalnym układem lokalnym i skalowaniem; bez ingerencji w geometrię, `SphereFlight67`, `CombatSolids68`, `Action38` czy dane modelu.
- `MetalRenderer.swift`: nowy `sphereStamp()` używa **tych samych przetestowanych 16 współczynników macierzy**. Skały dostają obrót z `rock.Angle*41/23`, a statek wizualny heading/bank/pitch (stopnie dla obrotów bank/pitch). Przełączanie pomiędzy sferą i płaską areną zachowano.
- `Tests/SphereCameraView556Tests.swift`: wartości referencyjne stempla w punkcie (0,360), kierunki osi dla kąta 0 i π/2, promień osłony, 32 kombinacje położenia/heading, ortogonalność, skale i odległości od środka.
- [GitHub Actions 42057687378](https://github.com/synixad-png/asteroidy-ios/actions/runs/42057687378): **PASS** dla testów źródłowego stempla, kamery i parsowania Swift. Nie jest to natywne renderowanie Metal/GPU ani dowód wizualny.

Ograniczenia: szkicowa siatka asteroid i uproszczony, nierigowany eksport Vanguard nie są jeszcze wierną, kompletną rekonstrukcją źródłowych shaderów, tekstur, animacji GLB ani wszystkich efektów graficznych. Te braki wymagają dalszych etapów 2–5, bez przedstawiania ich jako zakończonych. Nie zmieniano workflow ani stanu IPA.

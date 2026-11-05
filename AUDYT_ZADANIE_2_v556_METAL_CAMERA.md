# ASTEROIDY iOS — zadanie 2 / silnik graficzny Metal: kamera sferyczna

**Data:** 2026-11-05.

**AKTUALNY STAN: źródłowa tekstura i obie warstwy gwiazd `IntroHalo` zostały przeniesione po odnalezieniu oryginalnego archiwum C# — szczegóły w końcowej sekcji tego raportu. Opisy poniżej dotyczące brakującej tekstury i uproszczonych trójkątów przedstawiają wcześniejsze etapy, a nie obecny kod.**
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

## Niebo z oryginalnego ASTEROIDY v556 — weryfikacja i ograniczenia

Oryginalne źródła z `Asteroidy_v556_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`:

1. `Windows/src/GpuAmbient37.cs:6–7`: `SpaceHash207` i `SpaceRand207` — 32-bitowe mnożenie z przepełnieniem przez stałe `0x7feb352d` i `0x846ca68b`; wejście seed/index/salt miesza przez 73856093, 19349663, 83492791.
2. `Windows/src/GpuIntro41.cs:452`: **1500** gwiazd, losowania `SpaceRand207(41,i,17/31/53/71)`; współrzędne kierunkowe `(cos(a)*sqrt(1-y²),y,sin(a)*sqrt(1-y²))`, `a=rx*6.2831853`, `y=ry*2-1`; rozmiar 0.7/1.4/2.8 piksela, dwa oryginalne odcienie: ciepły `RGBA(249,205,161,235)`, zimny `RGBA(186,214,244,220)`. Oryginał rysuje poświaty za pomocą `IntroHalo` na płaszczyźnie 2D.
3. `Windows/src/GpuIntro41.cs:25–26`: `SkyProject55` wyświetla pozycję `direction*900` w orientacji `introView`, bez translacji oka, `focal=720`. `GpuSphere67.cs:420` rysuje niebo `IntroSky` **przed** planetą i obiektami, a scenę czyści kolorem `(.012,.021,.04,1)`.

Przed zmianą `MetalRenderer.swift` rysował **zero** źródłowych gwiazd w podglądzie planety; jedyne `starMesh` było odrębną, 130-elementową dekoracją płaskiej areny.

Nowe zachowanie:

- `Sphere67.swift`: `SphereSky207` odtwarza dokładny hash i 1500 kierunków, wielkości oraz kolorów z C#. Źródłowy promień 900 jednostek dzielony jest przez `100*1.4419674` do skali importowanej planety.
- `MetalRenderer.swift`: tworzy **raz** dodatkowy, statyczny bufor trójkątów oraz indeksów, umieszczony względem bieżącej pozycji kamery, nie zaś względem obracającego się statku. Wszystkie gwiazdy podlegają tej samej macierzy kamery i są emitowane **jednym rysowaniem GPU** przed planetą. Nie zmienia to LCG ani widoku płaskiej areny.
- `MetalRenderer.swift`: w widoku planety wybiera dokładnie źródłowe `clearColor(.012,.021,.04,1)`, poza nim zachowuje wcześniejsze `(.01,.025,.07,1)`.
- `Tests/SphereCameraView556Tests.swift`: sprawdza niezależne wartości wejściowe PRNG i kierunek pierwszej gwiazdy, 1500 unormowanych kierunków, właściwe skale i palety. [GitHub Actions 42060152260](https://github.com/synixad-png/asteroidy-ios/actions/runs/42060152260): **Swift/Linux PASS**, w tym parsowanie aktualnych plików SwiftUI/Metal.

**Świadomie nieukończone:** obecny Metal rysuje **uproszczone, nieprzezroczyste trójkąty** w oryginalnych kierunkach i kolorach RGB; to nie są jeszcze oryginalne, przezroczyste, teksturowane poświaty `IntroHalo`, nie odtworzono ich wariantów jasności ani całego `IntroSky` (mgławice i promienie). Nie twierdzić, że jest to 100% zgodności wyglądu z oryginałem, ani że przeszło test iPhone/Apple GPU. Renderowany rezultat nie został obejrzany na fizycznym urządzeniu.

## Gwiazdy RGBA z oryginalnym rozmiarem pikselowym — kolejna poprawka

W poprzedniej wersji z 1500 źródłowymi gwiazdami renderer rysował dla każdej gwiazdy **trzy nieprzezroczyste wierzchołki tworzące trójkąt w przestrzeni 3D**. Naruszało to dwie potwierdzone właściwości `GpuIntro41.cs:452`: `pixelSize` (0.7/1.4/2.8 piksela) i źródłową przezroczystość `RGBA` (235 lub 220 jednostek alfa).

W aktualnej poprawce:

- `MetalRenderer.sphereSky207()` generuje **1500 pojedynczych punktów** zamiast 4500 wierzchołków trójkątów, zachowując autentyczne kierunki `SpaceRand207`, barwy, źródłowe `pixelSize` oraz `alpha`. Dane zajmują około 102 kB zamiast około 306 kB (64 bajty/wierzchołek + 4 bajty indeksu; te wielkości są szacunkami layoutu, nie pomiarem GPU).
- `Ship.metal`: oddzielny `skyPointVertex` ustawia `[[point_size]]` z oryginalnego `pixelSize` (dla limitu sprzętowego co najmniej 1 px), `skyPointFragment` wykorzystuje `[[point_coord]]`, maskę kołową i rzeczywistą przezroczystość źródłowego koloru. **Miękkie wygładzenie krawędzi jest jawnym przybliżeniem renderowania**, nie rekonstrukcją nieudostępnionej tekstury `IntroHalo`.
- Shader fragmentów ma osobny `SkyPointFragmentInput`, ponieważ `[[point_size]]` jest **wyłącznie atrybutem wyjściowym shadera wierzchołków**; błędne umieszczenie go w `[[stage_in]]` jest chronione testem.
- `MetalRenderer` tworzy oddzielny pipeline z `sourceAlpha / oneMinusSourceAlpha`, bez zapisu głębi i z jednym `drawPrimitives(type:.point,vertexCount:1500)`. Po rysowaniu przywraca poprzedni pipeline PBR i dotychczasowy depth test. Płaska arena i jej niezależne 130 gwiazd pozostają bez zmian.
- `Tests/SkyPointSourceContract556.py` sprawdza ciągłość przekazywania rozmiaru/alfa, kontrakt dwóch shaderów, stan blend/depth i brak powrotu do trójkątów. `Tests/SphereCameraView556Tests.swift` nadal porównuje źródłowe 1500 kierunków i wartości RGBA. Te testy są **statyczne/Swift/Linux** i nie oznaczają, że kompilator Apple Metal ani prawdziwy GPU wykonały shader poprawnie.
- Źródło techniczne API: dokumentacja Apple dla `MTLPrimitiveType.point` potwierdza konieczność `[[point_size]]` na wyjściu wierzchołka; specyfikacja Metal Shading Language definiuje rasteryzatorowe `[[point_coord]]` i rozdzielenie sygnatur etapów.

**Wciąż NIE wykonano:** teksturowanych poświat `IntroHalo`, mgławic i promieni oraz natywnej kompilacji/testu na Apple GPU po tej poprawce. Nie deklarować zgodności 1:1 z oryginalnym renderingiem tła. Nie sprawdzano ani nie modyfikowano stanu IPA na życzenie użytkownika.

## Kontrola rozdzielczości ekranów Retina — 05.11.2026

Źródło: `GpuIntro41.cs:25–26`, w którym funkcja `SkyProject55` przyjmuje `focal=720` i tworzy obraz referencyjny w przestrzeni 720-pikselowej. Oryginalne `pixelSize` (0.7 / 1.4 / 2.8) ma jednostkę rozmiaru ekranu w obrazie referencyjnym, podczas gdy `Metal` `[[point_size]]` opisuje piksele rzeczywistego `MTKView.drawableSize`.

- `SphereSky207.drawableScale(height:)`: przenosi oryginalną skalę referencyjną do iPhone'a proporcjonalnie do wysokości bufora `height/720`, z bezpiecznym `1.0` dla niefinitywnych lub zerowych rozdzielczości.
- `MetalRenderer.swift`: podaje tę skalę jako oddzielny parametr istniejącego uniformu sky, bez przebudowy `SceneUniforms`, ponownego tworzenia siatki ani dodatkowego rysowania.
- `Ship.metal`: `[[point_size]]` przyjmuje `max(1,sourcePixelSize*drawableHeight/720)`, zachowując oryginalny rozmiar w 720 px i skaluje go do Retina. Dolna granica 1 px jest ograniczeniem rastryzacji punktów, a nie oryginalnym parametrem gry.
- `Tests/SphereCameraView556Tests.swift`: punkty kontrolne 360→0.5, 720→1, 1440→2 oraz 0/NaN→1. `Tests/SkyPointSourceContract556.py` chroni przekazanie skali przez renderer i shader.
- [GitHub Actions 42062785842](https://github.com/synixad-png/asteroidy-ios/actions/runs/42062785842) — **PASS** dla Swift/Linux, statycznego kontraktu Metal i składni SwiftUI/Metal.

**Nadal nie zweryfikowano:** natywnej kompilacji shaderów Apple, obrazu na urządzeniu i dokładnej tekstury `IntroHalo`. Nie sprawdzano statusu IPA.

## Aktualny kod źródłowy v556 — rzeczywiste StarTexture/IntroHalo (zastępuje wcześniejsze przybliżenia)

Po odnalezieniu rzeczywistego archiwum `Asteroidy_v556_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip` i odczytaniu `Windows/src` potwierdzono następujące fakty:

- `GpuAmbient37.cs:5` — `StarTexture()` generuje **64×64** pikseli `Format32bppPArgb`; dla każdej pary `x,y`: `dx=(x-31.5)/31.5`, `dy=(y-31.5)/31.5`, `r=sqrt(dx²+dy²)`, `edge=max(0,1-r)`, `a=(byte)(exp(-4*r²)*edge²*255)`. **Wszystkie cztery kanały BGRA mają taką samą wartość `a`**. Filtr tekstury w `GpuRenderer.cs:62–64` to `LINEAR`.
- `Gpu2DRenderer.cs:68,70,74` — `Begin2D/Flush2D` używa **premultiplied alpha**: `blendFunc(ONE,ONE_MINUS_SRC_ALPHA)`, a `Vertex2D` zapisuje `RGB=tintRGB*tintAlpha`. Wcześniejsze `sourceAlpha` w portowanym niebie Metal było rozbieżne.
- `GpuIntro41.cs:23,451–452` — `IntroHalo(p,radius,tint,halo)` to kwadrat o bokach `2*radius` z teksturą `StarTexture`. Dla **każdej** gwiazdy używa promienia `size*2` (czyli średnicy **4*size**: 2,8/5,6/11,2 px). Dla gwiazd `rz>.87` i aktywnego `GlowEnabled` najpierw dodaje **dodatkowy halo 10 px**, a dla `rz>.98` — **21 px**; oba z alfą 125/255. Domyślnie `Renderer.cs:25` ma `GlowEnabled=true`. Źródłowy `SpaceRand207` daje dokładnie **1294 normalne, 172 średnio jasne i 34 bardzo jasne gwiazdy**, a także **161 ciepłych**. Dlatego oryginalny widok z włączonym glow ma **1706 nakładających się warstw** (1500 podstawowych + 206 dodatkowych).
- `GpuSphere67.cs:420` wywołuje `IntroSky(glow,nebula,rays,true)`. Opcje oddzielnych mgławic i promieni nie zostały jeszcze wdrożone; w bieżącym podglądzie domyślny oryginalny stan glow=true jest odtwarzany statycznie do czasu portu ustawień (zadanie 14).

Implementacja aktualna:

- `SphereSky207.haloTexelsBGRA()` odtwarza dokładnie powyższe **16384 bajty** 64×64×4, łącznie z zaokrągleniem w dół przy konwersji do `UInt8`. Przykładowe wartości z oryginalnego wzoru: (31,31)→243, (31,10)→3, (31,16)→24, (31,20)→60, (31,24)→117, (31,28)→191.
- `MetalRenderer.makeSphereHaloTexture` tworzy **jedną** teksturę `BGRA8Unorm` o wymiarach 64×64, z filtrowaniem liniowym w MSL i bez duplikowania tekstury na każdą gwiazdę.
- `sphereSky207()` umieszcza w buforze najpierw dodatkową jasną poświatę, potem podstawową, zgodnie z kolejnością `GpuIntro41.cs:452`, i renderuje wszystkie 1706 punktów **jednym poleceniem drawPrimitives**. Ekranowa wielkość jest skalowana na iPhone/iPad według `drawableHeight/720`.
- `Ship.metal` **próbkuje rzeczywistą teksturę 64×64**, a kolor wierzchołka i stan blend są premultiplikowane zgodnie z `Gpu2DRenderer.cs`: `srcRGB=ONE`, `dstRGB=ONE_MINUS_SRC_ALPHA`, również bez zapisów do głębi. **Usunięto poprzednią improwizowaną maskę `smoothstep`.**
- `Tests/SphereCameraView556Tests.swift` weryfikuje dokładne piksele oryginalnej tekstury, średnice jasnych i podstawowych poświat oraz 1500 gwiazd i 206 jasnych warstw. `Tests/SkyPointSourceContract556.py` sprawdza kompletne połączenie tekstury, RGBA, skali, kolejności, odpowiedzi shaderów i pipeline’u.

**Wynik:** [GitHub Actions 42065903420](https://github.com/synixad-png/asteroidy-ios/actions/runs/42065903420), `source-camera-linux` — **PASS**, w tym Swift/Linux i testy statyczne źródłowego kontraktu Metal. Oddzielny `Xcode Metal/Swift compile verification ONLY (NO IPA)` **w kolejce macOS** przy ostatnim sprawdzeniu. Żadne z tych potwierdzeń nie zastępuje wizualnego testu na fizycznym iPhonie. Poświaty gwiazd zostały odtworzone z rzeczywistej procedury, ale **nie** oznacza to jeszcze pełnego `IntroSky` (mgławice i promienie) ani zakończenia całego zadania 2. **Nie sprawdzano IPA.**

## Promienie słoneczne IntroSky z oryginalnego GpuCosmos39.cs — 05.11.2026

Bezpośrednie źródła `Asteroidy_v556_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`:
- `Windows/src/GpuIntro41.cs:25`: `SkyProject55` projektuje **sam kierunek nieba**, bez translacji oka (`px=640+viewX*720/depth`, `py=360-viewY*720/depth`, `depth=-viewZ`). Kierunek słońca w `IntroSky(rays)` to **`(0.6,0.8,0.32)*900`**, a zakres widzialności jego środka to **X od -400 do 1680, Y od -400 do 1120**.
- `GpuIntro41.cs:454`: przy włączonych `glow` i `rays` po projekcji rysowane są kolejno trzy teksturowane `IntroHalo`: promień **130 px** i RGBA `(170,255,199,127)`, następnie **55 px** z `(220,255,217,164)`, potem **15 px** z `(255,255,245,207)`. Następnie wykonywane jest **pięć wywołań `SoftRay`**, o kątach `2.5+(i-2)*.17`, długości **750** i szerokości **30**, kolorze `(18,255,202,139)`.
- `Windows/src/GpuCosmos39.cs:8–10`: każdy `SoftRay` to **4×6 komórek, 6 wierzchołków na komórkę** (144 wierzchołki/wachlarz). Wiersze odległości `[0,.12,.35,.72,1]`, siły `[0,1,.72,.31,0]`; dla każdej kolumny `side=col/3-1`, `spread=(3+rayDistance[row]*width)*side`, `fade=cos(side*pi/2)^2`. Wierzchołek ma `alpha=(int)(18*rayStrength[row]*fade)`, czyli kanał alfa jest **obcinany do całkowitej wartości**, a nie losowo wygładzany. `Gpu2DRenderer.cs` używa premultiplied alfa.
- `Windows/src/Renderer.cs:25,240`: w oryginalnej konfiguracji domyślnej `GlowEnabled=true`, `SolarRaysEnabled=true`. Dynamiczna opcja włączenia/wyłączenia z menu `Renderer` pozostaje do wprowadzenia wraz z systemem ustawień, **zadanie 14**.

Zaimplementowano:
- `Sphere67.swift`: `SphereSolarOverlay556` odwzorowuje projekcję słońca, pełną strukturę 738 wierzchołków `3*6 + 5*4*6*6`, oryginalny układ UV i alfa, a także zakres widoczności słońca.
- `MetalRenderer.swift`: jedna niezmienna siatka GPU, jedna współdzielona źródłowa `StarTexture` 64×64, dedykowany pipeline 2D z blendingiem `ONE/ONE_MINUS_SRC_ALPHA`, wspólnym stanem depth bez zapisu głębi i **jednym `drawPrimitives` dla słońca i promieni**. Co klatkę zmienia się wyłącznie 16-bajtowy uniform pozycji słońca i przeliczenia obrazu 720 px na aktualny `drawableSize`; nie powstają nowe bufory ani geometria.
- `Ship.metal`: `solarOverlayVertex/Fragment` odtwarzają ekranowe przesunięcia, premultiplied RGBA źródłowych wierzchołków i teksturowanie trzech `IntroHalo`. Promienie (bez tekstury) są interpolowane ze źródłowych kolorów wierzchołków, nie emulowane animacją lub procedurą wymyśloną dla portu.
- `Tests/SphereSolarOverlay556Tests.swift`: niezależne od implementacji stałe referencyjne wybranych wierzchołków dla 2.16/2.5/2.84 rad, kolejność trójkątów, 18 wierzchołków poświat, projekcja słońca na środek przy kamerze po przeciwnej stronie kuli i odrzucenie za kamerą. `Tests/SolarOverlaySourceContract556.py`: dodatkowo chroni w kodzie połączenie shaderów i macierzy ekranu, blending, jedną teksturę i kolejność przed planetą.
- [GitHub Actions 42068464591](https://github.com/synixad-png/asteroidy-ios/actions/runs/42068464591), `source-camera-linux`: **PASS** (oryginalna geometria 738 wierzchołków, kontrakt źródeł, dotychczasowe testy kamery/gwiazd oraz składni Swift). **Natywna kompilacja Apple Metal i całego iOS** w osobnym zadaniu `Xcode Metal/Swift compile verification ONLY` **nadal w kolejce przy ostatnim sprawdzeniu**. Nie jest to potwierdzenie interaktywnego renderingu na iPhonie.

**Zakres zamknięty:** oryginalne słońce i pięć `SoftRay` dla domyślnie włączonych promieni oraz oryginalne `StarTexture/IntroHalo` dla gwiazd. **Zakres nadal brakujący:** mgławice i `CloudLayer`, obiekty `DrawDeepSpace55` (planety i czarna dziura), opcje graficzne, pełna wierność wizualna i test Apple GPU. Nie zmieniano ani nie sprawdzano statusu IPA zgodnie z poleceniem użytkownika.

## Oryginalne mgławice v556 — NebulaTexture/CloudLayer, 36 warstw (05.11.2026)

**Dowód źródłowy:** plik `Asteroidy_v556_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`, odczytany bezpośrednio; oryginalne `Windows/src/GpuCosmos39.cs:3–7`, `Windows/src/GpuIntro41.cs:122,451`, `Windows/src/GpuSphere67.cs:420,456` i `Windows/src/Renderer.cs`.

**Zasady z kodu C#:**
- `CloudHash(x,y,seed)` używa niejawnego 32-bitowego przepełnienia w `x*374761393+y*668265263+seed*144269`, następnie miesza `(n^(n>>13))*1274126177` i `n^=n>>16`. `CloudNoise` interpoluje cztery wartości hasha wygładzonymi współrzędnymi `fx²(3-2fx)`, `fy²(3-2fy)`.
- `NebulaTexture(theme)` ma **256×256, Format32bppPArgb**, sześć palet RGB: `(167,67,212)`, `(36,139,199)`, `(209,68,108)`, `(90,87,212)`, `(35,162,144)`, `(188,118,44)`. Dla pojedynczego piksela: `warp=CloudNoise(nx*3,ny*3,theme+5)*2-1`; pięć oktaw `noise+=CloudNoise(nx*freq+warp*.8,ny*freq-warp*.5,theme*19+octave)*weight` z `freq=3`, `weight=.57`, przyrostem `freq*=2.05` i `weight*=.48`; `edge=pow(sin(nx*pi)*sin(ny*pi),.75)`; `ribbon=exp(-pow((ny-.48-sin(nx*5+theme)*.16-warp*.13)*3.1,2))`; `cloud=max(0,noise-.34)*3.5`; `alpha=min(190,(int)(edge*ribbon*cloud*220))`; kolor `base+hot*[95,110,85]`, `hot=max(0,noise-.58)*2`. Piksele BGRA są **premultiplikowane**, `B=(blue*alpha)/255`, analogicznie G/R, z dzieleniem całkowitym.
- `DrawDeepSpace55(nebula,...)`: **24 warstwy** w odstępach `i*pi/12`, kierunek `normalize(cos(a),sin(a)*.38,sin(a))*900`, tekstura `theme=i%2`, `alpha=37`, `size=min(650,720*190/depth)`, pozycja `(p.x-size,p.y-size*.24)`, wymiary `(2*size,.48*size)`, ograniczenia środka `(-500,1780)×(-400,1120)`.
- `IntroSky(nebula,...)`: dodatkowe **12 warstw** `i*pi/6` z kierunkiem `(cos(a)*380,sin(i*2.3)*90,sin(a)*380)`, tekstura `i%2`, `alpha=140`, `size=720*220/depth`, pozycja `(p.x-size,p.y-size*.55)`, wymiary `(2*size,1.1*size)`, zakres środka `(-900,2180)×(-600,1320)`.
- Dla trybu planety z `GpuSphere67.cs:420` obie grupy używają **wyłącznie dwóch palet 0 i 1**, mimo istnienia sześciu palet dla osobnego `LivingCosmos`. `Renderer.cs` ma domyślne `NebulaEnabled=true`. `SkyProject55` obraca kierunki przez macierz kamery, **bez translacji oka**.

**Implementacja:**
- `Sphere67.swift`: `SphereNebula556.hash/noise/pixel/textureBGRA` z zachowaniem arytmetyki 32-bit, 5 oktaw, skali i dwóch oryginalnych palet; struktura `Layer` udostępnia 24+12 kierunki, rozmiary, alfy i referencyjną projekcję `SkyProject55` niezależnie od Metal.
- `MetalRenderer.swift`: **dwie niezmienne tekstury 256×256** umieszczone w jednym `MTLTexture` `texture2DArray`; wszystkie 36 warstw wykorzystuje jedną niezmienną siatkę **216 wierzchołków**, jedno wywołanie `drawPrimitives(.triangle)`, jedną parę shaderów i tylko uniform kierunków kamery aktualizowany w trakcie lotu. Nie ma regeneracji tekstur ani siatki w każdej klatce.
- `Ship.metal`: `nebulaOverlayVertex` projektuje źródłowe kierunki i prostokąty przy użyciu `SkyProject55`, uwzględnia ograniczenia widoczności i perspektywę 720 px; `nebulaOverlayFragment` próbkuje wspólną dwuwarstwową teksturę liniowo, zachowując premultiplikowaną alfę i brak zapisu do bufora głębi. Kolejność renderowania: mgławice, gwiazdy, źródłowe poświaty słońca i pięć promieni, następnie geometria planety. Płaski tryb treningowy bez zmian.
- `Tests/SphereNebula556Tests.swift`: niezależne złote wartości `CloudHash` (również ujemne współrzędne), porównanie pikseli BGRA obu tekstur, generacja 2×256×256, 36 układów i projekcji na antypodach, test odrzucenia za kamerą. `Tests/NebulaSourceContract556.py`: sprawdza bezpośrednie okablowanie `MTLTexture` array, `BGRA8Unorm`, uniformów, dwóch shaderów, premultiplikowanej alfy, kolejności rysowania i braku duplikowania draw call.

**Weryfikacja:** [GitHub Actions 42071274522](https://github.com/synixad-png/asteroidy-ios/actions/runs/42071274522) — `source-camera-linux` **PASS**: matematyczne testy kamery/słońca/chmur, oryginalne 64×64 StarTexture/IntroHalo, statyczne kontrakty Metal i sprawdzenie składni Swift. **Kompilacja Apple Metal na macOS pozostawała w kolejce, a test wizualny na iPhonie nie został wykonany.** Są to dowody implementacji algorytmów i połączenia kodu, nie obrazu 1:1 na sprzęcie.

**Co pozostało:** odtworzenie trzech planet głębokiego kosmosu i czarnej dziury z `DrawDeepSpace55`, prawdziwy rendering GPU/iOS, późniejsze sterowanie `NebulaEnabled` z menu (zadanie 14). W obecnym widoku inne motywy `LivingCosmos` nie są portowane bez wyraźnego zakresu. Nie sprawdzano IPA.


## Czarna dziura z oryginalnego GpuIntro41.cs — trzy warstwy i poprawiona kolejność DrawDeepSpace55

**Źródło nadrzędne:** bezpośredni odczyt `Windows/src/GpuIntro41.cs:62–127` i `Windows/src/GpuRenderer.cs:Texture(Bitmap)` z rzeczywistego `Asteroidy_v556_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`. Nie wykorzystano tekstur z innych gier ani obrazów koncepcyjnych.

W kodzie C# czarna dziura **nie jest płaskim czarnym kołem**. `DrawSkyBlackHole55` tworzy (leniwie) trzy osobne obrazy **640×640**: `BuildBlackHoleDisk55(false)` — tylny dysk akrecyjny, `BuildBlackHoleCore55()` — ciemny środek i soczewkowanie, `BuildBlackHoleDisk55(true)` — przedni dysk przechodzący przed środkiem. Dysk wykorzystuje obrót **25°** (`ca=.9063078`, `sa=.4226183`), elipsę `u/214,v/54`, różne maski `Smooth239((v+9)/18)` dla przodu i tyłu oraz tylny prześwit `Smooth239((r-76)/10)`. Rdzeń ma próg `1-Smooth239((r-69)/4)` i dodatkowe pierścienie przy promieniach 80 i 86.

**Rzeczywiste wdrożenie:**
- `ASTEROIDYiOS/BlackHoleSky55.swift`: wierne przeniesienie parametrów i równań `BuildBlackHoleDisk55`, `BuildBlackHoleCore55`, `AnimatedSkyDirection55`, `SkyProject55` i `DrawSkyBlackHole55`. Generowane są trzy pełne obrazy PArgb/BGRA 640×640, premultiplikowane tak, jak robi to `GpuRenderer.Texture(Bitmap)`. Kierunek tła jest animowany wzorem z C#: baza `(-.46,-.70,-.55)`, `amplitudeX=.005`, `amplitudeY=.006`, `speed=.05`, `phase=2.4`.
- Oryginalne rysowanie ma **10 warstw** przy `GlowEnabled=true`: trzy źródłowe `IntroHalo` (promienie `258×2`, `258×1.54`, `258×1.10`; alfy 42, 62, 28), cztery animowane `DrawRay55` (kąt `time×.22`, pulsacja i odrębne barwy), następnie teksturowane warstwy **back → core → front**. Przy wyłączonym glow pozostaje 7 warstw (cztery promienie i trzy obrazy).
- `ASTEROIDYiOS/Ship.metal`: nowe `blackHoleVertex55/blackHoleFragment55` wykorzystują źródłowe rozmiary prostokątów, obroty promieni, 64-pikselową współdzieloną `StarTexture` dla halo oraz 3-warstwową teksturę 640×640 dla dysku i rdzenia. Kolory i mieszanie `ONE/ONE_MINUS_SRC_ALPHA` zachowują premultiplikację oryginalnego `Gpu2DRenderer`.
- `ASTEROIDYiOS/MetalRenderer.swift`: wspólna **jedna** trzywarstwowa tekstura GPU utworzona jednorazowo, źródłowa projekcja ekranu 1280×720 przeniesiona do rzeczywistej proporcji iPhone'a, tylko około 500 bajtów danych animacji na klatkę (10 warstw × 3 `float4` plus centrum), **jedno wywołanie rysowania na czarną dziurę**, bez odtwarzania 640-pikselowych tekstur w każdej klatce.
- Przy okazji naprawiono ważną rozbieżność **kolejności głębi**: oryginał rysuje **24 dalekie mgławice → planety i czarną dziurę → 12 bliskich chmur → gwiazdy → słońce**. Port wcześniej grupował wszystkie 36 chmur przed obiektami tła. Teraz używa tych samych tekstur i 216 wierzchołków w dwóch rysowaniach: 144 dla dalekich i 72 dla bliskich. **Trzech planet nadal jeszcze nie zaimplementowano**, więc pełnej kolejności z `DrawDeepSpace55` nie ogłaszamy jako zakończonej.
- Przy generowaniu tekstur zastosowano bezpieczne odrzucanie matematycznie przezroczystych pikseli: `r≥321` zeruje `feather`, przeciwległe połowy dysku mają zerową maskę, `r≤76` daje pusty tylny środek, a dla rdzenia `r≥120` alfa jest poniżej źródłowego progu `.001`. Nie zmienia to wzorów ani kolejności rysowania.

**Weryfikacja:** `Tests/BlackHoleSky55Tests.swift` sprawdza niezależne wartości RGBA/BGRA, wszystkie trzy całe tekstury 640×640, prześwit tylnego dysku, ciemny rdzeń, zakrywanie przednim dyskiem, projekcję widoku, ruch oraz 3+4+3 warstwy. `Tests/BlackHoleSourceContract556.py` sprawdza źródłowe przypisania GPU, potwierdzoną kolejność i wykorzystanie jednej trzywarstwowej tekstury. Poprzedni test `NebulaSourceContract556.py` poprawiono zgodnie z oryginalnym porządkiem dalekich i bliższych chmur. **[GitHub Actions 42074436010](https://github.com/synixad-png/asteroidy-ios/actions/runs/42074436010), `source-camera-linux`: PASS**, łącznie z poprzednimi regresjami `SphereCameraView556`, `SphereSolarOverlay556`, `SphereNebula556`, `StarTexture/IntroHalo`, statyczną kontrolą wszystkich nowych shaderów i sprawdzeniem składni Swift.

**Ograniczenia:** kontrolny `Xcode Metal/Swift compile verification ONLY (NO IPA)` dla nowego kodu **oczekiwał na runner macOS** podczas ostatniego sprawdzenia; natywna kompilacja Apple Metal, działanie shaderów na GPU, obraz na fizycznym iPhonie i interaktywna wydajność **nie są potwierdzone**. Oryginalne pierścienie i kolory dysku odtwarzane są matematycznie, lecz nie deklarujemy zgodności wizualnej 1:1 bez testu. Trzy źródłowe planety `BuildDeepPlanet55(style:0/1/2)` i konfiguracja `NebulaEnabled/GlowEnabled/SolarRaysEnabled` pozostają do zrobienia w odpowiednich etapach. Statusu IPA nie sprawdzano zgodnie z poleceniem użytkownika.

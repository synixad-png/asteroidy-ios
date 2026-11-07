# W3 — przezroczyste tło oryginalnego renderera planety NewHome290
Data: 07.11.2026

## Poświadczenie oryginalnych źródeł użytkownika
- `Windows/src/RendererW3Home328.cs`, SHA-256 `a696603703583df5e4363106389833d6fd9aaa59fd6b73fa5e1aec3f71f4a966`.
- `Windows/src/GpuW3HomeReal333.cs`, SHA-256 `839f1bd3ac42632d72208671ae336859144e0ef0564365dedb241d68e3d5a065`.
- GPU `RendererW3Home328.cs:255`: `if(c.IsGpu)c.Gpu.HomePlanetPreview333(435,176,455,455,...)`.
- Nie-GPU `RendererW3Home328.cs:256`: `else DrawHomePlanet333(c,662,402,188)`. Jedynie ta zastępcza gałąź wywołuje `DrawHomePlanetBackdrop333` (cztery pierścienie, siatka, elipsa). Wersja iOS jest **natywnym GPU**, więc nie wolno dołączać tych ozdobników do autentycznej sceny 3D.
- `GpuW3HomeReal333.cs:HomePlanetPreview333`: `Flush2D(); LogicalViewport333(...); clear(0x0100)` (GL_DEPTH_BUFFER_BIT); następnie `PrepareNewHome290`, źródłowa kamera ortho, `DrawNewHome290`; nie ma dodatkowego malowania tła.
- Zwykłe etykiety nawigacyjne poza planetarnym viewportem występują również w oryginale. Zgłoszona przejrzystość dotyczy tylko **samej przestrzeni GPU planety**, nie usuwania tła i nawigacji całego W3.

## Różnica i poprawka
- Przed naprawą `W3MainMenu568.radar` dodawał w natywnym podglądzie planety tło prostokątne, obwódki, 5 okręgów, 2 osie, dekoracyjną elipsę, napisy `RADAR / SYSTEM NAWIGACJI` i `ORYGINALNA PLANETA NEWHOME290 / 3D METAL`, wprost sprzeczne ze źródłem GPU.
- Po naprawie w tej metodzie renderowany jest **jeden** `W3HomePlanetMetal568(yaw:planetYaw,pitch:planetPitch)` z niezmienionymi interakcjami przeciągania i automatycznym obrotem.
- `W3HomePlanetMetal568.makeUIView`: `MTKView.isOpaque=false`, `view.layer.isOpaque=false`, transparentne tło UIView i CAMetalLayer, `clearColor=(0,0,0,0)`.
- W `draw(in:)` `pass.colorAttachments[0].loadAction=.clear`, `pass.colorAttachments[0].clearColor=(0,0,0,0)`, co daje odpowiednik transparentnego tła w *osobnej* nakładce Metal (nie można bezpośrednio współdzielić OpenGL backbuffer z oryginału Windows).
- Geometryczna siatka v568, 2 tekstury źródłowe, shader, parametry 3D, prędkość obrotu, sterowanie, struktura HOME W3, audio i CARBONIS niezmienione.
- Nie narysowano syntetycznej planety w razie braku wymaganych zasobów, aby nie pokazywać sztucznego zamiennika.

## Testy
- Nowy statyczny `Tests/V568W3PlanetTransparentSourceContract.py` jest blokadą regresji: sprawdza tylko autentyczną planetę 3D, brak nieoryginalnego radaru, alpha0, zachowane stare parametry obrotu i oryginalne wywołania renderera.
- Zaktualizowano `Tests/V568W3NativeMenuContract.py`, aby nie wymagał starych, nieoryginalnych napisów.
- Natywna kompilacja wszystkich źródeł Swift/Metal — SUCCESS w [GitHub Actions 42364176781](https://github.com/synixad-png/asteroidy-ios/actions/runs/42364176781); niezależny job publikowania poprzednich wyników wystąpił jako FAILURE i nie świadczy o błędzie kompilatora.
- Pełny build IPA w [GitHub Actions 42364176842](https://github.com/synixad-png/asteroidy-ios/actions/runs/42364176842) — osobny wynik release.
- Prawdziwy zrzut menu iPada i iPhone'a: [GitHub Actions 42364176785](https://github.com/synixad-png/asteroidy-ios/actions/runs/42364176785) — zrzuty wyłącznie z **tej** aplikacji, wynik do sprawdzenia.
- Automatyczne testy aktywnych przycisków W3: [GitHub Actions 42364176793](https://github.com/synixad-png/asteroidy-ios/actions/runs/42364176793). Na iPhonie nie znaleziono dostępnego symulatora (środowisko `simctl`, nie jest to dowód błędu w aplikacji).
- Nie badano obrazu na rzeczywistym iPhonie ani iPadzie. Brak deklaracji zgodności pixel-perfect ze źródłem.

## Harmonogram i następny krok
18 stałych zadań bez zmian. Wskaźnik portu 38% / 62% pozostało, zadanie 14 (Menu W3, HUD i ustawienia) 25% (+0 pp). Dalszym warunkiem potwierdzenia wyglądu jest wykonanie realnego zrzutu z działania iPada i iPhone'a lub test fizyczny.

# ASTEROIDY iOS — powiązanie planetarium z trzema wskaźnikami plazmy
Data: 2026-11-11

## Oryginalne źródło PC v602
Baza: `Asteroidy_v602_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`.
Sprawdzono: `Windows/src/HudGlbAssets.cs`, `HudCapsuleController.cs`, `HudMotion.cs`, `RendererW3Combat331.cs`, `RendererHudEnergy.cs`, `Shared/assets/hud/default-layout.json` oraz oryginalny `planetarium.glb`.

Model zawiera trzy kapsuły 3D:
- `DAMAGE_HULL_FILL_SOCKET`, pozycja (3.18,+1.28,0): kadłub.
- `DAMAGE_ARMOR_FILL_SOCKET`, pozycja (3.18,0,0): pancerz.
- `DAMAGE_SHIELD_FILL_SOCKET`, pozycja (3.18,-1.28,0): tarcza.

Każda kapsuła czyta z tych samych danych stanu statku co paski plazmy. W PC ich geometryczne pozycje i energia są dwiema osobnymi warstwami. Zatwierdzony layout celowo ma w podstawowej konfiguracji model przy lewym początku pasków: środek X kapsuł ok. 203.54, paski rozpoczynają się w okolicy X 202–205. Współrzędne Y kapsuł w modelu: ok. 582.54, 620.59, 658.64, natomiast środki pasków w zatwierdzonym JSON to odpowiednio shield ~582.22, armor ~618.93, hull ~658.90. **Uwaga:** kolejność pionowa pasków kadłub i tarcza jest odwrócona wobec nazewnictwa kapsuł w GLB; nie zmieniano zatwierdzonego JSON ani mapowania danych.

W klasycznym PC `HudMotionPose.Weight('hud.planetarium')=1.18`, a dla pasków `0.78`. Przy wspólnym ruchu HUD wartości te powodują niejednakową paralaksę. Użytkownik zażądał połączenia wizualnego zespołu, co jest świadomym odstępstwem od indywidualnej paralaksy PC.

## Wdrożenie iOS
- `ASTEROIDYiOS/HudPlanetariumPlasmaAnchor600.swift` — wspólne zakotwiczenie na trzech paskach w 1280x720, średnie przesunięcie ich pozycji od zatwierdzonego baseline, transformacja poprzez istniejący `HudMotionProject600` z tą samą wagą co paski. Bez modyfikowania zapisanych danych F6.
- `ASTEROIDYiOS/HudPlanetariumMetal600.swift` — źródłowa pozycja i skala zostają, tylko ekranowy pivot i przechył modelu korzystają z powiązanej grupy plazmy. Oryginalne 159 kanałów animacji pozostają niezależne.
- `ASTEROIDYiOS/Sector01CarbonisPreview568.swift` — przekazanie istniejącego live `snapshot.pose` do tego samego przebiegu Metal.
- `Tests/HudPlanetariumPlasmaAnchorTests.swift` — test domyślnych F6, zakotwiczenia, wspólnego przesunięcia, przechyłu/efektu ruchu, przesuwania samego planetarium, ukrywania pasków i ograniczenia pojedynczych edycji.
- Kontrakty testowe i workflow HUD/IPA rozszerzone o typecheck oraz wykonywalny test. Nie zmieniano edytora, wartości/plazmy, świata gry, czterech ikon ani oryginalnego GLB.

## Zakres i ograniczenia
Fizyczne łączenie jest sztywne: wspólne przesunięcie trzech pasków przechodzi na planetarium. Trzy niezależnie przemieszczane paski nie mogą jednocześnie zachować fizycznego połączenia ze sztywnym modelem 3D; wymagają odrębnej decyzji projektowej. Zatwierdzona kolejność pionowa kadłub/tarcza nie została arbitralnie zamieniona. Test fizycznego urządzenia iOS nadal jest konieczny; sam typecheck i Xcode nie udowadniają poprawnej kompozycji obrazu.

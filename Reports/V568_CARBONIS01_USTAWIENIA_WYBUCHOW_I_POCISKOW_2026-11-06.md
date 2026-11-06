## Kompilacja natywna Xcode — diagnoza i poprawka API Metal (06.11.2026)

[Run 42283783569](https://github.com/synixad-png/asteroidy-ios/actions/runs/42283783569) zakończył się **FAIL** podczas natywnej kompilacji `compile-device`, mimo PASS bramki Linux. Rzeczywisty log Xcode wskazał jedno konkretne miejsce: `CarbonisExplosion524Renderer.swift:66:34` — `missing argument for parameter 'slice' in call`. W [commicie 6d212ed](https://github.com/synixad-png/asteroidy-ios/commit/6d212ed987ac89c84c590a68fd793a3b39ba6a0b) uzupełniono wymagany `slice:0` przy `MTLTexture.replace(region:mipmapLevel:slice:withBytes:bytesPerRow:bytesPerImage:)` dla 64³ tekstury szumu. Nie zmieniono shadera, ustawień, kolizji ani mechaniki. Automatyczna ponowna weryfikacja **bez IPA**: [GitHub Actions 42285668117](https://github.com/synixad-png/asteroidy-ios/actions/runs/42285668117), wynik natywnej kompilacji i Apple GPU **do potwierdzenia**. Testy interakcji ustawień na symulatorach [42285229667](https://github.com/synixad-png/asteroidy-ios/actions/runs/42285229667) także nie są jeszcze zaliczone. **Postęp: 38% / 62% pozostało (+0 pp).**

---

# ASTEROIDY iOS v568 — WYBUCHY 3D i POCISKI (oryginalne ustawienia)

**Data audytu:** 6.11.2026. **Zakres:** CARBONIS 01, W3 menu i renderer natywny SwiftUI/Metal. **Źródło prawdy:** `Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`, nie przykładowy projekt ani podobne gry.

## Zweryfikowane elementy Windows v568

1. `Windows/src/Menu139.cs:10–33`: dwie niezależne zakładki W3 z dokładnymi nazwami `WYBUCHY 3D` (IDs 113–124) i `POCISKI` (IDs 42–44). Ustawienia renderowania, **nie** zmiana fizyki broni.
2. `Windows/src/Explosion524.cs:8–30`: 12 kontrolek i 3 presety PALIWO/ASTEROIDA/REAKTOR. Presety ośmiu wartości: PALIWO [100,13,135,100,130,125,50,260], ASTEROIDA [92,11,80,165,145,155,90,270], REAKTOR [130,15,160,110,175,150,75,350]. Dolne limity [45,5,0,0,10,40,0,150], górne [170,17,200,200,200,200,100,450], kroki [1,1,5,5,5,5,1,5]. Jakości GAMEPLAY/BALANCED/SHOWCASE: 22/32/48 próbki, 3/4/6 eksplozji. Obrót podglądu i nowy wybuch są rzeczywistymi elementami menu.
3. `Windows/src/Renderer.cs:26–27` i `Menu139.cs:332–359`: pociski mają **jasność oświetlenia 0–400% (domyślna 220%)**, osiem opcji kolorystycznych Automatyczny/Błękit/Złoty/Zielony/Fiolet/Karmazyn/Lodowy/Bursztynowy i przełącznik `Mieszane kolory oświetlenia`.
4. `Windows/src/Combat69.cs:44–116` i `ShotAppearance151.cs`: naturalne kolory Pulse (55,215,255), Twin (255,197,62), Scatter (255,92,190), strzały myśliwców rodzaju 0 (72,185,255), kind2 zielone, kind3 fioletowe. Każdy pocisk ma 6-segmentową geodezyjną smugę z 3 warstwami, radialny rdzeń w ekranowych pikselach, promień halo 2,3×, przeciwnicy mają błysk lufy przez 0,10 s. Nie są to płaskie prostokąty.
5. `Windows/src/GpuSphere67.cs:288–303,337–358`: cztery warstwy światła rzucanego na planetę, osobne promienie/moc dla typu pocisku, mieszanie koloru wybranego z naturalnym w proporcji 48% wybranego / 52% naturalnego; ustawienie automatyczne zachowuje naturalny kolor **światła**. Kolorowy strzał pozostaje naturalny niezależnie od nastawy światła.

## Zrealizowane w repozytorium iOS

- `CarbonisVisualSettings568.swift`: kompletna, trwała konfiguracja 15 użytkowych opcji (12 eksplozji + 3 pocisków), bez nieudokumentowanych zakresów i z zachowaniem oryginalnych presetów, limitów i kwantyzacji. Dane trzymane w iOS UserDefaults zamiast desktopowego `visual.txt/explosions524.txt`.
- `CarbonisVisualSettingsPanel568.swift`: prawdziwe obie zakładki w obecnym W3 ustawień, każdy suwak i przełącznik zapisuje stan; przycisk detonacji oraz obrót podglądu korzystają z `CarbonisExplosion524Preview568.swift` i autentycznego shadera Metal, a nie dekoracyjnej animacji.
- `CarbonisExplosion524Renderer.swift`, `CarbonisDestruction524.swift` oraz `CarbonisExplosion524Meshes.swift`: rozmiar, moc ognia/dymu, nieregularność, rozrzut, liczba kłębów, długość efektu, odłamki i jakość/budżet rzeczywiście kształtują emitowany efekt 3D; wydarzenia destrukcji i fizyka nie są modyfikowane przez suwaki.
- `CarbonisProjectileFX69.swift`: oryginalne trzy warstwy sześcioczęściowych geodezyjnych smug, radialne rdzenie i poświaty w rzeczywistych pikselach, cztery warstwy powierzchniowego światła planety i błysk ostrzału myśliwców.
- `CarbonisCombat568.swift`: `Projectile.Kind` w grze odpowiada rzeczywistemu typowi broni gracza Pulse0/Twin1/Scatter2 i `EnemyTactics71` typowi wrogiego strzału. Obrażenia, prędkości, rozmiary hitboxów i czas strzału bez zmian.
- `Sector01CarbonisPreview568.swift`: przełączono renderowanie zwykłych prostokątów na geodezyjny renderer Combat69, włączono czterowarstwowe ground lights, stały pixel-core i muzzle flash, a do eksplozji przekazywane są ustawienia. Wspólne zasoby GPU i geometrię planety zachowano.

## Testy

**[GitHub Actions 42283180401](https://github.com/synixad-png/asteroidy-ios/actions/runs/42283180401) — `verify-combat-no-ipa` SUCCESS.**
- **PASS 19** zgodności oryginalnych ustawień, presetów i trwałego zapisu.
- **PASS 17** geometrii pocisków, kolorów wrogich/przyjacielskich, 0–400% oświetlenia, 48% mieszania, trójwarstwowego rdzenia i błysku lufy.
- **PASS 45** wcześniej zaimplementowanych źródłowych efektów destrukcji.
- **PASS 18** całego CARBONIS 01, 335 kroków logicznej symulacji.
- Kolejne regresje wcześniejszych mechanizmów w przebiegu `verify-combat-no-ipa` również zakończyły się SUCCESS.

**[Natywny build iOS 42283783569](https://github.com/synixad-png/asteroidy-ios/actions/runs/42283783569)** został uruchomiony na commicie `40951aceed589e506a7564483d8badaa91cfa00b`; w chwili zapisu raportu weryfikacja Linux nadal trwała. Obecność IPA i status kompilacji SwiftUI/Metal trzeba potwierdzić osobno, bez zgadywania.

## Czego jeszcze nie potwierdzono

- Pełnej wizualnej zgodności klatka-po-klatce źródłowego OpenGL z iPhone Metal, w szczególności płynnego przejścia warstw alfy, podświetlenia rzeczywistego terenu C279 i wydajności przy wielu wrogach.
- Działania wszystkich suwaków/podglądu na rzeczywistym iPhonie i iPadzie oraz zapisu po fizycznym wyłączeniu aplikacji; automatyczne testy UserDefaults nie zastępują takich testów.
- Zgodności dźwięków pocisków i eksplozji — nie należą do tego etapu.

**Status portu 18 zadań: nadal 38% globalnie; 62% pozostało**, bez zwiększania procentu przed natywną weryfikacją GPU. Baza nadal CARBONIS 01, nie rozpoczynano sektorów 02–26.


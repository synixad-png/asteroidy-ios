# ASTEROIDY iOS — zweryfikowany punkt odniesienia i plan odchodzenia od prototypu

Data: 2026-11-05. Repozytorium iOS: `synixad-png/asteroidy-ios`.

## Źródło pierwowzoru, nie zgadywać

W Bibliotece użytkownika rzeczywiście odnaleziono i zweryfikowano archiwum `Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip` (150 473 406 B, 1 788 plików, SHA256 `271229a995c6e0a096ec401ba969c795a2fe4a4954462465ec1de2e1af5caaa7`). Jest to *późniejszy* wariant gry PC niż dotychczasowa referencja C# v556 portu iOS. Przenoszenie zachowania między v556 i v568 musi być oparte na jawnej weryfikacji różnic, a nie cichej zamianie baz.

Sprawdzone rzeczywiste pliki oryginału:
- `Windows/src/Game.cs`: `Mode` obejmuje `Menu, Playing, Paused, GameOver, Shop, Victory, Tunnel, Jump, Intro, Orbit, Hub90, StoryPrologue359`; `Mode=Mode.Menu` przy starcie (linie 26, 68); `Wave()` buduje obiekty i przeciwników (90–100), `Start()` czyści i ustawia pełną grę (104).
- `Windows/src/Program.cs`: okno tworzy oryginalny `Game` z `SceneTransitions=true, PlanetHub50=true, SphereCombat67=true` (19), a główna akcja z menu wywołuje `StartCampaign()` (np. 180).
- `Windows/src/RendererW3Home328.cs`: faktyczne siedem elementów HOME to `NOWA GRA`, `KONTYNUUJ`, `KAMPANIA`, `HANGAR`, `USTAWIENIA`, `AUTORZY`, `WYJŚCIE` (11–12); ekran ma układ paneli HOME, podgląd obracanej planety i statku (45–61, 219–289).
- `Windows/src/GpuIntro41.cs`: oryginalny pas intro opiera się na `OrbitWorld50.Belt51` i 820 modelach kamieni, z oryginalną geometrią i cullingiem (4–21); nie oznacza to, że 820 asteroid ma pojawić się w każdej misji.
- `Windows/src/Orbit50.cs`: `EnterOrbit50` i `LaunchOrbitMission50` sterują przejściem do misji (46, 53), nie jest to ekwiwalent samego `SphereSector556`.

## Stan porównywanego portu iOS

- `ASTEROIDYiOS/GameCore.swift` zawiera odseparowaną, płaską scenę treningową; domyślny licznik to 9 asteroid, nie oryginalny stan `Game.Mode.Menu`.
- `ASTEROIDYiOS/SphereSector556.swift` świadomie opisuje się jako izolowany *test sector*, bez całego kontrolera misji, pełnego AI, bossów czy odblokowań kampanii.
- `ASTEROIDYiOS/App.swift` dotąd otwierał płaską scenę. Od aktualizacji `46a7ded` defaultem jest istniejący renderer oryginalnego `Boreas556.as3d`; arena pozostaje dostępna diagnostycznie. **To poprawa punktu wejścia dla testów grafiki, nie port oryginalnego HOME ani prawdziwa misja 01.**
- `ASTEROIDYiOS/CampaignProgress556.swift` zawiera logikę maski odblokowań, ale atlas jest tylko do odczytu; nie wolno przyznawać za jego pomocą ukończeń misji diagnostycznych.

## Następna praca — bez zmiany stałej listy 18 zadań

**Bieżące zadanie 2 — Metal (nadal otwarte):**
1. Potwierdzić kompilację najnowszego `App.swift` i `MetalRenderer.swift` przez Xcode bez IPA; następnie zweryfikować render/culling/skalę z modeli i oryginalnego `GpuSphere67`. Nie przypisywać PASS z testów Swift/Linux do Apple GPU.
2. Związać rzeczywiste obiekty renderingu oraz parametry kamer, efektów i sekwencji ze źródłem v556; używać v568 tylko po sprawdzeniu zmian między wersjami.
3. Do porównań wizualnych używać wyłącznie autentycznych klatek aplikacji i rzeczywistej gry źródłowej. Nie prezentować zewnętrznych screenów jako wyniku portowania.

**Kiedy zadanie 2 zostanie domknięte:** kontynuować istniejące zadania 3–6 (PBR, zasoby GLB, animacje, fizyka); zachować testy i gotowe moduły 7–8. Dopiero po integracji zależności wdrażać zadania 9–14: pełne bronie, AI/bossów, prawdziwy kontroler misji i źródłowe HOME W3. Brakujące procedury muszą pochodzić z oryginalnego kodu, nie z diagnostycznego `GameCore`. Odrębne zadanie 18 obejmie testy na fizycznych iPhone/iPad.

## Konfiguracja obu urządzeń

`project.yml` już miało `TARGETED_DEVICE_FAMILY='1,2'`; jednorazowe IPA z run `42090319849` celowo wymuszało tylko iPhone. Dla następnego **wyraźnie zamówionego** IPA dodano `.github/workflows/build-ios-iphone-ipad-manual.yml`, `workflow_dispatch` only, `macos-15-intel`, `ARCHS=arm64`, `TARGETED_DEVICE_FAMILY=1,2`, weryfikacja `Tools/verify_ipa.py` sprawdza `UIDeviceFamily={1,2}`. Stare IPA nie zyskuje obsługi iPada wstecznie. Nowe IPA nie zostało wygenerowane.

**Status testów na dzień aktualizacji:** nowe testy kontraktu startowego i zasobów Swift/Linux zakończyły się PASS w run `42093245632`. Test Metal/Xcode w run `42093300828` oczekiwał na macOS; testu nowych zmian na prawdziwym telefonie/tablecie nie wykonano. Bez potwierdzenia nie podwyższać historycznych postępów zadania 1=88%, zadania 2=68%, całego portu=27%.

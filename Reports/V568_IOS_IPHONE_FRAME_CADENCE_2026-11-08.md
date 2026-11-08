# ASTEROIDY iOS — rozdzielenie 30 FPS od rzeczywistej kadencji MTKView

**Data:** 08.11.2026. **Wydanie:** unsigned IPA #144. **Baza:** iOS IPA #143 (oryginalne źródła ASTEROIDY Windows v568; poprzednie #141 audio i #142 iPhone-only GPU drawable pozostają).

## Dane z rzeczywistego iPhone'a przekazane przez użytkownika
- CPU **2,3 ms**, SYM **0,9 ms**, GPU **4,1 ms**, WAIT **0,3 ms** podczas diagnozowania spadków z **60 do 30 FPS w trakcie strzelania**.
- Wymagane okno 60 FPS to około **16,67 ms** na klatkę. Podane wartości to **średnie z różnych etapów**; nie wolno ich bezrefleksyjnie dodawać (CPU/GPU nakładają się), a krótkie skoki mogą być ukryte w średniej.
- Te wartości nie dowodzą przeciążenia GPU ani CPU. Hipoteza warta dalszej weryfikacji: rytm wywoływania renderera `MTKViewDelegate.draw(in:)` lub krótkie opóźnienia głównej pętli, **nie potwierdzona przyczyna**.

## Faktyczna implementacja
[PR #8](https://github.com/synixad-png/asteroidy-ios/pull/8), squash merge **`d3e04c4b1e7832d8314eee16a7eeebff50f82865`**:
1. Nowy czysto diagnostyczny `ASTEROIDYiOS/PhoneFrameCadence568.swift` oparty wyłącznie o Foundation. Mierzy odstępy czasowe między **rzeczywistymi** wywołaniami `draw(in:)` od MetalKit, z obliczeniem **DRAW callbacków na sekundę**, średniego `avg`, 95. percentyla `p95`, maksymalnego `max` oraz liczników odstępów >=24 ms i >=40 ms. Nie używa nowego CADisplayLink, nie zmienia liczby klatek, efektów ani celowej częstotliwości odświeżania. Po przerwie >=0,5 s zeruje histogram zamiast raportować opóźnienie wynikające np. z blokady ekranu.
2. `Sector01CarbonisPreview568.swift`: tylko w istniejącej gałęzi `adaptivePhoneCombat568 && gameSession != nil` na iPhonie wywołuje `SourcePerformance568.shared.recordPhoneDrawCallback(at:entered)` **przed** CPU FX, wait stream i CAMetalDrawable. Pozostała konstrukcja renderera na iPadzie, w tym oryginalna rozdzielczość i kolejność, jest nietknięta.
3. `SourcePerformance568.swift`: już istniejący użytkowy licznik FPS otrzymuje tylko na iPhonie dodatkową linię `DRAW .../s avg/p95/max ... ms >=24 / >=40`. Stary `FPS` liczy ukończone bufory GPU i nie jest zmieniony. Na iPadzie nie trafia żadna nowa próbka ani linia interfejsu. Brak nowych ustawień grafiki.
4. Testy regresji: `Tests/PhoneFrameCadence568Tests.swift` sprawdza 120/60/30 Hz, pojedyncze pominięcie klatki, przejście 60→30, blokadę/odblokowanie oraz nieprawidłowe sygnały; `Tests/IOSPhoneFrameCadence568Contract.py` sprawdza wyłącznie iPhone route, brak obniżenia jakości, iPad path, brak zmian w audio/FX. Oba testy uruchamiane przez PR CI oraz przed kompilacją IPA.

## Potwierdzone testy i plik
- [PR CI #431](https://github.com/synixad-png/asteroidy-ios/actions/runs/42461017308): **2/2 PASS**, Swift/Metal native compile oraz pełna regresja.
- [main CI #432](https://github.com/synixad-png/asteroidy-ios/actions/runs/42461276133): **3/3 PASS**.
- [IPA build #144](https://github.com/synixad-png/asteroidy-ios/actions/runs/42461276141): **4/4 PASS**; Xcode **BUILD SUCCEEDED**, test 43 oryginalnych SFX/voice i 15 runtime music tracks PASS, test dźwięków po iPad lock/unlock PASS, `unzip -t` bez błędów, `Tools/verify_ipa.py` PASS (ARM64 iOS 17+, iPhone + iPad, Payload, Info.plist, ZIP CRC).
- [Pobierz IPA #144](https://github.com/synixad-png/asteroidy-ios/actions/runs/42461276141/artifacts/13610600181): GitHub artifact `ASTEROIDY-iOS-device-unsigned-ipa`, zewnętrzny ZIP **28 044 097 bajtów**, SHA256 **`a83a937600a80b36fbf4c2771c252a1138c7370638c99a9810656c56e53ef18d`**, wewnątrz `ASTEROIDY_iOS_UNSIGNED.ipa`. Należy podpisać przy instalacji na fizycznym urządzeniu (np. Sideloadly).

## Weryfikacja użytkownika — nadal wymagana
Przy spadku FPS do 30 na iPhonie odczytać jednocześnie `FPS`, nowy `DRAW`, `avg / p95 / max`, `GPU`, `CPU`, `WAIT drawable / stream` oraz `FX CPU P/W`:
- Jeśli **FPS 30 i DRAW ~30/s** przy GPU ~4 ms: klatki są wywoływane około 30 razy/s. To sugeruje problem planowania wywołań renderera, klatkowania przez system lub main-thread stalls; **nie dowodzi jeszcze polityki iOS bez dalszych pomiarów**.
- Jeśli **FPS 30 i DRAW ~60/s**: renderer jest wywoływany częściej, lecz tylko część klatek dociera do końca GPU; następny audyt powinien skupić się na odrzucanych buforach drawable, obsłudze GPU command buffers i ukończeniu submit/present.
- Jeśli **DRAW ~60/s, ale max/p95 pokazują ~33+ ms**: obecność pojedynczych hitchów, których średnie czasy CPU/GPU nie wychwytują.
- Sprawdzić iPada w tej samej misji: obraz, audio, zachowane stabilne 60 FPS, brak dodatkowej linii DRAW.

**Nie przeprowadzono testu na fizycznym iPhonie lub iPadzie.** Samo CI nie jest dowodem poprawy FPS. Nie wprowadzono nowego ograniczenia rozdzielczości ani obniżenia jakości efektów. Harmonogram portu **18 zadań — 38% wykonane / 62% pozostało** bez sztucznego podnoszenia postępu za diagnostykę.

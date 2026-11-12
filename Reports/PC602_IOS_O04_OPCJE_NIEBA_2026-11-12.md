# O04 — oryginalny świat H290: opcje poświaty, mgławicy, promieni

Stały harmonogram: O04 „Oryginalny świat H290”. Źródła: oryginalny PC v602 Windows/src/Renderer.cs (SHA256 efe49abfc95e6b7090cf7ad07295d397dab9f3624551a1eba8b13e2ce1a39c87), Orbit50.cs (SHA256 8154038327fd78129cd8678bc482103f78bfa5e5c9756b344790cdba73aee5de), HomeFlight291.cs (SHA256 7c26c62fc8010064f419512e83ce7b61e94cff8764d92cf595675c39d02a61d5) i GpuIntro41.cs (SHA256 cdeecc6eedc96084e12d50d4062ba981feb404ade6b9d6b25ae333e43486c45e).

## Potwierdzona rozbieżność

Windows Renderer.cs:240,356–357: niezależne przełączniki „GLOW / POŚWIATA” (#2), „MGŁAWICA KOSMICZNA” (#12), „PROMIENIE SŁONECZNE” (#13), wszystkie domyślnie włączone. Orbit50.cs:139 przekazuje GlowEnabled, NebulaEnabled, SolarRaysEnabled do OrbitScene50. HomeFlight291.cs:106–123 wywołuje IntroSky(glow,nebula,rays,true) oraz uzależnia atmosferę od glow. Na iOS dotychczas przekazywano do oryginalnego nieba domyślne true i odczytywano glowEnabled tylko w inicjalizatorze renderera: wyłączenie opcji w czasie lotu nie działało wiernie.

## Wdrożone

- Dodano źródłowe pola nebulaEnabled i solarRaysEnabled do istniejącego SourcePlanetGraphicsSettings568 oraz przełączniki w istniejącej zakładce POSTPROCES, bez zmiany innych ekranów.
- Zachowano stare profile JSON przez dekodowanie zgodne wstecznie (brak nowych kluczy oznacza oba domyślnie włączone); dotychczasowe glowEnabled, planetLightEnabled, planetLightSpeed i planetNightBrightness pozostają bez zmian.
- Renderer H290 aktualizuje trzy wartości przy zmianie numeru rewizji zapisu ustawień (nie dekoduje JSON w każdej klatce), przekazuje trzy przełączniki do istniejącego SourceCombatSky568.draw i używa aktualnej poświaty do oryginalnej atmosfery i sygnału misji.
- Zachowano planetę, asteroidy, wrak, VANGUARDA, metalowe zasoby, shader nieba Carbonis01 i zatwierdzony HUD.

## Odbiór i ograniczenia

Wymagane: przejście statycznych testów, kompilacji ARM64 i testów migracji ustawień. Brak natywnego interaktywnego testu na iPhonie i porównania klatek PC↔Metal oznacza, że **O04 nie jest jeszcze formalnie odebrane**. O02/O03 nadal pozostają otwarte do końcowego odbioru, zgodnie z decyzją użytkownika o równoległej weryfikacji. Nie zmieniono zakresu O01–O12.

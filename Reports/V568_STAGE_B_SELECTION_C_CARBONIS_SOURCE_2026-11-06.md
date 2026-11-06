# ASTEROIDY iOS v568 — wykonane prace nad wyborem misji i planetą CARBONIS

**Data:** 06.11.2026. **Priorytet użytkownika:** rozwijać rzeczywistą grę, a nie
bez końca wracać do tych samych siedmiu przycisków menu.

## Etap B — wybór misji z oryginalnej kampanii

Zaimplementowano nowe zachowanie w rzeczywistym, natywnym SwiftUI:

- `W3MainMenu568.swift` przekazuje wybór misji z pozycji
  **NOWA GRA** i **KAMPANIA** do głównego stanu aplikacji.
- `App.swift` ma interaktywny atlas 26 sektorów zamiast
  nieklikalnej listy. Przyciski posiadają odrębne identyfikatory,
  podświetlenie aktualnie wybranego sektora i opis prawdziwej planety.
- `MissionCatalog568.swift` zawiera dokładnie 26 nazw
  planet z audytu oryginalnych źródeł ASTEROIDY v568.
- `CampaignProgress556.selectUnlocked` stosuje źródłowe
  `MissionUnlocked50` z `Windows/src/Orbit50.cs`; nie
  przyjmuje wyboru zablokowanej misji. Specjalny sektor 26
  jest dostępny po 24, zgodnie ze źródłami.
- `CampaignStore556` zapisuje `selectedSector` oddzielnie
  od `completedMask`. Sam wybór **nie** przyznaje ukończenia,
  nie wypłaca nagród i nie odblokowuje kolejnej planety.
- Dotychczasowa diagnostyka gry i mechanika walki pozostają
  rozdzielone od źródłowego wyboru kampanii.

[GitHub Actions 42220854317](https://github.com/synixad-png/asteroidy-ios/actions/runs/42220854317)
— **PASS**: samodzielne testy 26 nazw i reguł wyboru,
zapis/odczyt, zabezpieczenie sektora 26, regresje walki i natywna
kompilacja iOS.

**Zakres jeszcze otwarty:** pełna weryfikacja rzeczywistych
dotknięć na obu symulatorach, a przede wszystkim podłączenie
`LaunchOrbitMission50` / `StartHubMission261` do rzeczywistej
rozgrywki. Wybranie sektora nie uruchamia starej sceny testowej
ani nie udaje ukończenia misji.

## Etap C — CARBONIS / rzeczywista planeta pierwszej misji

Z oryginalnego `carbonis279.mesh.gz`, `Carbonis277.cs`
oraz trzech źródłowych tekstur wyprowadzono bez zmian
`137 067` unikatowych wierzchołków z **12 float/wierzchołek**,
`810 747` oryginalnych indeksów (**270 249 trójkątów**),
dwie oryginalne grupy materiałów oraz mapę kolizji **512×256**.
Nie wykorzystano wygenerowanej kuli ani podmienionego GLB.

W `Tools/prepare_v568_carbonis_sector01.py` zachowano
oryginalną indeksację zamiast rozwijać trójkąty do osobnego
strumienia. Bufory GPU:

| Reprezentacja | Rozmiar |
|---|---:|
| Oryginalne unikalne wierzchołki + indeksy | **9 822 204 B** |
| Nieużywany strumień rozwinięty | 38 915 856 B |

Obliczenia nie zmieniają położenia, UV, normalnych ani
topologii. Kontrolowane sumy SHA-256:

- oryginalny `carbonis279.mesh.gz`:
  `27dfc67667b1605b57cfd3146993fecc1c62bbcc38037237fbdd050db16f8d84`
- bufor oryginalnych wierzchołków:
  `b35318d059b9c4f180d03f36e52a6c4eea1225a484e339d3f117e5df9d7634bd`
- oryginalne indeksy:
  `e542a65a0ddf0767d982b573da037becea7872cc8a6e0d5d1e1851cd90730bef`
- oryginalna mapa wysokości:
  `3ce9a0456d23a5b88de718e7fd8fe6560cb53cd112a31ecc876e6200a762cb39`
- tekstury base/emission/irradiance mają oddzielne SHA-256 w
  skrypcie i zawsze muszą się zgadzać przed stagingiem.

Dodano `Sector01CarbonisPreview568.swift` oraz
`Sector01Carbonis568.metal` dla rzeczywistego, indeksowanego
podglądu GPU po wyborze sektora 01. Natywny build Xcode
staginguje oryginalne zasoby bez duplikatów rozwiniętej
siatki. Renderer korzysta z dwóch grup materiałów, źródłowych
map i UV; sposób oświetlenia podglądu **nie jest jeszcze**
pełną implementacją PBR Windows v568.

[GitHub Actions 42222217173](https://github.com/synixad-png/asteroidy-ios/actions/runs/42222217173)
— **PASS**: 270 249 trójkątów, oba materiały, dokładne
hashowanie wszystkich oryginalnych danych, niezależna
weryfikacja uszkodzenia pliku. [GitHub Actions
42223077726](https://github.com/synixad-png/asteroidy-ios/actions/runs/42223077726)
— job **native iOS Swift/Metal compile SUCCESS** po
poprawieniu wykrytego błędu składni nowego shadera.

**Nie twierdzimy, że misja 01 jest grywalna.** Trzeba
podłączyć prawdziwe uruchomienie z wyboru misji, statek i
kamerę, source Physics68, rzeczywiste kolizje terenowe,
asteroidy/strzelanie/wynik i ukończenie misji; przejść
testy na urządzeniach. Podgląd jest autentycznym modelem
planety, ale nadal tylko podglądem.

## Bezpieczeństwo regresji / wydania

Nie zmieniano zamrożonej obsługi obrażeń/kolizji,
asteroidów ani oryginalnych zasobów v568. Zweryfikowano
kompilację iOS i testy logiki kampanii; interaktywny test
podglądu Carbonis na fizycznym urządzeniu **nie był wykonany**.
Nie generowano nowego IPA. Wcześniejszy plik w prywatnym
Dysku Google użytkownika nie zawiera tych nowszych zmian.

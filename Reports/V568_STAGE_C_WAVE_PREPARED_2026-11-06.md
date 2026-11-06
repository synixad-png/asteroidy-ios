# ASTEROIDY iOS v568 — pierwsza fala CARBONIS

Data: 2026-11-06. Źródło: pełne Windows/SteamOS v568, SHA-256 ZIP: 271229a995c6e0a096ec401ba969c795a2fe4a4954462465ec1de2e1af5caaa7.

## Wdrożone
- MissionWave568.swift: inicjalna Game.Wave z Game.cs:90–101, Action38.cs:4–7, EnemyTactics71.cs:11–14,29–30, RobotSnake70.cs:8–13 i Balance70.cs:5–6.
- Prawdziwe parametry asteroid, rozkładu klas, HP, prędkości i startu z dala od statku; uzbrojone myśliwce oraz segmentowane roboty; generator losowy zgodny z zasianym C# Random.
- MissionIncoming568.swift: źródłowa procedura Action38.cs:7,9–10; zachowuje generator losowy po Wave, zegar sektorowy, maksymalnie 2 posiłki jednocześnie, powiadomienie 1,6 s, warunek zakończenia celu Clear i odrębne zachowania poziomów 9/17. Jest przygotowana w Sector01PreparedWave568, ale nie pracuje jeszcze w pętli gry.
- MissionStart261 i nowy Sector01PreparedWave568 tworzą wspólny snapshot przed przejściem z atlasu do autentycznej sceny C279; liczby obiektów są pobierane z wygenerowanych danych, a nie z atrapy.
- CARBONIS 01, normalny: 13 asteroid, 4 myśliwce, 0 robotów, 0 początkowych posiłków. Oryginalne CampaignLength wynosi 25 — 26. pozycja atlasu nie jest obsługiwana jako misja Game.Wave.

## Testy
- Swift/Linux na testowych odpowiednikach zależności: 909/909 kontroli generatora, **633/633 kontroli Action38 SpawnIncoming** oraz 12/12 kontroli bramki pierwszej misji — PASS. Łącznie 1554 lokalne asercje.
- Kontrola 12 kontraktów App, menu i sceny — PASS. Oryginalny ZIP: CRC PASS.
- Zmiany workflow GitHub Actions zawierają testy modułów na rzeczywistych źródłach repozytorium i kompilację Apple bez IPA. Końcowego wyniku tych testów i uruchomienia na fizycznym iOS jeszcze nie potwierdzono.
- Nie przeprowadzono natywnych testów C#; aktualne SpawnShooters71 i starszy Gameplay77Tests.cs rozbieżnie liczą 2 dodatkowe myśliwce.

## Pozostało
Pętla gry, ruch statku, widoczne myśliwce i asteroidy na CARBONIS, AI, SpawnIncoming w działającej grze, kolizje statku z C279, strzelanie, intro i rozstrzygnięcie misji. Snapshot początkowej fali NIE oznacza grywalnej walki ani ukończonego sektora.

Postęp szacunkowy: projekt 30% (+1 pp) / 70% pozostało; zadanie 12 10% (+2 pp). Pozostałe 17 pozycji bez zmian. Nie wygenerowano nowego IPA.

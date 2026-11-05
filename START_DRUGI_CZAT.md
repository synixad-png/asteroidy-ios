# Przekazanie do kompilacji — ASTEROIDY iOS v18

Źródła v18 znajdują się bezpośrednio w korzeniu repozytorium, wraz z oryginalnymi zasobami Vanguard i Boreas. Przesłano zawartość paczki ASTEROIDY_iOS_v18_GITHUB_HANDOFF.zip. Kod gry, testy, zasoby, project.yml, workflow i walidator IPA zachowano dokładnie z tej paczki. Zaktualizowano dokumentację; dodano wykaz sum kontrolnych przesłanych plików.

## Polecenie do wklejenia w drugim czacie

Wykonaj rzeczywistą kompilację ASTEROIDY iOS v18 ze źródeł w repozytorium https://github.com/synixad-png/asteroidy-ios, gałąź main. Użyj połączonego konta GitHub synixad-png. Nie modyfikuj iphone-ipa-test ani projektów Windows/SteamOS. Źródła są już wgrane: ASTEROIDYiOS, .github, Tools, Tests oraz project.yml. Nie zastępuj ich starszą wersją ani projektem demonstracyjnym. Po pobraniu repozytorium wykonaj `shasum -a 256 -c SOURCES_SHA256SUMS.txt`, aby sprawdzić zgodność kodu i zasobów z przekazaną paczką.

Sprawdź visibility=public przed uruchomieniem Actions. Workflow build-ios.yml uruchamia się WYŁĄCZNIE ręcznie przez workflow_dispatch; upload źródeł nie uruchamia buildu. Wybierz Run workflow na main. Używaj standardowego macos-15; nie kupuj usług ani płatnych runnerów. Job ma dodatkową blokadę przed uruchomieniem w prywatnym repozytorium.

Zbuduj iphoneos arm64 bez podpisywania. Przeanalizuj prawdziwe logi, napraw błędy i ponów build. Pobierz artefakt ASTEROIDY-iOS-device-unsigned-ipa, rozpakuj go i sprawdź IPA za pomocą Tools/verify_ipa.py. Zweryfikuj również podpisy (brak certyfikatu dystrybucyjnego jest celowy), zasoby, Info.plist i zależności. Jeśli limit przechowywania artefaktów zablokuje upload, zachowaj logi i udostępnij wynik przez GitHub Release w tym samym publicznym repozytorium, bez zakupów i bez zmieniania innych repozytoriów.

Przekaż rzeczywisty IPA, SHA-256, link do udanego runu, commit oraz raport wykonanych testów i ograniczeń. Nie twierdź, że aplikacja działa na iPhonie, jeśli wykonano tylko kompilację lub testy statyczne. Nie zastępuj v18 projektem demonstracyjnym.

## Stan tej paczki

- Przygotowano konfigurację do późniejszego ręcznego uruchomienia na GitHub.
- Źródła zostały przesłane do GitHub. Workflow nie został uruchomiony w etapie przygotowania.
- XcodeGen wygeneruje projekt Xcode z project.yml na macOS.
- Nie wykonano kompilacji Xcode, testów Swift/macOS, GPU ani testów na fizycznym urządzeniu.
- Walidator IPA dodano do przyszłego workflow; nie był uruchomiony na rzeczywistym IPA, ponieważ IPA jeszcze nie powstało.
- Historyczne raporty w paczce opisują wcześniejsze prace i nie stanowią dowodu nowego buildu.

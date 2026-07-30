# HelpDeskDrzewniak

Aplikacja do zgłaszania i zarządzania problemami IT w szkole.
Pracownicy zgłaszają usterki, administratorzy je przeglądają i przypisują status.

## Jak to działa

1. Użytkownik loguje się jako **user** lub **admin**.
2. **User** może dodać zgłoszenie (sala, opis, kategoria, priorytet) i przeglądać swoje zgłoszenia.
3. **Admin** widzi wszystkie zgłoszenia, może zmieniać ich status (untouched → in_progress → done), dodawać komentarze, zarządzać użytkownikami.
4. Backend to serwer Node.js na lokalnej sieci, który trzyma dane w SQLite.

Aplikacja działa na desktopie (Windows/Linux/macOS) i łączy się z backendem po HTTP.

## Wymagania

- [Flutter SDK](https://flutter.dev) (^3.5.4)
- [Node.js](https://nodejs.org) (v16+)
- menedżer pakietów npm

## Uruchomienie backendu

```bash
cd Serwerjs
npm install
node server.js
```

Serwer wystartuje na porcie **8080**.
Domyślnie baza danych (`users.db`) tworzy się automatycznie.

## Uruchomienie aplikacji Flutter

```bash
flutter pub get
flutter run
```

Aplikacja uruchomi się jako okno desktopowe.
W polu adresu backendu wpisz `http://<ip-serwera>:8080` (domyślnie localhost:8080).

## Budowa projektu

```
HelpDeskFlutter/
├── lib/                        # Kod źródłowy Flutter
│   ├── main.dart               # Wejście aplikacji
│   ├── login.dart              # Ekran logowania
│   ├── add_problem_page.dart   # Dodawanie zgłoszenia
│   ├── admin_home_page.dart    # Panel administratora
│   ├── problemtemp.dart        # Lista zgłoszeń
│   ├── settings.dart           # Ustawienia
│   ├── statystyki_admin.dart   # Statystyki admina
│   ├── statystyki_user.dart    # Statystyki użytkownika
│   ├── usertempp.dart          # Zarządzanie użytkownikami
│   ├── models/                 # Modele danych
│   └── pages/                  # Dodatkowe strony
├── Serwerjs/                   # Backend Node.js
│   ├── server.js               # Serwer Express + SQLite
│   ├── index.html              # Testowa strona WWW
│   └── package.json
├── assets/images/              # Obrazy
├── test/                       # Testy Flutter
├── android/                    # Konfiguracja Androida
├── ios/                        # Konfiguracja iOS
├── web/                        # Konfiguracja Web
├── windows/                    # Konfiguracja Windows
├── linux/                      # Konfiguracja Linux
├── macos/                      # Konfiguracja macOS
├── pubspec.yaml                # Zależności Flutter
└── README.md
```

## Technologie

| Część | Technologia |
|---|---|
| Frontend | Flutter / Dart |
| Backend | Node.js + Express |
| Baza danych | SQLite (better-sqlite3) |
| Hasła | bcrypt |
| Desktop | window_manager |

## Licencja

Custom License — patrz plik [LICENSE.md](./LICENSE.md).
Autor: Wiktor Dłużniewski.

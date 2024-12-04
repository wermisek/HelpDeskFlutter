// Ignorowanie niektórych ostrzeżeń, które mogą wystąpić przy korzystaniu z prywatnych typów w publicznych API
// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'login.dart'; // Importujemy stronę logowania

// Klasa ustawień - strona ustawień użytkownika
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

// Stan strony ustawień
class _SettingsPageState extends State<SettingsPage> {
  String accountName = 'John Doe'; // Przykładowa nazwa konta
  Map<int, bool> hoverStates = {}; // Mapa do śledzenia stanu najechania na przyciski

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ustawienia'),
        backgroundColor: Color(0xFFF5F5F5),
        foregroundColor: Colors.black, // Kolor tekstu na czarno w pasku
        elevation: 0, // Usuwamy cień z paska
      ),
      backgroundColor: Color(0xFFF5F5F5), // Ustawiamy tło strony na jasny kolor
      body: Column(
        children: [
          Divider(
            color: Color(0xFFF49402), // Kolor podziału
            thickness: 1, // Grubość linii
            height: 1, // Wysokość podziału
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 36.0, // Margines po bokach
                vertical: 36.0, // Margines od góry i dołu
              ),
              child: Column(
                children: [
                  // Pierwszy przycisk: Zmień hasło
                  _buildSettingsTile(
                    context,
                    index: 1, // Indeks przycisku
                    icon: Icons.lock, // Ikona kłódki
                    text: 'Zmień hasło', // Tekst na przycisku
                    onTap: () => _showPasswordChangeMessage(context), // Akcja po kliknięciu
                  ),
                  SizedBox(height: 16.0), // Odstęp między przyciskami
                  // Drugi przycisk: Licencja aplikacji
                  _buildSettingsTile(
                    context,
                    index: 2,
                    icon: Icons.gavel,
                    text: 'Licencja aplikacji',
                    onTap: () => _showAboutUsDialog(context),
                  ),
                  SizedBox(height: 16.0), // Odstęp między przyciskami
                  // Trzeci przycisk: Informacje o aplikacji
                  _buildSettingsTile(
                    context,
                    index: 3,
                    icon: Icons.apps,
                    text: 'Informacje o aplikacji',
                    onTap: () => _showAppInfoDialog(context),
                  ),
                  Spacer(), // Przycisk wylogowania pcha resztę na dół
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 310, // Szerokość przycisku
                        height: 60, // Wysokość przycisku
                        child: ElevatedButton(
                          onPressed: _logOut, // Akcja wylogowania
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, // Kolor tła przycisku
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30), // Zaokrąglone rogi
                            ),
                            foregroundColor: Colors.black, // Kolor tekstu na czarno
                            elevation: 2.0, // Subtelny cień
                          ),
                          child: Text(
                            'Wyloguj się',
                            style: TextStyle(
                              fontSize: 16, // Rozmiar czcionki
                              fontWeight: FontWeight.w600, // Grubość czcionki
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pomocnicza funkcja do budowania przycisków w ustawieniach
  Widget _buildSettingsTile(
      BuildContext context, {
        required int index, // Indeks przycisku
        required IconData icon, // Ikona przycisku
        required String text, // Tekst przycisku
        required Function() onTap, // Akcja po kliknięciu
      }) {
    return MouseRegion(
      onEnter: (_) => setState(() => hoverStates[index] = true), // Zmieniamy stan przy najechaniu
      onExit: (_) => setState(() => hoverStates[index] = false), // Zmieniamy stan przy wyjściu
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200), // Czas trwania animacji
        height: 60, // Wysokość przycisku
        decoration: BoxDecoration(
          color: hoverStates[index] == true
              ? Colors.grey[300] // Kolor przycisku po najechaniu
              : Colors.white, // Kolor normalny
          borderRadius: BorderRadius.circular(30), // Zaokrąglone rogi
          boxShadow: [
            BoxShadow(
              color: hoverStates[index] == true
                  ? Colors.black.withOpacity(0.2) // Cień po najechaniu
                  : Colors.black.withOpacity(0.1), // Normalny cień
              blurRadius: 8.0, // Rozmycie cienia
              offset: Offset(0, 2), // Pozycja cienia
              spreadRadius: 2.0, // Rozprzestrzenianie się cienia
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap, // Akcja po kliknięciu
          borderRadius: BorderRadius.circular(30), // Zaokrąglone rogi przycisku
          child: ListTile(
            leading: Icon(icon, color: Colors.black), // Ikona po lewej stronie
            title: Text(
              text, // Tekst przycisku
              style: TextStyle(fontSize: 18.0, color: Colors.black), // Styl tekstu
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0), // Padding wewnętrzny
            visualDensity: VisualDensity.standard, // Gęstość wizualna
          ),
        ),
      ),
    );
  }

  // Funkcja wyświetlająca okno zmiany hasła
  void _showPasswordChangeMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Tło okna
          title: Text(
            'Zmiana hasła',
            style: TextStyle(color: Colors.black), // Kolor tytułu
          ),
          content: SizedBox(
            width: 500, // Szerokość okna
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jeżeli chciałbyś zmienić hasło do swojego konta musisz wysłać zgłoszenie do administratora.',
                  style: TextStyle(color: Colors.black), // Tekst w oknie
                ),
                SizedBox(height: 16), // Odstęp między tekstami
                Text(
                  'Wyslij zgłoszenie i wpisz:\nSala: "Zmiana hasła"\nOpis: Login: "Twoj login", Nowe hasło: "Twoje nowe wymyslone haslo"',
                  style: TextStyle(color: Colors.black), // Kolejny tekst
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Zamknięcie okna
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // Kolor przycisku
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0), // Zaokrąglone rogi
                ),
              ),
              child: Text('OK'), // Tekst przycisku
            ),
          ],
        );
      },
    );
  }

  // Funkcja pokazująca licencję aplikacji
  void _showAboutUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Licencja aplikacji',
            style: TextStyle(color: Colors.black),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Text(
                '''
Umowa Licencyjna
================

Copyright (c) 2024 Wiktor Dłużniewski. Wszelkie prawa zastrzeżone.

Niniejsze oprogramowanie jest licencjonowane wyłącznie dla upoważnionych instytucji. Zabrania się nieautoryzowanego używania, modyfikowania lub dystrybuowania tej aplikacji.
                ''',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Zamknięcie okna
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Funkcja pokazująca informacje o aplikacji
  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Informacje o aplikacji',
            style: TextStyle(color: Colors.black),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Text(
                '''
Aplikacja do zarządzania ustawieniami konta.

Wersja: 1.0.0
Autor: Wiktor Dłużniewski

Wszelkie prawa zastrzeżone.
                ''',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Funkcja wylogowująca użytkownika
  void _logOut() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    ); // Przechodzimy do strony logowania
  }
}

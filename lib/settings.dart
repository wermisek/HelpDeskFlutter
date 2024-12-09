// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'login.dart'; // Importujemy stronę logowania
import 'ea.dart'; // Import the ea.dart file


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
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ustawienia'),
        backgroundColor: Color(0xFFF5F5F5),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Column(
            children: [
              Divider(
                color: Color(0xFFF49402),
                thickness: 1,
                height: 1,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36.0,
                    vertical: 36.0,
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        context,
                        index: 1,
                        icon: Icons.lock,
                        text: 'Zmień hasło',
                        onTap: () => _showPasswordChangeMessage(context),
                      ),
                      SizedBox(height: 16.0),
                      _buildSettingsTile(
                        context,
                        index: 2,
                        icon: Icons.gavel,
                        text: 'Licencja aplikacji',
                        onTap: () => _showAboutUsDialog(context),
                      ),
                      SizedBox(height: 16.0),
                      _buildSettingsTile(
                        context,
                        index: 3,
                        icon: Icons.apps,
                        text: 'Informacje o aplikacji',
                        onTap: () => _showAppInfoDialog(context),
                      ),
                      Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 310,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _logOut,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                foregroundColor: Colors.black,
                                elevation: 2.0,
                              ),
                              child: Text(
                                'Wyloguj się',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
          Positioned(
            bottom: 20,
            right: 20,
            child: MouseRegion(
              onEnter: (_) => setState(() => isHovered = true),
              onExit: (_) => setState(() => isHovered = false),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                height: isHovered ? 65 : 56,
                width: isHovered ? 65 : 56,
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                  boxShadow: isHovered
                      ? [BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TicTacToeApp()),
                      );
                    },
                    child: AnimatedOpacity(
                      duration: Duration(milliseconds: 200),
                      opacity: isHovered ? 1.0 : 0.0,
                      child: Icon(
                        Icons.pets, // Changed to cat-related icon
                        color: Colors.black,
                        size: 30,
                      ),
                    ),
                  ),
                ),
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
        required int index,
        required IconData icon,
        required String text,
        required Function() onTap,
      }) {
    return MouseRegion(
      onEnter: (_) => setState(() => hoverStates[index] = true),
      onExit: (_) => setState(() => hoverStates[index] = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: 60,
        decoration: BoxDecoration(
          color: hoverStates[index] == true
              ? Colors.grey[300]
              : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: hoverStates[index] == true
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 8.0,
              offset: Offset(0, 2),
              spreadRadius: 2.0,
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: ListTile(
            leading: Icon(icon, color: Colors.black),
            title: Text(
              text,
              style: TextStyle(fontSize: 18.0, color: Colors.black),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
            visualDensity: VisualDensity.standard,
          ),
        ),
      ),
    );
  }

  void _showPasswordChangeMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Zmiana hasła',
            style: TextStyle(color: Colors.black),
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jeżeli chciałbyś zmienić hasło do swojego konta musisz wysłać zgłoszenie do administratora.',
                  style: TextStyle(color: Colors.black),
                ),
                SizedBox(height: 16),
                Text(
                  'Wyslij zgłoszenie i wpisz:\nSala: "Zmiana hasła"\nOpis: Login: "Twoj login", Nowe hasło: "Twoje nowe wymyslone haslo"',
                  style: TextStyle(color: Colors.black),
                ),
              ],
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

  void _logOut() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}

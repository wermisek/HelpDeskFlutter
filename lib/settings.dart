// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login.dart';  // Correct import for login page
import 'dart:convert';
import 'package:http/http.dart' as http;


// Klasa ustawień - strona ustawień użytkownika
class SettingsPage extends StatefulWidget {
  final String username;  // Add username parameter
  
  const SettingsPage({
    super.key,
    required this.username,  // Make username required
  });

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

// Stan strony ustawień
class _SettingsPageState extends State<SettingsPage> {
  late String accountName; // Will be initialized with actual username
  Map<int, bool> hoverStates = {}; // Mapa do śledzenia stanu najechania na przyciski
  bool isHovered = false;

  @override
  void initState() {
    super.initState();
    accountName = widget.username; // Initialize with actual username
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ustawienia',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            color: Color(0xFFF49402),
            thickness: 1.0,
            height: 1.0,
          ),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Text(
                'Ustawienia konta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      index: 1,
                      icon: Icons.lock,
                      text: 'Zmień hasło',
                      onTap: () => _changePassword(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Pomoc',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      index: 2,
                      icon: Icons.help_outline,
                      text: 'Pomoc i dokumentacja',
                      onTap: () => _showHelpDialog(context),
                    ),
                    Divider(height: 1, thickness: 1),
                    _buildSettingsTile(
                      context,
                      index: 3,
                      icon: Icons.info_outline,
                      text: 'Informacje o aplikacji',
                      onTap: () => _showAppInfoDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hoverStates[index] == true
                        ? Color(0xFFF49402).withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: hoverStates[index] == true
                        ? Color(0xFFF49402)
                        : Colors.grey[600],
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: hoverStates[index] == true
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: hoverStates[index] == true
                          ? Color(0xFFF49402)
                          : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: hoverStates[index] == true
                      ? Color(0xFFF49402)
                      : Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Color(0xFFF49402), size: 24),
            SizedBox(width: 12),
            Text(
              'Zmień hasło',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Aktualne hasło',
                labelStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFFF49402), width: 2),
                ),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nowe hasło',
                labelStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFFF49402), width: 2),
                ),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[800],
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              'Anuluj',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentPassword = currentPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();

              if (currentPassword.isNotEmpty && newPassword.isNotEmpty) {
                try {
                  var response = await http.put(
                    Uri.parse('http://localhost:8080/change_password'),
                    body: json.encode({
                      'username': widget.username,
                      'currentPassword': currentPassword,
                      'newPassword': newPassword,
                    }),
                    headers: {
                      'Content-Type': 'application/json',
                    },
                  );

                  if (response.statusCode == 200) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hasło zostało zmienione pomyślnie'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Błąd: Nie udało się zmienić hasła (${response.statusCode})'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Błąd połączenia z serwerem: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF49402),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Zapisz',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionBuilder: (context, animation1, animation2, child) {
        return FadeTransition(
          opacity: animation1,
          child: ScaleTransition(
            scale: animation1,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              backgroundColor: Colors.white,
              title: Text(
                'Pomoc i dokumentacja',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 18.0,
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Zgłaszanie problemów:\n'
                        '   • Wybierz numer sali\n'
                        '   • Opisz szczegółowo problem\n'
                        '   • Kliknij "Wyślij zgłoszenie"\n\n'
                        '2. Zarządzanie kontem:\n'
                        '   • Zmiana hasła w ustawieniach\n'
                        '   • Wylogowanie z aplikacji',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.black),
                    ),
                  ),
                  child: Text('Zamknij'),
                ),
              ],
            ),
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 300),
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionBuilder: (context, animation1, animation2, child) {
        return FadeTransition(
          opacity: animation1,
          child: ScaleTransition(
            scale: animation1,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              backgroundColor: Colors.white,
              title: Text(
                'Informacje o aplikacji',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 18.0,
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HelpDesk Drzewniak',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Wersja: 1.0.0\n'
                        'Data wydania: Grudzień 2024\n\n'
                        'Aplikacja do zarządzania zgłoszeniami problemów technicznych '
                        'w salach lekcyjnych. System umożliwia szybkie raportowanie '
                        'usterek i efektywną komunikację między nauczycielami a '
                        'administratorami.\n\n'
                        'Autorzy:\n'
                        '• Wiktor Dłużniewski\n'
                        '\n'
                        'Technologie:\n'
                        '• Frontend: Flutter/Dart\n'
                        '• Backend: Node.js\n'
                        '• Baza danych: SQLite\n\n'
                        '© 2024 Zespół Szkół Technicznych w Słupsku\n'
                        'Wszelkie prawa zastrzeżone.',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.black),
                    ),
                  ),
                  child: Text('Zamknij'),
                ),
              ],
            ),
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 300),
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
    );
  }
}

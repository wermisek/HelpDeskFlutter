// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login.dart'; // Importujemy stronę logowania
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
                        icon: Icons.help_outline,
                        text: 'Pomoc i dokumentacja',
                        onTap: () => _showHelpDialog(context),
                      ),
                      SizedBox(height: 16.0),
                      _buildSettingsTile(
                        context,
                        index: 3,
                        icon: Icons.info_outline,
                        text: 'Informacje o aplikacji',
                        onTap: () => _showAppInfoDialog(context),
                      ),
                      Spacer(),
                      MouseRegion(
                        onEnter: (_) => setState(() => hoverStates[-1] = true),
                        onExit: (_) => setState(() => hoverStates[-1] = false),
                        child: TweenAnimationBuilder(
                          duration: Duration(milliseconds: 200),
                          tween: Tween<double>(
                            begin: 1.0,
                            end: hoverStates[-1] == true ? 1.05 : 1.0,
                          ),
                          builder: (context, double scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 310,
                                    height: 60,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        _logOut();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        foregroundColor: Colors.black,
                                        elevation: hoverStates[-1] == true ? 4.0 : 2.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          AnimatedSwitcher(
                                            duration: Duration(milliseconds: 200),
                                            child: Icon(
                                              Icons.logout,
                                              key: ValueKey<bool>(hoverStates[-1] == true),
                                              color: Colors.black,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Wyloguj się',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: hoverStates[-1] == true
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
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
            child: Container(), // Empty container instead of easter egg button
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
      child: TweenAnimationBuilder(
        duration: Duration(milliseconds: 200),
        tween: Tween<double>(
          begin: 1.0,
          end: hoverStates[index] == true ? 1.05 : 1.0,
        ),
        builder: (context, double scale, child) {
          return Transform.scale(
            scale: scale,
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
                    blurRadius: hoverStates[index] == true ? 12.0 : 8.0,
                    offset: Offset(0, hoverStates[index] == true ? 4 : 2),
                    spreadRadius: hoverStates[index] == true ? 3.0 : 2.0,
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  // Dodaj animację kliknięcia
                  HapticFeedback.lightImpact();
                  onTap();
                },
                borderRadius: BorderRadius.circular(30),
                child: ListTile(
                  leading: AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return RotationTransition(
                        turns: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      icon,
                      key: ValueKey<bool>(hoverStates[index] == true),
                      color: Colors.black,
                    ),
                  ),
                  title: Text(
                    text,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black,
                      fontWeight: hoverStates[index] == true
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                  visualDensity: VisualDensity.standard,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPasswordChangeMessage(BuildContext context) {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

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
                'Zmiana hasła',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 18.0,
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: true,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Obecne hasło',
                          labelStyle: TextStyle(color: Colors.black),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFF49402)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Wprowadź obecne hasło';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Nowe hasło',
                          labelStyle: TextStyle(color: Colors.black),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFF49402)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Wprowadź nowe hasło';
                          }
                          if (value.length < 6) {
                            return 'Hasło musi mieć minimum 6 znaków';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Potwierdź nowe hasło',
                          labelStyle: TextStyle(color: Colors.black),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFF49402)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Potwierdź nowe hasło';
                          }
                          if (value != newPasswordController.text) {
                            return 'Hasła nie są identyczne';
                          }
                          return null;
                        },
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
                  child: Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      try {
                        final response = await http.put(
                          Uri.parse('http://localhost:8080/change_password_for_user'),
                          headers: {'Content-Type': 'application/json'},
                          body: json.encode({
                            'username': accountName,
                            'oldPassword': currentPasswordController.text,
                            'newPassword': newPasswordController.text,
                          }),
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
                              content: Text('Błąd: ${json.decode(response.body)['message']}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Błąd połączenia z serwerem'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF49402),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Zmień hasło'),
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
                        '• Hubert Piechocki\n'
                        '• Przemysław Ćwil\n\n'
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

  void _logOut() {
    // Dodaj animację wylogowania
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionBuilder: (context, animation1, animation2, child) {
        return Transform.scale(
          scale: animation1.value,
          child: Opacity(
            opacity: animation1.value,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Container(
                height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF49402)),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Wylogowywanie...',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 300),
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black54,
    );

    // Symuluj opóźnienie wylogowania
    Future.delayed(Duration(milliseconds: 1500), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => LoginPage(),
          transitionDuration: Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = Offset(1.0, 0.0);
            var end = Offset.zero;
            var curve = Curves.easeInOutQuart;
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    });
  }
}

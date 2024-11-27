import 'package:flutter/material.dart';
import 'login.dart'; // Import the login page
import 'add_problem_page.dart'; // Import the page for submitting problems

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String accountName = 'John Doe'; // Mock account name
  Map<int, bool> hoverStates = {}; // To track hover state for each tile
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ustawienia'),
        backgroundColor: Color(0xFFF5F5F5),
        foregroundColor: Colors.black, // Black text color for AppBar
        elevation: 0, // Remove shadow
      ),
      backgroundColor: Color(0xFFF5F5F5), // Set background color to f5f5f5
      body: Column(
        children: [
          // Black divider below AppBar
          Divider(
            color: Color(0xFFF49402), // Black divider
            thickness: 1, // Divider thickness
            height: 1, // Ensures it does not take additional space
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 36.0),
              child: Column(
                children: [
                  // Change Password Tile
                  _buildSettingsTile(
                    context,
                    index: 1, // Tile index
                    icon: Icons.lock,
                    text: 'Zmień hasło',
                    onTap: () => _showPasswordChangeMessage(context),
                  ),
                  SizedBox(height: 16.0),
                  // About Us Tile
                  _buildSettingsTile(
                    context,
                    index: 2, // Tile index
                    icon: Icons.gavel,
                    text: 'Licencja aplikacji',
                    onTap: () => _showAboutUsDialog(context),
                  ),
                  SizedBox(height: 16.0),
                  // App Info Tile
                  _buildSettingsTile(
                    context,
                    index: 3, // Tile index
                    icon: Icons.apps,
                    text: 'Informacje o aplikacji',
                    onTap: () => _showAppInfoDialog(context),
                  ),
                  Spacer(), // Pushes the logout button to the bottom
                  // Logout Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center the button horizontally
                    children: [
                      SizedBox(
                        width: 310, // Set a fixed width for the button
                        height: 60, // Maintain the height
                        child: ElevatedButton(
                          onPressed: _logOut,
                          child: Text(
                            'Wyloguj się',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, // White background
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30), // Rounded corners
                            ),
                            foregroundColor: Colors.black, // Black text
                            elevation: 2.0, // Subtle shadow
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


  // Helper method to build tiles with hover effect for individual tiles
  Widget _buildSettingsTile(BuildContext context,
      {required int index,
        required IconData icon,
        required String text,
        required Function() onTap}) {
    return MouseRegion(
      onEnter: (_) => setState(() => hoverStates[index] = true), // Set hover state for this tile
      onExit: (_) => setState(() => hoverStates[index] = false), // Set hover state for this tile
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: 60, // Set the height of the tile to 60
        decoration: BoxDecoration(
          color: hoverStates[index] == true ? Colors.grey[300] : Colors.white, // Change color on hover
          borderRadius: BorderRadius.circular(30), // Rounded corners for tile
          boxShadow: [
            BoxShadow(
              color: hoverStates[index] == true
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 8.0,
              offset: Offset(0, 2),
              spreadRadius: 2.0, // Ensures the shadow has a rounded appearance
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30), // Rounded tap area
          child: ListTile(
            leading: Icon(icon, color: Colors.black),
            title: Text(
              text,
              style: TextStyle(fontSize: 18.0, color: Colors.black),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0), // Adjust padding
            visualDensity: VisualDensity.standard, // Ensures proper alignment
          ),
        ),
      ),
    );
  }

  // Dialog to show message about password change
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
          content: Container(
            width: 500, // Set a smaller width for the dialog
            child: Column(
              mainAxisSize: MainAxisSize.min, // Minimize height
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
              child: Text('OK'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // Text color
                backgroundColor: Colors.white, // Button background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0), // Rounded corners
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  // About Us Dialog
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
          content: Container(
            width: 500, // Set a smaller width for the dialog
            child: SingleChildScrollView(
              child: Text(
                '''
Umowa Licencyjna
================

Copyright (c) 2024 Wiktor Dłużniewski. Wszelkie prawa zastrzeżone.

Niniejsze oprogramowanie jest licencjonowane wyłącznie dla upoważnionych instytucji. Zabrania się nieautoryzowanego użycia, modyfikacji lub dystrybucji tego oprogramowania. Oprogramowanie jest przeznaczone wyłącznie do celów edukacyjnych w ramach określonej instytucji.

W przypadku zapytań dotyczących licencji, prosimy o kontakt z autorem projektu przez email lub jakikolwiek komunikator zawart na podanym nizej koncie github

Konto Github: https://github.com/wermisek
''',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // Text color
                backgroundColor: Colors.white, // Button background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0), // Rounded corners
                ),
              ),
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
          content: Container(
            width: 500, // Set a smaller width for the dialog
            child: SingleChildScrollView(
              child: Text(
                '''
Pełny kod aplikacji oraz wszystkie jej funkcje są dostępne w repozytorium GitHub. 
Możesz zapoznać się z dokumentacją, zgłaszać błędy lub proponować zmiany.

Wszystkie szczegóły i kod źródłowy są dostępne pod tym linkiem:

https://github.com/wermisek/HelpDeskFlutter
''',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // Text color
                backgroundColor: Colors.white, // Button background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0), // Rounded corners
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  // Log out functionality
  void _logOut() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wylogowano się pomyślnie')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to login page
    );
  }
}

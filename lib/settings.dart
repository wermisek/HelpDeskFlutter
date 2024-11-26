import 'package:flutter/material.dart';
import 'login.dart'; // Import the login page

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            // Change Password Tile
            _buildSettingsTile(
              context,
              index: 1, // Tile index
              icon: Icons.lock,
              text: 'Zmień hasło',
              onTap: () => _showChangePasswordDialog(context),
            ),
            SizedBox(height: 16.0),
            // About Us Tile
            _buildSettingsTile(
              context,
              index: 2, // Tile index
              icon: Icons.info,
              text: 'Informacje o nas',
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

  // Dialog to change the password
  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // White background for AlertDialog
          title: Text(
            'Zmień hasło',
            style: TextStyle(color: Colors.black),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Stare hasło'),
                ),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Nowe hasło'),
                ),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Potwierdź nowe hasło'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPasswordController.text == confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Zmieniono hasło!')),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hasła nie pasują!')),
                  );
                }
              },
              child: Text('Zapisz'),
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
          backgroundColor: Colors.white, // White background for AlertDialog
          title: Text(
            'Informacje o nas',
            style: TextStyle(color: Colors.black), // Set title text to black
          ),
          content: Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
            style: TextStyle(color: Colors.black), // Set content text to black
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // App Info Dialog
  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // White background for AlertDialog
          title: Text(
            'Informacje o aplikacji',
            style: TextStyle(color: Colors.black), // Set title text to black
          ),
          content: Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
            style: TextStyle(color: Colors.black), // Set content text to black
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
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

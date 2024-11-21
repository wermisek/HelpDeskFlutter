import 'package:flutter/material.dart';
import 'login.dart'; // Import the login page

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // This is a mock of the current account name
  String accountName = 'John Doe';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ustawienia'),
        backgroundColor: Color(0xFFF5F5F5),
      ),
      backgroundColor: Color(0xFFF5F5F5), // Set background color to f5f5f5
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.0),
            // Account Name Change Option
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Tile: Zmień nazwę konta
                Container(
                  width: 600, // Set the width of the tile
                  decoration: BoxDecoration(
                    color: Colors.black, // Set tile background color to black
                    borderRadius: BorderRadius.circular(30), // Add border radius
                  ),
                  child: ListTile(
                    leading: Icon(Icons.account_circle, color: Colors.grey[300]), // Icon color matches text color
                    title: Text(
                      'Zmień nazwe konta',
                      style: TextStyle(fontSize: 18.0, color: Colors.grey[300]), // Text color set to light gray
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[300]), // Arrow color matches text color
                    onTap: () {
                      _showChangeAccountNameDialog(context);
                    },
                  ),
                ),
                // Right Tile: Informacje o nas
                Container(
                  width: 600, // Set the width of the tile
                  decoration: BoxDecoration(
                    color: Colors.black, // Set tile background color to black
                    borderRadius: BorderRadius.circular(30), // Add border radius
                  ),
                  child: ListTile(
                    leading: Icon(Icons.info, color: Colors.grey[300]),
                    title: Text(
                      'Informacje o nas',
                      style: TextStyle(fontSize: 18.0, color: Colors.grey[300]),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[300]),
                    onTap: () {
                      _showAboutUsDialog(context);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0), // Space between tiles
            // Change Password Option
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Tile: Zmień hasło
                Container(
                  width: 600, // Set the width of the tile
                  decoration: BoxDecoration(
                    color: Colors.black, // Set tile background color to black
                    borderRadius: BorderRadius.circular(30), // Add border radius
                  ),
                  child: ListTile(
                    leading: Icon(Icons.lock, color: Colors.grey[300]),
                    title: Text(
                      'Zmień hasło',
                      style: TextStyle(fontSize: 18.0, color: Colors.grey[300]),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[300]),
                    onTap: () {
                      _showChangePasswordDialog(context);
                    },
                  ),
                ),
                // Right Tile: Informacje o aplikacji
                Container(
                  width: 600, // Set the width of the tile
                  decoration: BoxDecoration(
                    color: Colors.black, // Set tile background color to black
                    borderRadius: BorderRadius.circular(30), // Add border radius
                  ),
                  child: ListTile(
                    leading: Icon(Icons.apps, color: Colors.grey[300]),
                    title: Text(
                      'Informacje o aplikacji',
                      style: TextStyle(fontSize: 18.0, color: Colors.grey[300]),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[300]),
                    onTap: () {
                      _showAppInfoDialog(context);
                    },
                  ),
                ),
              ],
            ),
            Spacer(), // Pushes the Log Out button to the bottom
            // Log Out Button (with the same style as the login button)
            Align(
              alignment: Alignment.bottomCenter, // Center horizontally
              child: ElevatedButton(
                onPressed: _logOut,
                child: Text(
                  'Wyloguj się',
                  style: TextStyle(
                    fontSize: 18, // Increase font size for larger text
                    fontWeight: FontWeight.w600, // Optional: Make text bold
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Same color as login button
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40), // Increase padding for larger button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Rounded corners
                  ),
                  foregroundColor: Colors.white, // Text color set to white
                ),
              ),
            ),
            SizedBox(height: 16), // Optional, to add some space after the button
          ],
        ),
      ),
    );
  }

  // Dialog to change the account name
  void _showChangeAccountNameDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Zmień nazwę konta',
            style: TextStyle(color: Colors.black), // Title text color set to black
          ),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Nowa nazwa konta'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  accountName = nameController.text;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Zmieniono nazwę konta na $accountName')),
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF49402),
                foregroundColor: Colors.white, // Button background color set to f49402
              ),
              child: Text('Zapisz'),
            ),
          ],
        );
      },
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
          title: Text(
            'Zmień hasło',
            style: TextStyle(color: Colors.black), // Title text color set to black
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
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
                    SnackBar(content: Text('Hasło nie pasuje!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF49402),
                foregroundColor: Colors.white, // Button background color set to f49402
              ),
              child: Text('Zapisz'),
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
          title: Text(
            'Informacje o nas',
            style: TextStyle(color: Colors.black), // Set title text color to black
          ),
          content: Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
            style: TextStyle(color: Colors.black), // Set content text color to black
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFF49402), // Set button background color
                foregroundColor: Colors.white, // Set button text color to white
              ),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

// Show the "Informacje o aplikacji" dialog
  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Informacje o aplikacji',
            style: TextStyle(color: Colors.black), // Set title text color to black
          ),
          content: Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
            style: TextStyle(color: Colors.black), // Set content text color to black
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFF49402), // Set button background color
                foregroundColor: Colors.white, // Set button text color to white
              ),
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

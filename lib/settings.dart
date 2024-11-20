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
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.0),
            // Account Name Change Option
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text(
                'Change Account Name',
                style: TextStyle(fontSize: 18.0),
              ),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showChangeAccountNameDialog(context);
              },
            ),
            SizedBox(height: 16.0),
            // Change Password Option
            ListTile(
              leading: Icon(Icons.lock),
              title: Text(
                'Change Password',
                style: TextStyle(fontSize: 18.0),
              ),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showChangePasswordDialog(context);
              },
            ),
            Spacer(), // Pushes the Log Out button to the bottom
            // Log Out Button (with the same style as the login button)
            Align(
              alignment: Alignment.bottomCenter, // Center horizontally
              child: ElevatedButton(
                onPressed: _logOut,
                child: Text('Wyloguj się'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Same color as login button
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
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
          title: Text('Change Account Name'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'New Account Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  accountName = nameController.text;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Account name updated to $accountName')),
                );
                Navigator.of(context).pop();
              },
              child: Text('Update'),
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
          title: Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Old Password'),
                ),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'New Password'),
                ),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Confirm New Password'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPasswordController.text == confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password successfully changed!')),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Passwords do not match!')),
                  );
                }
              },
              child: Text('Change'),
            ),
          ],
        );
      },
    );
  }

  // Log out functionality
  void _logOut() {
    // Here, you would typically clear session data, tokens, etc.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wylogowano się pomyślnie')),
    );
    // Navigate to the login screen (for example)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),  // Navigate to login page
    );
  }
}

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false; // State variable for theme mode

  // Method to toggle theme
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode; // Toggle dark mode
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Disable the debug banner
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light, // Theme changes based on _isDarkMode
      darkTheme: ThemeData.dark(), // Dark theme settings
      theme: ThemeData.light(), // Light theme settings
      home: SettingsPage(
        isDarkMode: _isDarkMode, // Passing the current theme mode
        toggleTheme: _toggleTheme, // Passing the toggle function
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  SettingsPage({required this.isDarkMode, required this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        // Removed the settings button from the right side of the AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Mode Toggle Switch
            SwitchListTile(
              title: Text('Dark Mode'),
              value: isDarkMode, // Use the isDarkMode passed from the parent
              onChanged: (value) {
                toggleTheme(); // Toggle dark mode by calling toggleTheme
              },
            ),
            Divider(),
            Text('Change Password', style: Theme.of(context).textTheme.titleLarge),
            Form(
              key: GlobalKey<FormState>(),
              child: Column(
                children: [
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Enter new password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('Change Password'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

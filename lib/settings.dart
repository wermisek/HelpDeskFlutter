import 'package:flutter/material.dart';
import 'add_problem_page.dart'; // Import the add_problem_page.dart file

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;  // State variable for theme mode

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Disable the debug banner
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      darkTheme: ThemeData.dark(),
      theme: ThemeData.light(),
      home: SettingsPage(
        isDarkMode: _isDarkMode,
        toggleTheme: () {
          setState(() {
            _isDarkMode = !_isDarkMode;  // Toggle theme
          });
        },
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  SettingsPage({required this.isDarkMode, required this.toggleTheme});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  String _newPassword = '';

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _changePassword() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _newPassword = _passwordController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password Changed!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navigate to add_problem_page.dart when the button is pressed
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddProblemPage(username: 'Username'), // Provide the 'username'
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text('Dark Mode'),
              value: widget.isDarkMode,
              onChanged: (value) {
                widget.toggleTheme();
              },
            ),
            Divider(),
            Text('Change Password', style: Theme.of(context).textTheme.titleLarge),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _passwordController,
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
                    onPressed: _changePassword,
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

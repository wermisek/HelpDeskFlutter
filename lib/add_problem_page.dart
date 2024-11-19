import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'settings.dart';  // Import the settings page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // This line removes the debug banner
      home: UserHomePage(username: 'TestUser'), // Starting screen (replace with actual user login logic)
    );
  }
}

class UserHomePage extends StatelessWidget {
  final String username;

  UserHomePage({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zalogowano jako $username'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Witaj, $username!'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to AddProblemPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProblemPage(username: username),
                  ),
                );
              },
              child: Text('Dodaj Problem'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddProblemPage extends StatefulWidget {
  final String username;

  AddProblemPage({required this.username});

  @override
  _AddProblemPageState createState() => _AddProblemPageState();
}

class _AddProblemPageState extends State<AddProblemPage> {
  final _roomController = TextEditingController();
  final _problemController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showForm = false;  // To control whether to show the form or not

  // Function to send the problem to the local server
  Future<void> _submitProblem(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      String room = _roomController.text;
      String problem = _problemController.text;

      // Create the data to be sent to the server
      Map<String, dynamic> problemData = {
        'username': widget.username,
        'room': room,
        'problem': problem,
        'timestamp': DateTime.now().toString(),
      };

      try {
        // Sending data to the server
        var response = await HttpClient()
            .postUrl(Uri.parse('http://192.168.10.188:8080/add_problem')) // Zmieniono URL na IP komputera hosta
            .then((request) {
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(problemData));
          return request.close();
        });

        if (response.statusCode == 200) {
          // Show success message
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Problem wysłany'),
              content: Text('Dziękujemy, ${widget.username}. Twój problem został wysłany.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          throw Exception('Błąd połączenia z serwerem');
        }
      } catch (e) {
        // Handle connection errors
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Błąd'),
            content: Text('Nie udało się wysłać problemu. Spróbuj ponownie.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dodaj Problem'),
        actions: [
          // Restore settings button in the AppBar
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigate to SettingsPage (you can add settings functionality later)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    isDarkMode: false, // Placeholder, modify as necessary
                    toggleTheme: () {}, // Placeholder, modify as necessary
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showForm = !_showForm;
                  });
                },
                child: Text(_showForm ? 'Anuluj' : 'Dodaj Problem'),
              ),
              SizedBox(height: 20),
              if (_showForm)
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _roomController,
                        decoration: InputDecoration(
                          labelText: 'Numer Sali',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Proszę podać numer sali';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _problemController,
                        decoration: InputDecoration(
                          labelText: 'Opis Problemu',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Proszę podać opis problemu';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _submitProblem(context),
                        child: Text('Wyślij problem'),
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
}

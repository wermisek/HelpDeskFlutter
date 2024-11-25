import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'settings.dart'; // Keep the import for SettingsPage
import 'problemy.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UserHomePage(username: 'TestUser'),
    );
  }
}

class UserHomePage extends StatefulWidget {
  final String username;

  UserHomePage({required this.username});

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final _teacherController = TextEditingController(text: 'Nauczyciel X'); // Pre-filled teacher
  final _roomController = TextEditingController();
  final _problemController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool showUsers = false;
  bool showProblems = true;

  Future<void> _submitProblem(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      String room = _roomController.text;
      String problem = _problemController.text;

      // Add 'read' parameter with value 0 (unread)
      Map<String, dynamic> problemData = {
        'username': widget.username,
        'room': room,
        'problem': problem,
        'read': 0, // Status set to unread
      };

      try {
        final request = await HttpClient()
            .postUrl(Uri.parse('http://192.168.10.188:8080/add_problem'));

        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(problemData));

        final response = await request.close();

        if (response.statusCode == 201) {
          _showDialog(
            context,
            title: 'Problem wysłany',
            message: 'Dziękujemy, ${widget.username}. Twój problem został przesłany.',
          );
        } else {
          _showDialog(
            context,
            title: 'Błąd',
            message: 'Nie udało się wysłać problemu. Serwer zwrócił: ${response.reasonPhrase}',
          );
        }
      } catch (e) {
        _showDialog(
          context,
          title: 'Błąd połączenia',
          message: 'Nie udało się połączyć z serwerem. Sprawdź połączenie sieciowe.',
        );
      }
    }
  }

  void _showDialog(BuildContext context, {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(color: Colors.black),
        ),
        content: Text(message),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            offset: Offset(0, 2), // Shadow only at the bottom
            blurRadius: 4,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: labelText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none, // No border
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            offset: Offset(0, 2), // Shadow only at the bottom
            blurRadius: 4,
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          // Disable hover effect
          shadowColor: Colors.transparent, // Removes the hover effect
          elevation: 0, // Removes elevation
        ),
        onPressed: () => _submitProblem(context),
        child: Text('Zgłoś problem'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define height of the input fields for 'Nauczyciel' and 'Pokój'
    double problemFieldHeight = 80.0; // Height of 'Opis problemu' input
    double inputHeight = problemFieldHeight * 0.75; // 75% of 'Opis problemu' height

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'HelpDesk Strona Główna',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Divider to add line separating AppBar and the main screen
          Container(
            color: Color(0xFF8A8A8A),
            height: 1.0, // Line thickness
          ),
          Expanded(
            child: Container(
              color: Color(0xFFF5F5F5),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Row for 'Nauczyciel' and 'Pokój' side by side
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width * 0.45, // Adjust width to fit 75% of 'Opis problemu'
                              height: inputHeight,
                              child: _buildInputField(
                                controller: _teacherController,
                                labelText: 'Nauczyciel',
                                enabled: false,
                              ),
                            ),
                            SizedBox(width: 16), // Space between the two input fields
                            Container(
                              width: MediaQuery.of(context).size.width * 0.45,
                              height: inputHeight,
                              child: _buildInputField(
                                controller: _roomController,
                                labelText: 'Pokój',
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Wprowadź pokój';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        // Input for 'Opis problemu'
                        _buildInputField(
                          controller: _problemController,
                          labelText: 'Opis problemu',
                          maxLines: 5,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Wprowadź opis problemu';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24.0),
                        _buildSubmitButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              Container(
                height: 73.0,
                child: UserAccountsDrawerHeader(
                  accountName: Text(
                    'Helpdesk Admin',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  accountEmail: null,
                  currentAccountPicture: null,
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  margin: EdgeInsets.zero,
                ),
              ),
              ListTile(
                leading: Icon(Icons.report_problem, color: Colors.black),
                title: Text('Dodaj problem', style: TextStyle(color: Colors.black)),
                onTap: () {
                  setState(() {
                    showProblems = true;
                    showUsers = false;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.group, color: Colors.black),
                title: Text('Moje problemy', style: TextStyle(color: Colors.black)),
                onTap: () {
                  setState(() {
                    showProblems = false;
                    showUsers = true;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.settings, color: Colors.black),
                title: Text('Ustawienia', style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

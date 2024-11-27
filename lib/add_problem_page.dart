import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'settings.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

  const UserHomePage({super.key, required this.username});

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final _teacherController = TextEditingController(text: 'Wypełnione automatycznie');
  final _roomController = TextEditingController();
  final _problemController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _submitProblem(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      String room = _roomController.text;
      String problem = _problemController.text;

      Map<String, dynamic> problemData = {
        'username': widget.username,
        'room': room,
        'problem': problem,
        'read': 0,
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
    } else {
      setState(() {});
    }
  }

  void _showDialog(BuildContext context, {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: Colors.black)),
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
    bool isTeacherField = false, // Dodatkowy parametr, by ustawić szary tekst dla wypełnionego pola
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.black),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          hoverColor: Colors.transparent,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        style: TextStyle(
          color: isTeacherField && controller.text.isNotEmpty ? Colors.grey : Colors.black, // Szary tekst dla pola Nauczyciel
        ),
        validator: validator,
        onChanged: (text) {
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          Container(
            color: Color(0xFF8A8A8A),
            height: 1.0,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 120.0, right: 0.0, bottom: 20),
                                child: SizedBox(
                                  height: 90.0,
                                  child: _buildInputField(
                                    controller: _teacherController,
                                    labelText: 'Nauczyciel',
                                    enabled: false,
                                    isTeacherField: true, // Używamy nowego parametru
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 120.0, left: 30, bottom: 20),
                                child: SizedBox(
                                  height: 90.0,
                                  child: _buildInputField(
                                    controller: _roomController,
                                    labelText: 'Sala',
                                    maxLines: 2,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Wprowadź nazwę Sali';
                                      }
                                      return null;
                                    },
                                    maxLength: 15, // Limit znaków dla pola Sala
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        FractionallySizedBox(
                          widthFactor: 0.8,
                          child: SizedBox(
                            height: 160.0,
                            child: _buildInputField(
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
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        Padding(
                          padding: const EdgeInsets.only(top: 50.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 310,
                                height: 60,
                                child: ElevatedButton(
                                  onPressed: () => _submitProblem(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    foregroundColor: Colors.black,
                                    elevation: 2.0,
                                  ),
                                  child: Text(
                                    'Wyślij',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
              SizedBox(
                height: 80.0,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Helpdesk Drzewniak',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 19.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6.0),
                      Divider(
                        color: Colors.black,
                        thickness: 1.0,
                        indent: 0,
                        endIndent: 0,
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.report_problem, color: Colors.black),
                title: Text('Dodaj problem', style: TextStyle(color: Colors.black)),
                onTap: () {
                  setState(() {});
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.group, color: Colors.black),
                title: Text('Moje problemy', style: TextStyle(color: Colors.black)),
                onTap: () {
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_problem_page.dart';
import 'admin_home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strona Logowania',
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.white,
        buttonTheme: ButtonThemeData(buttonColor: Colors.black),
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _login(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      String username = _usernameController.text;
      String password = _passwordController.text;

      try {
        final response = await http.post(
          Uri.parse('http://192.168.10.188:8080/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'password': password,
          }),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> data = jsonDecode(response.body);
          String role = data['role'];

          if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminHomePage(),
              ),
            );
          } else if (role == 'user') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AddProblemPage(username: username),
              ),
            );
          } else {
            _showErrorDialog(context, 'Błąd logowania', 'Nieznana rola użytkownika.');
          }
        } else {
          _showErrorDialog(context, 'Błąd logowania', 'Niepoprawna nazwa użytkownika lub hasło.');
        }
      } catch (e) {
        _showErrorDialog(context, 'Błąd połączenia', 'Wystąpił problem z połączeniem z serwerem.');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logowanie do HelpDesk'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildTextField(
                  controller: _usernameController,
                  label: 'Nazwa użytkownika',
                  icon: Icons.person,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Hasło',
                  obscureText: true,
                  icon: Icons.lock,
                  onFieldSubmitted: (_) => _login(context),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _login(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Zaloguj się',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    required IconData icon,
    Function(String)? onFieldSubmitted,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 50),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.black),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          prefixIcon: Icon(icon, color: Colors.black),
        ),
        style: TextStyle(color: Colors.black),
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return 'Proszę podać $label';
          }
          return null;
        },
        onFieldSubmitted: onFieldSubmitted,
      ),
    );
  }
}

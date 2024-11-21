import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_problem_page.dart';
import 'admin_home_page.dart';
import 'settings.dart';  // Assuming SettingsPage is imported here.

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
  String? _usernameError;
  String? _passwordError;

  Future<void> _login(BuildContext context) async {
    // Resetujemy błędy przed rozpoczęciem walidacji
    setState(() {
      _usernameError = null;
      _passwordError = null;
    });

    // Jeśli dane są puste, nie wykonujemy logowania
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        if (_usernameController.text.isEmpty) {
          _usernameError = 'Proszę podać nazwę użytkownika';
        }
        if (_passwordController.text.isEmpty) {
          _passwordError = 'Proszę podać hasło';
        }
      });
      return;
    }

    // Dopiero teraz sprawdzamy login na serwerze
    try {
      final response = await http.post(
        Uri.parse('http://192.168.10.188:8080/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
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
              builder: (context) => AddProblemPage(username: _usernameController.text),
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

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(color: Colors.black),
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'OK',
              style: TextStyle(color: Colors.black),
            ),
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
        title: Text('HelpDesk Drzewniak'),
        backgroundColor: Color.fromRGBO(245, 245, 245, 1),
        elevation: 0,
        automaticallyImplyLeading: false, // Prevents the back button from showing
      ),
      body: Stack(
        children: [
          Container(
            color: Color.fromRGBO(245, 245, 245, 1),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/drzewniak.png',
                width: MediaQuery.of(context).size.width * 0.60,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
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
                      errorText: _usernameError,
                    ),
                    SizedBox(height: 20),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Hasło',
                      obscureText: true,
                      icon: Icons.lock,
                      onFieldSubmitted: (_) => _login(context),
                      errorText: _passwordError,
                    ),
                    SizedBox(height: 40),
                    _buildLoginButton(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    required IconData icon,
    String? errorText,
    Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 3,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: Offset(0, 0),
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
        ),
        if (errorText != null)
          Text(
            errorText,
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ElevatedButton(
        onPressed: () => _login(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
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
    );
  }
}

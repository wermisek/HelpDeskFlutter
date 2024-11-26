import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_problem_page.dart';
import 'admin_home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _usernameError;
  String? _passwordError;
  bool isLoading = false; // Zmienna do śledzenia stanu ładowania

  Future<void> _login(BuildContext context) async {
    setState(() {
      _usernameError = null;
      _passwordError = null;
      isLoading = true; // Rozpoczynamy ładowanie
    });

    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        if (_usernameController.text.isEmpty) {
          _usernameError = 'Proszę podać nazwę użytkownika';
        }
        if (_passwordController.text.isEmpty) {
          _passwordError = 'Proszę podać hasło';
        }
        isLoading = false; // Kończymy ładowanie w przypadku błędu
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.10.188:8080/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      setState(() {
        isLoading = false; // Kończymy ładowanie po zakończeniu żądania
      });

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        String role = data['role'];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

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
                builder: (context) =>
                    UserHomePage(username: _usernameController.text), // Przejście do nowej strony głównej użytkownikao
              ),
            );
          } else {
            _showErrorDialog(
              context,
              'Błąd logowania',
              'Nieznana rola użytkownika.',
            );
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          _showErrorDialog(
            context,
            'Błąd logowania',
            'Niepoprawna nazwa użytkownika lub hasło.',
          );
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false; // Kończymy ładowanie w przypadku błędu połączenia
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _showErrorDialog(
          context,
          'Błąd połączenia',
          'Wystąpił problem z połączeniem z serwerem.',
        );
      });
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: Colors.white,
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
        automaticallyImplyLeading: false,
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
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
                      isLoading
                          ? CircularProgressIndicator() // Animacja ładowania
                          : _buildLoginButton(context),
                    ],
                  ),
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
          width: 450, // Szerokość kontenera
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              // Zmniejszony cień
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1, // Mniejszy spread
                blurRadius: 4,   // Mniejszy blur
                offset: Offset(0, 2), // Mniejszy offset
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1, // Mniejszy spread
                blurRadius: 6,   // Mniejszy blur
                offset: Offset(0, 2), // Mniejszy offset
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
        SizedBox(height: 6), // Odstęp od pola tekstowego

        // Animowana wysokość kontenera dla błędu
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: errorText != null ? 20 : 0, // Jeśli błąd istnieje, kontener ma wysokość 20
          curve: Curves.easeInOut,
          child: errorText != null
              ? Text(
            errorText,
            style: TextStyle(color: Colors.red, fontSize: 12),
          )
              : SizedBox.shrink(), // Jeśli brak błędu, wyświetla pusty widget
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
          minimumSize: Size(200, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
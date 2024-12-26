import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_problem_page.dart';
import 'admin_home_page.dart';
import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelpDesk Login',
      theme: ThemeData(
        primaryColor: Color(0xFF2C3E50),
        scaffoldBackgroundColor: Colors.white,
        buttonTheme: ButtonThemeData(buttonColor: Color(0xFF2C3E50)),
        textTheme: GoogleFonts.poppinsTextTheme(),
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
  bool isLoading = false;
  bool _rememberMe = false; // Zmienna do zapamiętania opcji "Zapamiętaj mnie"

  @override
void initState() {
  super.initState();
  _loadCredentials().then((credentials) {
    if (credentials != null) {
      // Jeśli dane zostały załadowane z pliku, ustaw je w polach
      _usernameController.text = credentials['username']!;
      _passwordController.text = credentials['password']!;
    }
    // Jeśli credentials są null, pola pozostaną puste
  });
}


  Future<void> _login(BuildContext context) async {
  setState(() {
    _usernameError = null;
    _passwordError = null;
    isLoading = true;
  });

  if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
    setState(() {
      if (_usernameController.text.isEmpty) {
        _usernameError = 'Proszę podać nazwę użytkownika';
      }
      if (_passwordController.text.isEmpty) {
        _passwordError = 'Proszę podać hasło';
      }
      isLoading = false;
    });
    return;
  }

  try {
    final response = await http.post(
      Uri.parse('http://localhost:8080/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _usernameController.text,
        'password': _passwordController.text,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      String role = data['role'];

      // Jeśli "Zapamiętaj mnie" jest włączone, zapisz dane logowania
      if (_rememberMe) {
        _saveCredentials(_usernameController.text, _passwordController.text);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminHomePage(username: _usernameController.text),
            ),
          );
        } else if (role == 'user') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserHomePage(username: _usernameController.text),
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
      isLoading = false;
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

  Future<void> _saveCredentials(String username, String password) async {
  // Użycie bieżącego katalogu (obok pliku .exe)
  final directory = Directory.current; // Ścieżka do katalogu roboczego aplikacji
  final file = File('${directory.path}/credentials.json'); // Tworzenie pliku w bieżącym katalogu

  // Przygotowanie danych w formacie JSON
  Map<String, String> credentials = {
    'username': username,
    'password': password,
  };

  // Zapisanie danych w pliku JSON
  await file.writeAsString(jsonEncode(credentials));
}


Future<Map<String, String>?> _loadCredentials() async {
  try {
    final directory = Directory.current; // Katalog roboczy aplikacji
    final file = File('${directory.path}/credentials.json'); // Ścieżka do pliku

    // Jeśli plik istnieje, odczytaj dane
    if (await file.exists()) {
      final contents = await file.readAsString();
      Map<String, dynamic> credentials = jsonDecode(contents);

      // Jeśli plik zawiera dane
      if (credentials.containsKey('username') && credentials.containsKey('password')) {
        return {
          'username': credentials['username'],
          'password': credentials['password'],
        };
      }
    }
  } catch (e) {
    print('Error loading credentials: $e');
  }
  // Jeśli plik nie istnieje lub wystąpił błąd, zwróć null, aby pozostawić pola puste
  return null;
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
  final orangeAccent = Color(0xFFF49402); // Define orange accent color
  
  return Scaffold(
    body: Stack(
      children: [
        Container(
          color: Color(0xFFF5F5F5),
          width: double.infinity,
          height: double.infinity,
        ),
        Center(
          child: Image.asset(
            'assets/images/Background_image.JPEG',
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            fit: BoxFit.cover,
          ),
        ),
        Center(
          child: Card(
            elevation: 10,
            shadowColor: Colors.black12,
            color: Colors.white.withOpacity(0.75),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: orangeAccent.withOpacity(0.3), width: 1), // Subtle orange border
            ),
            child: Container(
              width: 600,
              padding: EdgeInsets.symmetric(
                horizontal: 50,
                vertical: 40,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'HelpDesk Drzewniak',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Zaloguj się do swojego konta',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: orangeAccent, // Orange subtitle
                      ),
                    ),
                    SizedBox(height: 40),
                    
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Nazwa użytkownika',
                      icon: Icons.person_outline,
                      errorText: _usernameError,
                      accentColor: orangeAccent,
                    ),
                    SizedBox(height: 15),
                    
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Hasło',
                      obscureText: true,
                      icon: Icons.lock_outline,
                      onFieldSubmitted: (_) => _login(context),
                      errorText: _passwordError,
                      accentColor: orangeAccent,
                    ),
                    SizedBox(height: 15),
                    
                    Row(
                      children: [
                        Transform.scale(
                          scale: 1.0,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (bool? value) {
                              setState(() {
                                _rememberMe = value!;
                              });
                            },
                            activeColor: orangeAccent, // Orange checkbox
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Text(
                          'Zapamiętaj mnie',
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 25),
                    
                    isLoading
                        ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(orangeAccent),
                          )
                        : _buildLoginButton(context, orangeAccent),
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
  required Color accentColor,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: errorText != null ? Colors.red.shade300 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.poppins(
              color: Colors.grey[700],
              fontSize: 13,
            ),
            prefixIcon: Icon(
              icon,
              color: accentColor,  // Orange icon
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.transparent,
            focusedBorder: OutlineInputBorder(  // Orange border on focus
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
          onFieldSubmitted: onFieldSubmitted,
        ),
      ),
      if (errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 12),
          child: Text(
            errorText,
            style: GoogleFonts.poppins(
              color: Colors.red.shade400,
              fontSize: 11,
            ),
          ),
        ),
    ],
  );
}

Widget _buildLoginButton(BuildContext context, Color accentColor) {
  return Container(
    width: double.infinity,
    height: 45,
    child: ElevatedButton(
      onPressed: () => _login(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,  // Orange button
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        'Zaloguj się',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    ),
  );
}
}


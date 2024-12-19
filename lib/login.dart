import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_problem_page.dart';
import 'admin_home_page.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';


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
              'assets/images/Background_image.JPEG',
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Zaloguj się',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 30), // Zmniejszony odstęp między napisem a polami

                    // Pierwsze pole tekstowe
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Nazwa użytkownika',
                      icon: Icons.person,
                      errorText: _usernameError,
                    ),
                    SizedBox(height: 20),

                    // Drugie pole tekstowe
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Hasło',
                      obscureText: true,
                      icon: Icons.lock,
                      onFieldSubmitted: (_) => _login(context),
                      errorText: _passwordError,
                    ),
                    SizedBox(height: 20),

                    // Wyrównanie checkboxa z innymi polami tekstowymi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start, // Wyrównanie na lewo
                      children: [
                        SizedBox(width: 75), // Przesunięcie checkboxa o 50 px w prawo
                        Transform.scale(
                          scale: 1.4, // Zwiększenie rozmiaru checkboxa
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (bool? value) {
                              setState(() {
                                _rememberMe = value!;
                              });
                            },
                            activeColor: Color(0xFFF49402), // Kolor zaznaczonego checkboxa
                          ),
                        ),
                        Text('Zapamiętaj mnie'),
                      ],
                    ),

                    // Przycisk logowania lub animacja ładowania
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


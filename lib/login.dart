import 'package:flutter/material.dart';
import 'add_problem_page.dart'; // Dodaj stronę, gdzie problemy są dodawane
import 'admin_home_page.dart'; // Dodaj stronę główną dla admina

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final bool isDarkMode = false; // Możesz przełączać tryb ciemny tutaj

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strona Logowania',
      theme: isDarkMode
          ? ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.black,
      )
          : ThemeData.light().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  final bool isDarkMode = false;

  LoginPage({Key? key}) : super(key: key);

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final String correctUsername = 'admin';
  final String correctPassword = 'hasło';

  void _login(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      String username = _usernameController.text;
      String password = _passwordController.text;

      if (username == correctUsername && password == correctPassword) {
        // Zamiast pokazywać tekst powitalny, przechodzimy bezpośrednio do AdminHomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminHomePage(),
          ),
        );
      } else if (username == 'user' && password == 'password') {
        // Login user, go to AddProblemPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AddProblemPage(username: username),
          ),
        );
      } else {
        // Invalid login, show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Błąd logowania'),
            content: Text('Niepoprawna nazwa użytkownika lub hasło.'),
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
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Nazwa użytkownika',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Proszę podać nazwę użytkownika';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Hasło',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Proszę podać hasło';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _login(context),
                  child: Text('Zaloguj się'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'add_problem_page.dart'; // Add the page where problems are added
import 'admin_home_page.dart'; // Add the page for admin home

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strona Logowania',
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.black,
      )
          : ThemeData.light().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: LoginPage(
        isDarkMode: _isDarkMode,
        toggleTheme: () {
          setState(() {
            _isDarkMode = !_isDarkMode;
          });
        },
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  LoginPage({required this.isDarkMode, required this.toggleTheme});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final String correctUsername = 'admin';
  final String correctPassword = 'hasło';

  late AnimationController _buttonController;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();

    _buttonController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _buttonAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeInOut,
      ),
    );

    _buttonController.forward();
  }

  void _login(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      String username = _usernameController.text;
      String password = _passwordController.text;

      if (username == correctUsername && password == correctPassword) {
        // Zamiast push, używamy pushReplacement, aby zastąpić stronę logowania
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminHomePage(username: username),
          ),
        );
      } else if (username == 'user' && password == 'password') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AddProblemPage(username: username),
          ),
        );
      } else {
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

//komentarz bo prosili
  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logowanie do HelpDesk'),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
              color: Colors.black,
            ),
            onPressed: widget.toggleTheme,
          ),
        ],
        backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedContainer(
                    duration: Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    height: 100,
                    child: Center(
                      child: Text(
                        'Witaj!!',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: widget.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Nazwa użytkownika',
                        labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                        filled: true,
                        fillColor: widget.isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Proszę podać nazwę użytkownika';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Hasło',
                        labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                        filled: true,
                        fillColor: widget.isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Proszę podać hasło';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 40),
                  ScaleTransition(
                    scale: _buttonAnimation,
                    child: ElevatedButton(
                      onPressed: () => _login(context),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          widget.isDarkMode ? Colors.black : Colors.blueAccent,
                        ),
                        padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      child: Text(
                        'Zaloguj się',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminHomePage extends StatelessWidget {
  final String username;

  AdminHomePage({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Home'),
      ),
      body: Center(
        child: Text('Welcome, $username!'), // Display the username for testing
      ),
    );
  }
}


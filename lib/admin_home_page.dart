import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'login.dart';
import 'settings.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelpDesk Admin',
      theme: ThemeData.light().copyWith(
        primaryColor: Color(0xFFF5F5F5),
        scaffoldBackgroundColor: Color(0xFFF6F6F8),
        buttonTheme: ButtonThemeData(buttonColor: Colors.white),
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      home: AdminHomePage(),
    );
  }
}

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  List<dynamic> problems = [];
  Timer? _refreshTimer;
  bool showUsers = false; // Zmienna przechowująca stan widoczności kontenera użytkowników

  Future<void> getProblems() async {
    try {
      var response =
      await HttpClient().getUrl(Uri.parse('http://192.168.10.188:8080/get_problems'));
      var data = await response.close();
      String content = await data.transform(utf8.decoder).join();
      setState(() {
        problems = jsonDecode(content);
      });
    } catch (e) {
      _showErrorDialog(context, 'Błąd połączenia', 'Nie udało się pobrać danych z serwera.');
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
  void initState() {
    super.initState();
    getProblems();
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      getProblems();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Widget _buildProblemList() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
        child: problems.isEmpty
            ? Center(
          child: Text(
            'Brak zgłoszeń.',
            style: TextStyle(fontSize: 16.0, color: Colors.black),
          ),
        )
            : GridView.builder(
          padding: EdgeInsets.symmetric(vertical: 3.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 1.9,
          ),
          itemCount: problems.length,
          itemBuilder: (context, index) {
            var problem = problems[index];
            return IntrinsicHeight(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(3, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sala: ${problem['room'] ?? 'Nieznana'}',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 19),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Nauczyciel: ${problem['username'] ?? 'Nieznany'}',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Treść: ${problem['problem'] ?? 'Brak opisu'}',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            _showPopup(context, problem);
                          },
                          child: Text(
                            'Rozwiń',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 15.0, horizontal: 20.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showPopup(BuildContext context, dynamic problem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFFF5F5F5),
        contentPadding: EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zgłoszenie od: ${problem['username'] ?? 'Nieznany'}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'Pokój: ${problem['room'] ?? 'Nieznany'}',
                style: TextStyle(fontSize: 17),
              ),
              SizedBox(height: 10),
              Text(
                'Opis problemu: ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 5),
              Text(
                problem['problem'] ?? 'Brak opisu',
                style: TextStyle(fontSize: 17),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Zamknij', style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Color(0xFFF5F5F5),
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
          ),
          title: Padding(
            padding: EdgeInsets.only(left: 25.0),
            child: Text(
              'Panel administratora',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: Color(0xFFF5F5F5),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildCustomButton('Zgłoszenia'),
                SizedBox(width: 30),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showUsers = !showUsers; // Toggle visibility
                    });
                  },
                  child: Text(
                    'Użytkownicy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                    elevation: 5,
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: showUsers, // Kontener użytkowników będzie widoczny, jeśli `showUsers` jest true
            child: Container(
              margin: EdgeInsets.all(10.0),
              color: Colors.grey[200],
              padding: EdgeInsets.all(10.0),
              child: Text('Kontener użytkowników'), // Możesz tutaj dodać więcej elementów
            ),
          ),
          _buildProblemList(),
        ],
      ),
    );
  }

  Widget _buildCustomButton(String text) {
    return ElevatedButton(
      onPressed: () {},
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
        elevation: 5,
      ),
    );
  }
}

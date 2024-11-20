import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'login.dart';  // Import strony logowania

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelpDesk Admin',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.black,
        buttonTheme: ButtonThemeData(buttonColor: Colors.white),
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.white)),
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
  List<dynamic> unreadProblems = [];
  List<dynamic> readProblems = [];
  Timer? _refreshTimer;
  ScrollController _unreadScrollController = ScrollController();
  ScrollController _readScrollController = ScrollController();

  Future<void> getProblems() async {
    try {
      var response =
      await HttpClient().getUrl(Uri.parse('http://192.168.10.188:8080/get_problems'));
      var data = await response.close();
      String content = await data.transform(utf8.decoder).join();
      List<dynamic> fetchedProblems = jsonDecode(content);

      setState(() {
        unreadProblems = fetchedProblems
            .where((p) => (p['read'] ?? false) == 0)  // Assuming 0 means unread
            .toList();
        readProblems = fetchedProblems
            .where((p) => (p['read'] ?? false) == 1)  // Assuming 1 means read
            .toList();
      });
    } catch (e) {
      _showErrorDialog(context, 'Błąd połączenia', 'Nie udało się pobrać danych z serwera.');
    }
  }

  Future<void> deleteProblem(int id) async {
    try {
      var request = await HttpClient()
          .deleteUrl(Uri.parse('http://192.168.10.188:8080/delete_problem/$id'));
      await request.close();
      setState(() {
        unreadProblems.removeWhere((problem) => problem['id'] == id);
        readProblems.removeWhere((problem) => problem['id'] == id);
      });
    } catch (e) {
      _showErrorDialog(context, 'Błąd', 'Nie udało się usunąć problemu.');
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      var request = await HttpClient()
          .putUrl(Uri.parse('http://192.168.10.188:8080/mark_as_read/$id'));
      await request.close();
      getProblems();
    } catch (e) {
      _showErrorDialog(context, 'Błąd', 'Nie udało się oznaczyć zgłoszenia jako odczytane.');
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

  void _logout() {
    // Tutaj należy dodać logikę wylogowania, np. usuwając dane logowania z pamięci.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),  // Przenosimy użytkownika na stronę logowania
    );
  }

  @override
  void initState() {
    super.initState();
    getProblems();
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      getProblems();  // Fetch problems every 5 seconds
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _unreadScrollController.dispose();
    _readScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Home',
          style: TextStyle(color: Colors.black),  // Text color black
        ),
        backgroundColor: Colors.white,  // AppBar background white
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),  // Refresh icon color black
            onPressed: getProblems,
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.black),  // Wyloguj ikona
            onPressed: _logout,  // Wywołanie funkcji wylogowania
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nieodczytane zgłoszenia',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),  // Text color black
                  ),
                  Expanded(
                    child: unreadProblems.isEmpty
                        ? Center(
                      child: Text(
                        'Brak nieodczytanych zgłoszeń.',
                        style: TextStyle(fontSize: 16.0, color: Colors.black),  // Text color black
                      ),
                    )
                        : ListView.builder(
                      controller: _unreadScrollController,
                      physics: BouncingScrollPhysics(), // For smoother scrolling
                      itemCount: unreadProblems.length,
                      itemBuilder: (context, index) {
                        var problem = unreadProblems[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          color: Colors.grey[800],
                          child: ListTile(
                            title: Text(
                              'Username: ${problem['username'] ?? 'Nieznany'}',
                              style: TextStyle(color: Colors.white),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Room: ${problem['room'] ?? 'Nieznany'}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  'Problem: ${problem['problem'] ?? 'Brak opisu'}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  'Timestamp: ${problem['timestamp'] ?? 'Nieznany'}',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deleteProblem(problem['id']),
                                ),
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed: () => markAsRead(problem['id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Odczytane zgłoszenia',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),  // Text color black
                  ),
                  Expanded(
                    child: readProblems.isEmpty
                        ? Center(
                      child: Text(
                        'Brak odczytanych zgłoszeń.',
                        style: TextStyle(fontSize: 16.0, color: Colors.black),  // Text color black
                      ),
                    )
                        : ListView.builder(
                      controller: _readScrollController,
                      physics: BouncingScrollPhysics(), // For smoother scrolling
                      itemCount: readProblems.length,
                      itemBuilder: (context, index) {
                        var problem = readProblems[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          color: Colors.grey[800],
                          child: ListTile(
                            title: Text(
                              'Username: ${problem['username'] ?? 'Nieznany'}',
                              style: TextStyle(color: Colors.white),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Room: ${problem['room'] ?? 'Nieznany'}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  'Problem: ${problem['problem'] ?? 'Brak opisu'}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  'Timestamp: ${problem['timestamp'] ?? 'Nieznany'}',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteProblem(problem['id']),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

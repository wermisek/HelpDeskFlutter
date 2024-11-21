import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'login.dart'; // Import strony logowania
import 'settings.dart'; // Import your settings page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelpDesk Admin',
      theme: ThemeData.light().copyWith(
        primaryColor: Color(0xFFF5F5F5), // Set the primary color to #f5f5f5
        scaffoldBackgroundColor: Color(0xFFF5F5F5), // Set the scaffold background color to #f5f5f5
        buttonTheme: ButtonThemeData(buttonColor: Colors.white),
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.black)), // Set text color to black
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

  Future<void> getProblems() async {
    try {
      var response =
      await HttpClient().getUrl(Uri.parse('http://192.168.10.188:8080/get_problems'));
      var data = await response.close();
      String content = await data.transform(utf8.decoder).join();
      List<dynamic> fetchedProblems = jsonDecode(content);

      setState(() {
        unreadProblems = fetchedProblems
            .where((p) => (p['read'] ?? false) == 0) // Assuming 0 means unread
            .toList();
        readProblems = fetchedProblems
            .where((p) => (p['read'] ?? false) == 1) // Assuming 1 means read
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Przenosimy użytkownika na stronę logowania
    );
  }

  void _showPopup(BuildContext context, dynamic problem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFFF5F5F5), // Jaśniejszy kolor tła popupu
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
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              Text(
                'Opis problemu:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 5),
              Text(
                problem['problem'] ?? 'Brak opisu',
                style: TextStyle(fontSize: 14),
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
  void initState() {
    super.initState();
    getProblems();
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      getProblems(); // Fetch problems every 5 seconds
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Widget _buildProblemGrid(String title, List<dynamic> problems, bool isUnread) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0), // Zwiększenie zewnętrznego marginesu
        padding: EdgeInsets.only(left: 5.0, right: 5.0, top: 8.0, bottom: 8.0), // Padding wewnętrzny
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5), // Background color changed to #f5f5f5
          border: Border.all(color: Colors.black, width: 3), // Szerszy border
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Expanded(
              child: problems.isEmpty
                  ? Center(
                child: Text(
                  isUnread
                      ? 'Brak nieodczytanych zgłoszeń.'
                      : 'Brak odczytanych zgłoszeń.',
                  style: TextStyle(fontSize: 14.0, color: Colors.black),
                ),
              )
                  : GridView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // Four tiles per row
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 1.8, // Adjust aspect ratio for compact tiles
                ),
                itemCount: problems.length,
                itemBuilder: (context, index) {
                  var problem = problems[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.black, // Tło bardzo ciemne, prawie czarne
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Username: ${problem['username'] ?? 'Nieznany'}',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14), // Decreased font size
                              ),
                              IconButton(
                                icon: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white),
                                onPressed: () {
                                  _showPopup(context, problem); // Show full problem in popup
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Room: ${problem['room'] ?? 'Nieznany'}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14), // Decreased font size
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Problem: ${problem['problem'] ?? 'Brak opisu'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  deleteProblem(problem['id']);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.check, color: Colors.green),
                                onPressed: () {
                                  markAsRead(problem['id']);
                                },
                              ),
                            ],
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            height: 60,
            color: Color(0xFFF5F5F5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Panel administratora',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
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
          _buildProblemGrid('Nieodczytane Zgłoszenia', unreadProblems, true),
          _buildProblemGrid('Odczytane Zgłoszenia', readProblems, false),
        ],
      ),
    );
  }
}

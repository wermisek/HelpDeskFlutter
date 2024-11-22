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
        primaryColor: Color(0xFFFFFFFF),
        scaffoldBackgroundColor: Color(0xFFFFFFFF),
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
  bool showUsers = false;
  bool showProblems = true;
  PageController _pageController = PageController();
  int currentPage = 0;
  final int itemsPerPage = 12;
  String currentUser = "Jan Kowalski";  // Przykładowa nazwa użytkownika (zmień na dynamiczną)

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
    _refreshTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      getProblems();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildProblemList() {
    List<List<dynamic>> paginatedProblems = [];
    for (int i = 0; i < problems.length; i += itemsPerPage) {
      paginatedProblems.add(problems.sublist(i, i + itemsPerPage > problems.length ? problems.length : i + itemsPerPage));
    }

    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
        child: paginatedProblems.isEmpty
            ? Center(
          child: Text(
            'Brak zgłoszeń.',
            style: TextStyle(fontSize: 16.0, color: Colors.black),
          ),
        )
            : Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: paginatedProblems.length,
                onPageChanged: (pageIndex) {
                  setState(() {
                    currentPage = pageIndex;
                  });
                },
                itemBuilder: (context, pageIndex) {
                  var pageProblems = paginatedProblems[pageIndex];
                  return GridView.builder(
                    padding: EdgeInsets.symmetric(vertical: 3.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 1.9,
                    ),
                    itemCount: pageProblems.length,
                    itemBuilder: (context, index) {
                      var problem = pageProblems[index];
                      return IntrinsicHeight(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: Offset(-3, 0),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: Offset(3, 0),
                              ),
                            ],
                          ),
                          margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
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
                                SizedBox(height: 5),
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
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
                    onPressed: currentPage > 0
                        ? () {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                        : null,
                  ),
                  Text(
                    '${currentPage + 1} / ${paginatedProblems.length}',
                    style: TextStyle(fontSize: 14.0, color: Colors.black),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 20, color: Colors.black),
                    onPressed: currentPage < paginatedProblems.length - 1
                        ? () {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                        : null,
                  ),
                ],
              ),
            ),
          ],
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
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'Treść zgłoszenia: ${problem['problem'] ?? 'Brak opisu'}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Zamknij'),
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
      appBar: AppBar(
        title: Text('HelpDesk Admin Panel'),
        backgroundColor: Color(0xFFFFFFFF),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white, // Ustawienie białego tła dla całego Drawer
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              Container(
                height: 73.0, // Zmniejszenie wysokości nagłówka
                child: UserAccountsDrawerHeader(
                  accountName: Text(
                    'Helpdesk Admin', // Zmieniony na napis
                    style: TextStyle(
                      color: Colors.black, // Kolor tekstu na czarny
                      fontSize: 22.0, // Zmniejszenie rozmiaru czcionki
                      fontWeight: FontWeight.bold, // Pogrubienie tekstu
                    ),
                  ),
                  accountEmail: null,
                  currentAccountPicture: null, // Usunięcie profilowego obrazka
                  decoration: BoxDecoration(
                    color: Colors.white, // Kolor tła całego headera na biały
                  ),
                  margin: EdgeInsets.zero, // Zmniejszenie marginesu wokół headera
                ),
              ),
              ListTile(
                leading: Icon(Icons.report_problem, color: Colors.black), // Kolor ikony na czarny
                title: Text(
                  'Zgłoszenia',
                  style: TextStyle(color: Colors.black), // Kolor tekstu na czarny
                ),
                onTap: () {
                  setState(() {
                    showProblems = true;
                    showUsers = false;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.group, color: Colors.black), // Kolor ikony na czarny
                title: Text(
                  'Użytkownicy',
                  style: TextStyle(color: Colors.black), // Kolor tekstu na czarny
                ),
                onTap: () {
                  setState(() {
                    showProblems = false;
                    showUsers = true;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.settings, color: Colors.black), // Kolor ikony na czarny
                title: Text(
                  'Ustawienia',
                  style: TextStyle(color: Colors.black), // Kolor tekstu na czarny
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),



      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            if (showProblems) _buildProblemList(),
          ],
        ),
      ),
    );
  }
}

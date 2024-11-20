import 'dart:convert';
import 'dart:io';
import 'dart:async';  // Dodano import do Timer
import 'package:flutter/material.dart';

class ProblemyPage extends StatefulWidget {
  final String username;

  ProblemyPage({required this.username});

  @override
  _ProblemyPageState createState() => _ProblemyPageState();
}

class _ProblemyPageState extends State<ProblemyPage> {
  List<dynamic> unreadProblems = [];
  List<dynamic> readProblems = [];
  Timer? _refreshTimer;  // Zmienna dla Timer

  Future<void> getUserProblems() async {
    try {
      var response =
      await HttpClient().getUrl(Uri.parse('http://192.168.10.188:8080/get_problems'));
      var data = await response.close();
      String content = await data.transform(utf8.decoder).join();
      List<dynamic> fetchedProblems = jsonDecode(content);

      setState(() {
        unreadProblems = fetchedProblems
            .where((problem) =>
        problem['username'] == widget.username &&
            (problem['read'] ?? false) == 0) // 0 - nieodczytane
            .toList();
        readProblems = fetchedProblems
            .where((problem) =>
        problem['username'] == widget.username &&
            (problem['read'] ?? false) == 1) // 1 - odczytane
            .toList();
      });
    } catch (e) {
      print('Błąd: $e');
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
    getUserProblems();
    _refreshTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      getUserProblems();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();  // Anulowanie Timer przy zamykaniu strony
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Moje Zgłoszenia'),
        actions: [
          // Przycisk do ręcznego odświeżania
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: getUserProblems,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: unreadProblems.isEmpty && readProblems.isEmpty
            ? Center(child: Text('Nie posiadasz zgłoszeń.'))
            : Column(
          children: [
            if (unreadProblems.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nieodczytane zgłoszenia',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: unreadProblems.length,
                      itemBuilder: (context, index) {
                        var problem = unreadProblems[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text('Pokój: ${problem['room']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Problem: ${problem['problem']}'),
                                Text('Data: ${problem['timestamp']}'),
                                Text('Status: Nieodczytane'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            if (readProblems.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Odczytane zgłoszenia',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: readProblems.length,
                      itemBuilder: (context, index) {
                        var problem = readProblems[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text('Pokój: ${problem['room']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Problem: ${problem['problem']}'),
                                Text('Data: ${problem['timestamp']}'),
                                Text('Status: Odczytane'),
                              ],
                            ),
                          ),
                        );
                      },
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

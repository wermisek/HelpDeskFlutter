import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class ProblemyPage extends StatefulWidget {
  final String username;

  ProblemyPage({required this.username});

  @override
  _ProblemyPageState createState() => _ProblemyPageState();
}

class _ProblemyPageState extends State<ProblemyPage> {
  List<dynamic> problems = [];

  Future<void> getUserProblems() async {
    try {
      var response = await HttpClient().getUrl(Uri.parse('http://192.168.10.188:8080/get_problems'));
      var data = await response.close();
      String content = await data.transform(utf8.decoder).join();
      List<dynamic> fetchedProblems = jsonDecode(content);

      setState(() {
        problems = fetchedProblems
            .where((problem) => problem['username'] == widget.username)
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Moje Zgłoszenia'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: problems.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: problems.length,
          itemBuilder: (context, index) {
            var problem = problems[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text('Pokój: ${problem['room']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Problem: ${problem['problem']}'),
                    Text('Data: ${problem['timestamp']}'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

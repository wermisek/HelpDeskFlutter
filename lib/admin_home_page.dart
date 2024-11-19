import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Problem Viewer',
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

  // Function to fetch problems from the server
  Future<void> getProblems() async {
    try {
      // Send GET request to fetch problems from the server
      var response = await HttpClient().getUrl(Uri.parse('http://192.168.10.188:8080/get_problems'));
      var data = await response.close();

      // Wait for response and decode it
      String content = await data.transform(utf8.decoder).join();

      // Decode the response JSON and update state
      List<dynamic> fetchedProblems = jsonDecode(content);
      setState(() {
        problems = fetchedProblems;
      });
    } catch (e) {
      print('Błąd: $e');
      // In case of error, display an alert to the user
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
    getProblems();  // Fetch problems when the page loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Home'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: problems.isEmpty
            ? Center(child: CircularProgressIndicator()) // Show loading indicator
            : ListView.builder(
          itemCount: problems.length,
          itemBuilder: (context, index) {
            var problem = problems[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text('Username: ${problem['username']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Room: ${problem['room']}'),
                    Text('Problem: ${problem['problem']}'),
                    Text('Timestamp: ${problem['timestamp']}'),
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

// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Klasa reprezentująca stronę ProblemTempPage
class ProblemTempPage extends StatefulWidget {
  final Map<String, dynamic> problem;

  const ProblemTempPage({super.key, required this.problem});

  @override
  _ProblemTempPageState createState() => _ProblemTempPageState();
}

// Stan dla ProblemTempPage
class _ProblemTempPageState extends State<ProblemTempPage> {
  // Funkcja do usuwania problemu
  Future<void> _deleteProblem(BuildContext context, String problemId) async {
    final url = Uri.parse('http://192.168.10.188:8080/delete_problem/$problemId');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Zgłoszenie zostało usunięte')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udało się usunąć zgłoszenia')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd połączenia z serwerem')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime timestamp = DateTime.parse(widget.problem['timestamp'] ?? DateTime.now().toString());
    String formattedTimestamp = "${timestamp.day}-${timestamp.month}-${timestamp.year} ${timestamp.hour}:${timestamp.minute}";

    return Scaffold(
      appBar: AppBar(
        title: Text('Szczegóły Zgłoszenia'),
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Color(0xFFF49402), width: 1)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F5F5), Color(0xFFF5F5F5)], // Gradient tła
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 100),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60.0),
              child: Container(
                height: 400.0,
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.0), // Zaokrąglenie krawędzi kontenera
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8.0, // Promień rozmycia cienia
                      offset: Offset(0, 4), // Przesunięcie cienia
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Szczegóły Zgłoszenia',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20.0),
                    _buildDetailRow('Sala', widget.problem['room'] ?? 'Nieznana'),
                    SizedBox(height: 15.0),
                    _buildDetailRow('Nauczyciel', widget.problem['username'] ?? 'Nieznany'),
                    SizedBox(height: 15.0),
                    _buildDetailRow('Treść', widget.problem['problem'] ?? 'Brak opisu'),
                    SizedBox(height: 15.0),
                    _buildDetailRow('Czas zgłoszenia', formattedTimestamp),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildButton(
                          label: 'Zamknij',
                          backgroundColor: Colors.white,
                          textColor: Colors.black,
                          borderColor: Colors.black,
                          onPressed: () => Navigator.pop(context),
                        ),
                        _buildButton(
                          label: 'Usuń',
                          backgroundColor: Colors.white,
                          textColor: Colors.black,
                          borderColor: Colors.red,
                          onPressed: () => _deleteProblem(context, widget.problem['id'].toString()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Funkcja do budowania wiersza szczegółów
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
            color: Colors.black,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  // Funkcja do budowania przycisku
  Widget _buildButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
    required void Function() onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        side: BorderSide(color: borderColor, width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0), // Zaokrąglenie krawędzi przycisku
        ),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 18.0),
      ),
    );
  }
}

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
  String? _comment;

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

  // Funkcja do dodawania komentarza
  Future<void> _addComment(BuildContext context, String problemId) async {
    TextEditingController commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0), // Zaokrąglenie krawędzi dialogu
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5F5F5), Color(0xFFEFEFEF)], // Gradient tła
              ),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dodaj komentarz',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Wpisz komentarz...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0), // Zaokrąglenie krawędzi pola tekstowego
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0), // Zaokrąglenie krawędzi pola tekstowego
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0), // Zaokrąglenie krawędzi pola tekstowego
                      borderSide: BorderSide(color: Color(0xFF1976D2), width: 2.0),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButton(
                      label: 'Anuluj',
                      backgroundColor: Colors.white,
                      textColor: Colors.black,
                      borderColor: Colors.black,
                      onPressed: () => Navigator.pop(context),
                    ),
                    _buildButton(
                      label: 'Dodaj',
                      backgroundColor: Colors.white,
                      textColor: Colors.black,
                      borderColor: Colors.blue,
                      onPressed: () async {
                        final url = Uri.parse('http://192.168.10.188:8080/update_comment/$problemId');
                        try {
                          final response = await http.put(
                            url,
                            headers: {'Content-Type': 'application/json'},
                            body: json.encode({'comment': commentController.text}),
                          );
                          if (response.statusCode == 200) {
                            setState(() {
                              _comment = commentController.text;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Komentarz został dodany')),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Nie udało się dodać komentarza')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Błąd połączenia z serwerem')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime timestamp = DateTime.parse(widget.problem['timestamp'] ?? DateTime.now().toString());
    String formattedTimestamp = "${timestamp.day}-${timestamp.month}-${timestamp.year} ${timestamp.hour}:${timestamp.minute}";

    String commentText = _comment ?? widget.problem['comment'] ?? 'Nie dodales jeszcze komentarza';

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
                height: 450.0,  // Increased from 400.0
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8.0,
                      offset: Offset(0, 4),
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
                    SizedBox(height: 15.0),
                    _buildDetailRow('Komentarz', commentText),
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
                        _buildButton(
                          label: 'Komentarz',
                          backgroundColor: Colors.white,
                          textColor: Colors.black,
                          borderColor: Colors.blue,
                          onPressed: () => _addComment(context, widget.problem['id'].toString()),
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
          child: Container(
            constraints: BoxConstraints(maxHeight: 70), // Add this to control height
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

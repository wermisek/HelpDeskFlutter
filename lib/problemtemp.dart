import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProblemTempPage extends StatefulWidget {
  final Map<String, dynamic> problem;

  const ProblemTempPage({super.key, required this.problem});

  @override
  _ProblemTempPageState createState() => _ProblemTempPageState();
}

class _ProblemTempPageState extends State<ProblemTempPage> {
  String? _comment; // Przechowywanie dodanego komentarza

  Future<void> _deleteProblem(BuildContext context, String problemId) async {
    final url = Uri.parse('http://192.168.10.188:8080/delete_problem/$problemId');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Zgłoszenie zostało usunięte')),
        );
        Navigator.pop(context);
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

  Future<void> _addComment(BuildContext context, String problemId) async {
    TextEditingController commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5F5F5), Color(0xFFEFEFEF)],
              ),
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
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Wpisz komentarz...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
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
                              _comment = commentController.text; // Zapisz dodany komentarz
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

    // Sprawdzamy, czy problem ma komentarz, jeśli nie ustawiamy komunikat
    String commentText = _comment ?? widget.problem['comment'] ?? 'Nie dodales jeszcze komentarza'; // Dodajemy komentarz z ciała problemu, jeśli istnieje

    return Scaffold(
      appBar: AppBar(
        title: Text('Szczegóły Zgłoszenia'),
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F5F5), Color(0xFFF5F5F5)],
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
                    // Dodajemy pole "Komentarz" z ciała problemu
                    SizedBox(height: 15.0),
                    _buildDetailRow('Komentarz', commentText), // Wyświetlenie komentarza lub komunikatu o braku komentarza
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
        backgroundColor: backgroundColor,  // Use backgroundColor instead of primary
        foregroundColor: textColor,         // Use foregroundColor instead of onPrimary
        side: BorderSide(color: borderColor, width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 18.0),
      ),
    );
  }
  }

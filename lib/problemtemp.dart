import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProblemTempPage extends StatelessWidget {
  final Map<String, dynamic> problem;

  ProblemTempPage({required this.problem});

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

  @override
  Widget build(BuildContext context) {
    DateTime timestamp = DateTime.parse(problem['timestamp'] ?? DateTime.now().toString());
    String formattedTimestamp = "${timestamp.day}-${timestamp.month}-${timestamp.year} ${timestamp.hour}:${timestamp.minute}";

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: Text('Szczegóły Zgłoszenia'),
          backgroundColor: Color(0xFFF5F5F5),
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFF49402),
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F5F5), Color(0xFFF5F5F5)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8.0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
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
                    _buildDetailRow('Sala', problem['room'] ?? 'Nieznana'),
                    SizedBox(height: 15.0),
                    _buildDetailRow('Nauczyciel', problem['username'] ?? 'Nieznany'),
                    SizedBox(height: 15.0),
                    _buildDetailRow('Treść', problem['problem'] ?? 'Brak opisu'),
                    SizedBox(height: 15.0),
                    _buildDetailRow('Czas zgłoszenia', formattedTimestamp),
                    SizedBox(height: 20.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            elevation: 8.0, // Dodanie cienia dla "Powrót"
                            shadowColor: Colors.grey,
                          ),
                          child: Text(
                            'Powrót',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _deleteProblem(context, problem['id'].toString());
                          },
                          style: ButtonStyle(
                            side: MaterialStateProperty.all(BorderSide(color: Colors.red, width: 2)),
                            foregroundColor: MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                if (states.contains(MaterialState.hovered)) {
                                  return Colors.white; // Biały tekst przy hover
                                }
                                return Colors.black; // Czarny tekst domyślnie
                              },
                            ),
                            backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                if (states.contains(MaterialState.hovered)) {
                                  return Colors.red; // Czerwone tło przy hover
                                }
                                return Colors.white; // Białe tło domyślnie
                              },
                            ),
                            animationDuration: Duration.zero,
                            padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 40.0, vertical: 12.0)),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            elevation: MaterialStateProperty.all(8.0),
                            shadowColor: MaterialStateProperty.all(Colors.black),
                          ),
                          child: Text(
                            'Usuń',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
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
          ),
        ),
      ],
    );
  }
}

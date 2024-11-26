import 'package:flutter/material.dart';

class ProblemTempPage extends StatelessWidget {
  final Map<String, dynamic> problem;

  ProblemTempPage({required this.problem});

  @override
  Widget build(BuildContext context) {
    // Pobranie i formatowanie timestampu
    DateTime timestamp = DateTime.parse(problem['timestamp'] ?? DateTime.now().toString());
    String formattedTimestamp = "${timestamp.day}-${timestamp.month}-${timestamp.year} ${timestamp.hour}:${timestamp.minute}";

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: Text('Szczegóły Zgłoszenia'),
          backgroundColor: Color(0xFFF5F5F5),
          elevation: 0, // Usuń domyślny cień AppBar
          flexibleSpace: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.5), // Kolor linii
                  width: 1.0, // Grubość linii
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
          padding: const EdgeInsets.all(71.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Duża karta zawierająca wszystkie informacje
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
                    // Nagłówek
                    Text(
                      'Szczegóły Zgłoszenia',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20.0),

                    // Sala
                    _buildDetailRow('Sala', problem['room'] ?? 'Nieznana'),
                    SizedBox(height: 15.0),

                    // Nauczyciel
                    _buildDetailRow('Nauczyciel', problem['username'] ?? 'Nieznany'),
                    SizedBox(height: 15.0),

                    // Treść
                    _buildDetailRow('Treść', problem['problem'] ?? 'Brak opisu'),
                    SizedBox(height: 15.0),

                    // Timestamp
                    _buildDetailRow('Czas zgłoszenia', formattedTimestamp),
                    SizedBox(height: 20.0),

                    // Przycisk powrotu
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // Kolor tła przycisku
                          padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: Text(
                          'Powrót',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Kolor tekstu przycisku
                          ),
                        ),
                      ),
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

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProblemTempPage extends StatefulWidget {
  final Map<String, dynamic> problem;

  const ProblemTempPage({super.key, required this.problem});

  @override
  _ProblemTempPageState createState() => _ProblemTempPageState();
}

class _ProblemTempPageState extends State<ProblemTempPage> {
  bool _isHovered = false; // To track hover state of the 'Usuń' button

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
    DateTime timestamp = DateTime.parse(widget.problem['timestamp'] ?? DateTime.now().toString());
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
        child: Column(
          children: [
            SizedBox(height: 100), // Adjust this height to move content higher/lower
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60.0), // Padding outside the container (32px on both sides)
              child: Container(
                height: 360.0,
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
                  ], // Shadow kept for the container
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start, // Push content to the top
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
                    Spacer(), // This pushes the buttons to the bottom of the container
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
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            elevation: 0.0,  // Removed shadow from the button
                            side: BorderSide(color: Colors.black), // Small black border around Zamknij button
                          ),
                          child: Text(
                            'Zamknij',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _isHovered = true; // Update state when hovering
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              _isHovered = false; // Revert state when mouse exits
                            });
                          },
                          child: TextButton(
                            onPressed: () {
                              _deleteProblem(context, widget.problem['id'].toString());
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 12.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              side: BorderSide(color: Colors.red, width: 1),  // Border still there
                              foregroundColor: _isHovered ? Colors.white : Colors.black, // Text color white on hover
                              backgroundColor: _isHovered ? Colors.red : Colors.white, // Button background red on hover
                              elevation: 0.0, // Removed shadow from the button
                            ),
                            child: Text(
                              'Usuń',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
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

  // Modified _buildDetailRow to fit content
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Aligns the text to the top
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16.0,
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
            overflow: TextOverflow.ellipsis, // Truncates text if it's too long
            maxLines: 3, // Limit the number of lines to 3 (optional)
          ),
        ),
      ],
    );
  }
}

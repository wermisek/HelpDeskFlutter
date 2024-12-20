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

  // Helper functions for styling
  Color getPriorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String getPriorityText(String? priority) {
    switch (priority) {
      case 'high':
        return 'Wysoki';
      case 'medium':
        return 'Średni';
      case 'low':
        return 'Niski';
      default:
        return 'Nieokreślony';
    }
  }

  IconData getPriorityIcon(String? priority) {
    switch (priority) {
      case 'high':
        return Icons.arrow_upward;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.arrow_downward;
      default:
        return Icons.remove;
    }
  }

  String getStatusText(String? status) {
    switch (status) {
      case 'new':
        return 'Nowe';
      case 'in_progress':
        return 'W trakcie';
      case 'resolved':
        return 'Rozwiązane';
      default:
        return 'Nieznany';
    }
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'in_progress':
        return Color(0xFFF49402);
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Helper function to get category name in Polish
  String getCategoryName(String? categoryId) {
    switch (categoryId) {
      case 'hardware':
        return 'Sprzęt';
      case 'software':
        return 'Oprogramowanie';
      case 'network':
        return 'Sieć';
      case 'printer':
        return 'Drukarka';
      case 'other':
        return 'Inne';
      default:
        return 'Nie określono';
    }
  }

  // Funkcja do usuwania problemu
  Future<void> _deleteProblem(BuildContext context, String problemId) async {
    final url = Uri.parse('http://localhost:8080/delete_problem/$problemId');
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
                        final url = Uri.parse('http://localhost:8080/update_comment/$problemId');
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

  // Function to update priority
  Future<void> _updatePriority(String newPriority) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:8080/update_priority/${widget.problem['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'priority': newPriority}),
      );

      if (response.statusCode == 200) {
        setState(() {
          widget.problem['priority'] = newPriority;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Priorytet został zmieniony')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udało się zmienić priorytetu')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd połączenia z serwerem')),
      );
    }
  }

  // Function to show priority change dialog
  void _showPriorityChangeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Container(
            width: 400,
            padding: EdgeInsets.all(32),
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Zmień priorytet',
                  style: TextStyle(
                        fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 24, color: Colors.grey[400]),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Wybierz nowy priorytet dla zgłoszenia',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                _buildPriorityOption('high', 'Wysoki', Colors.red),
                SizedBox(height: 12),
                _buildPriorityOption('medium', 'Średni', Colors.orange),
                SizedBox(height: 12),
                _buildPriorityOption('low', 'Niski', Colors.green),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper function to build priority option
  Widget _buildPriorityOption(String priority, String label, Color color) {
    bool isSelected = widget.problem['priority'] == priority;
    return InkWell(
      onTap: () {
        _updatePriority(priority);
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
              getPriorityIcon(priority),
              color: color,
              size: 20,
            ),
            ),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? color : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            Spacer(),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: color,
                  size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime timestamp = DateTime.parse(widget.problem['timestamp'] ?? DateTime.now().toString());
    String formattedTimestamp = "${timestamp.day}.${timestamp.month}.${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";
    String commentText = _comment ?? widget.problem['comment'] ?? 'Nie dodales jeszcze komentarza';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              'Zgłoszenie #${widget.problem['id']}',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            SizedBox(width: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: getPriorityColor(widget.problem['priority']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: getPriorityColor(widget.problem['priority']).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    getPriorityIcon(widget.problem['priority']),
                    size: 16,
                    color: getPriorityColor(widget.problem['priority']),
                  ),
                  SizedBox(width: 6),
                  Text(
                    getPriorityText(widget.problem['priority']),
                    style: TextStyle(
                      color: getPriorityColor(widget.problem['priority']),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: ElevatedButton.icon(
              icon: Icon(Icons.priority_high, size: 18),
              label: Text('Zmień priorytet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0,
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _showPriorityChangeDialog,
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF5F5F5), Color(0xFFF5F5F5)],
            ),
          ),
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumb Navigation
                    Row(
                      children: [
                        Text(
                          'Panel administratora',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        Text(
                          'Zgłoszenia',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        Text(
                          'Szczegóły zgłoszenia #${widget.problem['id']}',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    // Problem Details Summary
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sala ${widget.problem['room'] ?? 'Nieznana'}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.problem['problem'] ?? 'Brak opisu problemu',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 24),
                        // Quick Info Cards
                        Row(
                          children: [
                            _buildInfoCard(
                              icon: Icons.category_outlined,
                              label: 'Kategoria',
                              value: getCategoryName(widget.problem['category']),
                              color: Colors.blue,
                            ),
                            SizedBox(width: 16),
                            _buildInfoCard(
                              icon: Icons.access_time,
                              label: 'Data zgłoszenia',
                              value: formattedTimestamp,
                              color: Colors.green,
                            ),
                            SizedBox(width: 16),
                            _buildInfoCard(
                              icon: Icons.person_outline,
                              label: 'Zgłaszający',
                              value: widget.problem['username'] ?? 'Nieznany',
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60.0),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(32.0, 24.0, 32.0, 24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8.0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Problem Description Section
                        Text(
                          'Opis problemu',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                            ),
                          ),
                          child: Text(
                            widget.problem['problem'] ?? 'Brak opisu problemu',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                        SizedBox(height: 32),

                        // Comment Section
                        Text(
                          'Komentarz administratora',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                            ),
                          ),
                          child: Text(
                            commentText,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                        Spacer(),

                        // Bottom Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  icon: Icon(Icons.add_comment_outlined, size: 18),
                                  label: Text('Dodaj komentarz'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Color(0xFFF49402),
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    side: BorderSide(color: Color(0xFFF49402)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => _addComment(context, widget.problem['id'].toString()),
                                ),
                            SizedBox(width: 16),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.delete_outline, size: 18),
                                  label: Text('Usuń zgłoszenie'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red[700],
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    side: BorderSide(color: Colors.red[200]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => _deleteProblem(context, widget.problem['id'].toString()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build detail rows (if needed)
  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16.0,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Updated button builder with modern styling
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
        elevation: 0,
        side: BorderSide(color: borderColor),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: color.withOpacity(0.8),
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

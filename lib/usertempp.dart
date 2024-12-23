// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

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
  String? _comment;

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
        return Icons.help_outline;
    }
  }

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

  IconData getCategoryIcon(String? categoryId) {
    switch (categoryId) {
      case 'hardware':
        return Icons.computer;
      case 'software':
        return Icons.apps;
      case 'network':
        return Icons.wifi;
      case 'printer':
        return Icons.print;
      case 'other':
        return Icons.help_outline;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _deleteProblem(BuildContext context, String problemId) async {
    final url = Uri.parse('http://localhost:8080/delete_problem/$problemId');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zgłoszenie zostało usunięte'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie udało się usunąć zgłoszenia'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wystąpił błąd podczas usuwania zgłoszenia'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final problem = widget.problem;
    final timestamp = DateTime.parse(problem['timestamp'] ?? '');
    final solvedTimestamp = problem['solved_timestamp'] != null
        ? DateTime.parse(problem['solved_timestamp'])
        : null;
    final isRead = problem['read'] == 1;
    final status = problem['status'] ?? 'pending';
    final comment = problem['comment'] as String?;
    final formattedTimestamp = "${timestamp.day}.${timestamp.month}.${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";

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
              'Zgłoszenie #${problem['id']}',
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
                color: getPriorityColor(problem['priority']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: getPriorityColor(problem['priority']).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    getPriorityIcon(problem['priority']),
                    size: 16,
                    color: getPriorityColor(problem['priority']),
                  ),
                  SizedBox(width: 6),
                  Text(
                    getPriorityText(problem['priority']),
                    style: TextStyle(
                      color: getPriorityColor(problem['priority']),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                  // Problem Details Summary
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                              'Sala ${problem['room'] ?? 'Nieznana'}',
                      style: TextStyle(
                                fontSize: 24,
                        fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              problem['problem'] ?? 'Brak opisu problemu',
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
                            value: getCategoryName(problem['category']),
                            color: Colors.blue,
                          ),
                          SizedBox(width: 16),
                          _buildInfoCard(
                            icon: Icons.access_time,
                            label: 'Data zgłoszenia',
                            value: formattedTimestamp,
                            color: Colors.green,
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
                          problem['problem'] ?? 'Brak opisu problemu',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                      if (comment != null) ...[
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
                            comment,
            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.5,
            ),
          ),
        ),
      ],
                      Spacer(),
                      // Bottom Action Buttons
                      if (status != 'Rozwiązane')
                        Center(
                          child: ElevatedButton.icon(
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
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Potwierdź usunięcie'),
                                content: Text('Czy na pewno chcesz usunąć to zgłoszenie?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Anuluj'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deleteProblem(context, problem['id'].toString());
                                    },
                                    child: Text(
                                      'Usuń',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
    );
  }
}

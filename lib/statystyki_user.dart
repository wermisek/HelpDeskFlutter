// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class StatystykiUserPage extends StatefulWidget {
  final String username;

  const StatystykiUserPage({super.key, required this.username});

  @override
  _StatystykiUserPageState createState() => _StatystykiUserPageState();
}

class _StatystykiUserPageState extends State<StatystykiUserPage> {
  List<dynamic> problems = [];
  bool isLoading = true;
  Map<String, int> categoryStats = {};
  Map<String, int> priorityStats = {};
  Map<String, int> statusStats = {};
  int totalProblems = 0;
  Map<String, bool> hoverStates = {};

  @override
  void initState() {
    super.initState();
    _fetchProblems();
  }

  Future<void> _fetchProblems() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8080/get_problems'));
      if (response.statusCode == 200) {
        final List<dynamic> allProblems = json.decode(response.body);
        problems = allProblems.where((p) => p['username'] == widget.username).toList();
        _calculateStats();
      }
    } catch (e) {
      print('Error fetching problems: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _calculateStats() {
    categoryStats.clear();
    priorityStats.clear();
    statusStats.clear();
    totalProblems = problems.length;

    for (var problem in problems) {
      // Category stats
      final category = problem['category'] ?? 'other';
      categoryStats[category] = (categoryStats[category] ?? 0) + 1;

      // Priority stats
      final priority = problem['priority'] ?? 'low';
      priorityStats[priority] = (priorityStats[priority] ?? 0) + 1;

      // Status stats
      final status = problem['status'] ?? 'untouched';
      statusStats[status] = (statusStats[status] ?? 0) + 1;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
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
        return 'Nieznane';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'hardware':
        return Colors.blue;
      case 'software':
        return Colors.green;
      case 'network':
        return Colors.orange;
      case 'printer':
        return Colors.purple;
      case 'other':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityName(String priority) {
    switch (priority) {
      case 'high':
        return 'Wysoki';
      case 'medium':
        return 'Średni';
      case 'low':
        return 'Niski';
      default:
        return 'Nieznany';
    }
  }

  Color _getPriorityColor(String priority) {
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

  String _getStatusName(String status) {
    switch (status) {
      case 'done':
        return 'Zakończone';
      case 'in_progress':
        return 'W trakcie';
      case 'untouched':
        return 'Nierozpoczęte';
      default:
        return 'Nieznany';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'untouched':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Moje Statystyki',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            color: Color(0xFFF49402),
            thickness: 1.0,
            height: 1.0,
          ),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFF49402)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  SizedBox(height: 24),
                  _buildChartsSection(),
                  SizedBox(height: 24),
                  _buildDetailsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildSummaryCard(
            'Wszystkie zgłoszenia',
            totalProblems.toString(),
            Icons.assignment,
            Color(0xFFF49402),
          ),
          _buildSummaryCard(
            'Zakończone',
            (statusStats['done'] ?? 0).toString(),
            Icons.check_circle,
            Colors.green,
          ),
          _buildSummaryCard(
            'W trakcie',
            (statusStats['in_progress'] ?? 0).toString(),
            Icons.pending,
            Colors.orange,
          ),
          _buildSummaryCard(
            'Nierozpoczęte',
            (statusStats['untouched'] ?? 0).toString(),
            Icons.schedule,
            Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 240,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 400,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zgłoszenia według kategorii',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24),
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: categoryStats.entries.map((entry) {
                        return PieChartSectionData(
                          color: _getCategoryColor(entry.key),
                          value: entry.value.toDouble(),
                          title: '${(entry.value / totalProblems * 100).toStringAsFixed(1)}%',
                          radius: 100,
                          titleStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: categoryStats.entries.map((entry) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(entry.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _getCategoryName(entry.key),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          child: Container(
            height: 400,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zgłoszenia według priorytetu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: priorityStats.values.fold(0, (p, c) => p > c ? p : c).toDouble(),
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              String priority = '';
                              if (value == 0) priority = 'Wysoki';
                              if (value == 1) priority = 'Średni';
                              if (value == 2) priority = 'Niski';
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  priority,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[200],
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                          left: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: (priorityStats['high'] ?? 0).toDouble(),
                              color: Colors.red,
                              width: 20,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: (priorityStats['medium'] ?? 0).toDouble(),
                              color: Colors.orange,
                              width: 20,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 2,
                          barRods: [
                            BarChartRodData(
                              toY: (priorityStats['low'] ?? 0).toDouble(),
                              color: Colors.green,
                              width: 20,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
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
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Szczegółowe statystyki',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildDetailsList(
                  'Kategorie',
                  categoryStats,
                  _getCategoryName,
                  _getCategoryColor,
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: _buildDetailsList(
                  'Priorytety',
                  priorityStats,
                  _getPriorityName,
                  _getPriorityColor,
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: _buildDetailsList(
                  'Status',
                  statusStats,
                  _getStatusName,
                  _getStatusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsList(
    String title,
    Map<String, int> stats,
    String Function(String) getName,
    Color Function(String) getColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        ...stats.entries.map((entry) {
          final percentage = (entry.value / totalProblems * 100).toStringAsFixed(1);
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: getColor(entry.key),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    getName(entry.key),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
} 
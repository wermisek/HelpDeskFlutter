import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class StatystykiAdminPage extends StatefulWidget {
  final String username;

  const StatystykiAdminPage({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  _StatystykiAdminPageState createState() => _StatystykiAdminPageState();
}

class _StatystykiAdminPageState extends State<StatystykiAdminPage> {
  bool _isLoading = true;
  Map<String, int> categoryStats = {};
  Map<String, int> priorityStats = {};
  Map<String, int> dailyStats = {};
  Map<String, int> weeklyStats = {};
  Map<String, int> userStats = {};
  int totalProblems = 0;
  int solvedProblems = 0;
  int pendingProblems = 0;
  double averageResponseTime = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/get_problems'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> problems = json.decode(response.body);
        
        // Reset stats
        categoryStats = {};
        priorityStats = {};
        dailyStats = {};
        weeklyStats = {};
        userStats = {};
        totalProblems = problems.length;
        solvedProblems = 0;
        pendingProblems = 0;
        int totalResponseTime = 0;
        int problemsWithResponse = 0;

        final now = DateTime.now();

        // Calculate statistics
        for (var problem in problems) {
          // User stats
          final username = problem['username'] as String? ?? 'unknown';
          userStats[username] = (userStats[username] ?? 0) + 1;

          // Category stats
          final category = problem['category'] as String? ?? 'other';
          categoryStats[category] = (categoryStats[category] ?? 0) + 1;

          // Priority stats
          final priority = problem['priority'] as String? ?? 'low';
          priorityStats[priority] = (priorityStats[priority] ?? 0) + 1;

          // Status stats
          if (problem['status'] == 'Rozwiązane') {
            solvedProblems++;
            
            // Calculate response time if we have both timestamps
            if (problem['timestamp'] != null && problem['solved_timestamp'] != null) {
              final createTime = DateTime.parse(problem['timestamp']);
              final solveTime = DateTime.parse(problem['solved_timestamp']);
              final responseTime = solveTime.difference(createTime).inHours;
              totalResponseTime += responseTime;
              problemsWithResponse++;
            }
          } else {
            pendingProblems++;
          }

          // Daily stats (last 7 days)
          if (problem['timestamp'] != null) {
            final date = DateTime.parse(problem['timestamp']);
            final daysAgo = now.difference(date).inDays;
            
            if (daysAgo < 7) {
              // Create a list of the last 7 days
              for (int i = 6; i >= 0; i--) {
                final day = now.subtract(Duration(days: i));
                final dayKey = '${day.day}.${day.month}';
                if (!dailyStats.containsKey(dayKey)) {
                  dailyStats[dayKey] = 0;
                }
              }
              
              // Add the problem to its day
              final problemDayKey = '${date.day}.${date.month}';
              dailyStats[problemDayKey] = (dailyStats[problemDayKey] ?? 0) + 1;
            }

            // Weekly stats (last 4 weeks)
            if (problem['timestamp'] != null) {
              final date = DateTime.parse(problem['timestamp']);
              final daysAgo = now.difference(date).inDays;
              
              // Initialize all 4 weeks with zero if not already done
              for (int i = 1; i <= 4; i++) {
                final weekKey = 'Tydzień $i';
                if (!weeklyStats.containsKey(weekKey)) {
                  weeklyStats[weekKey] = 0;
                }
              }

              // Add to appropriate week
              if (daysAgo < 28) {  // 4 weeks * 7 days
                final weekNumber = (daysAgo / 7).floor() + 1;
                if (weekNumber <= 4) {
                  final weekKey = 'Tydzień $weekNumber';
                  weeklyStats[weekKey] = (weeklyStats[weekKey] ?? 0) + 1;
                }
              }
            }
          }
        }

        // Sort daily stats by date
        var sortedDailyStats = Map.fromEntries(
          dailyStats.entries.toList()
            ..sort((a, b) {
              var partsA = a.key.split('.');
              var partsB = b.key.split('.');
              var dateA = DateTime(2024, int.parse(partsA[1]), int.parse(partsA[0]));
              var dateB = DateTime(2024, int.parse(partsB[1]), int.parse(partsB[0]));
              return dateA.compareTo(dateB);
            })
        );
        dailyStats = sortedDailyStats;

        // Sort weekly stats by week number
        var sortedWeeklyStats = Map.fromEntries(
          weeklyStats.entries.toList()
            ..sort((a, b) {
              var weekA = int.parse(a.key.split(' ')[1]);
              var weekB = int.parse(b.key.split(' ')[1]);
              return weekA.compareTo(weekB);
            })
        );
        weeklyStats = sortedWeeklyStats;

        // Calculate average response time
        if (problemsWithResponse > 0) {
          averageResponseTime = totalResponseTime / problemsWithResponse;
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching stats: $e');
      setState(() {
        _isLoading = false;
      });
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(Map<String, int> data, String title, IconData icon) {
    if (data.isEmpty) return SizedBox();

    final List<FlSpot> spots = [];
    final List<String> bottomTitles = [];
    int index = 0;
    int maxValue = 0;

    data.forEach((key, value) {
      spots.add(FlSpot(index.toDouble(), value.toDouble()));
      bottomTitles.add(key);
      if (value > maxValue) maxValue = value;
      index++;
    });

    // Add padding to max value for better visualization
    maxValue = maxValue + (maxValue * 0.2).ceil();
    if (maxValue == 0) maxValue = 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Color(0xFFF49402).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: Color(0xFFF49402)),
              ),
              SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                    horizontalInterval: maxValue > 4 ? maxValue / 4 : 1,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value.toInt() != value) return Text('');
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          );
                        },
                        interval: maxValue > 4 ? maxValue / 4 : 1,
                        reservedSize: 24,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= bottomTitles.length) return Text('');
                          return Transform.rotate(
                            angle: -0.5,
                            child: Container(
                              padding: EdgeInsets.only(top: 5.0),
                              child: Text(
                                bottomTitles[value.toInt()],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      left: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  minX: -0.5,
                  maxX: spots.length - 0.5,
                  minY: 0,
                  maxY: maxValue.toDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Color(0xFFF49402),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      curveSmoothness: 0.2,
                      preventCurveOverShooting: true,
                      preventCurveOvershootingThreshold: 1.0,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Colors.white,
                            strokeWidth: 1.5,
                            strokeColor: Color(0xFFF49402),
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFF49402).withOpacity(0.2),
                            Color(0xFFF49402).withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      showOnTopOfTheChartBoxArea: true,
                      tooltipPadding: EdgeInsets.all(8),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          return LineTooltipItem(
                            '${touchedSpot.y.toInt()}',
                            const TextStyle(
                              color: Color(0xFFF49402),
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStats() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFFF49402).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.category, size: 16, color: Color(0xFFF49402)),
              ),
              SizedBox(width: 8),
              Text(
                'Zgłoszenia według kategorii',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...categoryStats.entries.map((entry) {
            final percentage = (entry.value / totalProblems * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getCategoryName(entry.key),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '$percentage% (${entry.value})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF49402),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.grey[200],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          children: [
                            Container(
                              width: constraints.maxWidth * (entry.value / totalProblems),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: Color(0xFFF49402),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    // Sort users by number of problems (descending)
    var sortedUsers = userStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFFF49402).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.person, size: 16, color: Color(0xFFF49402)),
              ),
              SizedBox(width: 8),
              Text(
                'Statystyki użytkowników',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...sortedUsers.take(5).map((entry) {
            final percentage = (entry.value / totalProblems * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '$percentage% (${entry.value})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF49402),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.grey[200],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          children: [
                            Container(
                              width: constraints.maxWidth * (entry.value / totalProblems),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: Color(0xFFF49402),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statystyki',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchStats,
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(
            color: Color(0xFFF49402),
            thickness: 1.0,
            height: 1.0,
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Color(0xFFF49402)))
                : Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column - Stats and Categories
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              // Top stats in a row
                              Container(
                                height: 70,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildCompactStatCard(
                                        'Wszystkie',
                                        totalProblems.toString(),
                                        Icons.assignment,
                                        Color(0xFFF49402),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: _buildCompactStatCard(
                                        'Średnie',
                                        (priorityStats['medium'] ?? 0).toString(),
                                        Icons.warning_amber,
                                        Colors.orange,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: _buildCompactStatCard(
                                        'Niskie',
                                        (priorityStats['low'] ?? 0).toString(),
                                        Icons.low_priority,
                                        Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12),
                              // Category stats
                              Expanded(
                                child: _buildCategoryStats(),
                              ),
                              SizedBox(height: 12),
                              // User stats
                              Expanded(
                                child: _buildUserStats(),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        // Right column - Charts
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Expanded(
                                child: _buildLineChart(
                                  dailyStats,
                                  'Zgłoszenia w ostatnich 7 dniach',
                                  Icons.calendar_today,
                                ),
                              ),
                              SizedBox(height: 12),
                              Expanded(
                                child: _buildLineChart(
                                  weeklyStats,
                                  'Zgłoszenia w ostatnich 4 tygodniach',
                                  Icons.date_range,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
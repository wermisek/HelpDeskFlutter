import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class StatystykiUserPage extends StatefulWidget {
  final String username;

  const StatystykiUserPage({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  _StatystykiUserPageState createState() => _StatystykiUserPageState();
}

class _StatystykiUserPageState extends State<StatystykiUserPage> {
  bool _isLoading = true;
  Map<String, int> categoryStats = {};
  Map<String, int> priorityStats = {};
  Map<String, int> dailyStats = {};
  Map<String, int> statusStats = {};
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
        final List<dynamic> allProblems = json.decode(response.body);
        // Filter problems for current user
        final problems = allProblems.where((p) => p['username'] == widget.username).toList();
        
        // Reset stats
        categoryStats = {};
        priorityStats = {};
        dailyStats = {};
        statusStats = {};
        totalProblems = problems.length;
        solvedProblems = 0;
        pendingProblems = 0;
        int totalResponseTime = 0;
        int problemsWithResponse = 0;

        final now = DateTime.now();

        // Calculate statistics
        for (var problem in problems) {
          // Category stats
          final category = problem['category'] as String? ?? 'other';
          categoryStats[category] = (categoryStats[category] ?? 0) + 1;

          // Priority stats
          final priority = problem['priority'] as String? ?? 'low';
          priorityStats[priority] = (priorityStats[priority] ?? 0) + 1;

          // Status stats
          final status = problem['status'] as String? ?? 'pending';
          statusStats[status] = (statusStats[status] ?? 0) + 1;

          if (status == 'Rozwiązane') {
            solvedProblems++;
            
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
              final dayKey = '${date.day}/${date.month}';
              dailyStats[dayKey] = (dailyStats[dayKey] ?? 0) + 1;
            }
          }
        }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Moje Statystyki',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.15,
                        child: _buildSummaryCards(),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader('Według kategorii', Icons.category),
                                  SizedBox(height: 8),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            spreadRadius: 0,
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: _buildPieChart(categoryStats),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader('Według priorytetu', Icons.flag),
                                  SizedBox(height: 8),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            spreadRadius: 0,
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: _buildPieChart(priorityStats),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Zgłoszenia w ostatnich 7 dniach', Icons.calendar_today),
                            SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      spreadRadius: 0,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: _buildBarChart(),
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

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.2,
      children: [
        _buildStatCard('Wszystkie zgłoszenia', totalProblems.toString(), Icons.list_alt),
        _buildStatCard('Wysoki priorytet', (priorityStats['high'] ?? 0).toString(), Icons.priority_high),
        _buildStatCard('Sprzęt', (categoryStats['hardware'] ?? 0).toString(), Icons.computer),
        _buildStatCard('Sieć', (categoryStats['network'] ?? 0).toString(), Icons.wifi),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Color(0xFFF49402)),
            SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Color(0xFFF49402)),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, int> data) {
    final List<Color> colors = [
      Color(0xFFF49402), // Orange (primary)
      Color(0xFF4CAF50), // Green
      Color(0xFF2196F3), // Blue
      Color(0xFFF44336), // Red
      Color(0xFF9C27B0), // Purple
      Color(0xFF607D8B), // Blue Grey
    ];

    return PieChart(
      PieChartData(
        sections: data.entries.map((entry) {
          final index = data.keys.toList().indexOf(entry.key);
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: entry.value.toDouble(),
            title: '${_translateCategory(entry.key)}\n${entry.value}',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 0,
      ),
    );
  }

  String _translateCategory(String category) {
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
      case 'high':
        return 'Wysoki';
      case 'medium':
        return 'Średni';
      case 'low':
        return 'Niski';
      default:
        return category;
    }
  }

  Widget _buildBarChart() {
    final List<FlSpot> spots = [];
    final List<String> bottomTitles = [];
    int index = 0;
    int maxValue = 0;

    // Generate dates for the last 7 days
    final List<String> days = List.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: 6 - index));
      return '${date.day}/${date.month}';
    });

    // Create spots and calculate max value
    for (int i = 0; i < days.length; i++) {
      final value = dailyStats[days[i]]?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), value));
      bottomTitles.add(days[i]);
      if (value > maxValue) maxValue = value.toInt();
    }

    // Add padding to max value for better visualization
    maxValue = maxValue + (maxValue * 0.2).ceil();
    if (maxValue == 0) maxValue = 1;

    return LineChart(
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
    );
  }
} 
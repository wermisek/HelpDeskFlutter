// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'settings.dart';
import 'package:http/http.dart' as http;
import 'problemtemp.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'dart:typed_data';
import 'login.dart';
import 'statystyki_admin.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelpDesk Admin',
      theme: ThemeData.light().copyWith(
        primaryColor: Color(0xFFFFFFFF),
        scaffoldBackgroundColor: Color(0xFFFFFFFF),
        buttonTheme: ButtonThemeData(buttonColor: Colors.white),
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      home: LoginPage(),
    );
  }
}

class AdminHomePage extends StatefulWidget {
  final String username;

  const AdminHomePage({
    super.key,
    required this.username,
  });

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  late Uint8List decodedImage;
  String searchQuery = '';
  String? selectedCategory;
  String? selectedPriority;
  List<dynamic> problems = [];
  List<dynamic> filteredProblems = [];
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  Timer? _refreshTimer;
  bool showUsers = false;
  bool showProblems = true;
  int currentPageNumber = 1;
  final PageController _problemsPageController = PageController();
  final PageController _usersPageController = PageController();
  int currentPage = 0;
  final int itemsPerPage = 12;
  DateTime? selectedDate;
  late String currentUsername;
  Map<String, bool> hoverStates = {};
  bool _isLoading = false;
  final Map<String, Color> statusColors = {
    'untouched': Colors.grey,
    'in_progress': Colors.orange,
    'done': Colors.green,
  };

  String getRelativeTime(String timestamp) {
    final now = DateTime.now();
    final date = DateTime.parse(timestamp);
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Przed chwilą';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minuta' : minutes < 5 ? 'minuty' : 'minut'} temu';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'godz' : hours < 5 ? 'godz' : 'godz'} temu';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'dzień' : 'dni'} temu';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await getProblems();
    await getUsers();

    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      getProblems();
      getUsers();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _problemsPageController.dispose();
    _usersPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> getProblems() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/get_problems'),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        List<dynamic> fetchedProblems = List<dynamic>.from(json.decode(response.body));
        
        if (mounted && fetchedProblems.toString() != problems.toString()) {
          setState(() {
            problems = fetchedProblems;
            
            // Apply current filters and sorting
            List<dynamic> filtered = List.from(problems);
            
            // Apply search filter if active
            if (searchQuery.isNotEmpty) {
              if (int.tryParse(searchQuery) != null) {
                filtered = filtered.where((problem) =>
                  problem['room'].toString().toLowerCase().contains(searchQuery.toLowerCase())
                ).toList();
              } else {
                filtered = filtered.where((problem) =>
                  problem['username'].toString().toLowerCase().contains(searchQuery.toLowerCase())
                ).toList();
              }
            }
            
            // Apply date filter if active
            if (selectedDate != null) {
              filtered = filtered.where((problem) {
                if (problem['timestamp'] != null) {
                  DateTime problemDate = DateTime.parse(problem['timestamp']);
                  return problemDate.year == selectedDate!.year &&
                      problemDate.month == selectedDate!.month &&
                      problemDate.day == selectedDate!.day;
                }
                return false;
              }).toList();
            }
            
            // Apply category filter if active
            if (selectedCategory != null) {
              filtered = filtered.where((problem) => problem['category'] == selectedCategory).toList();
            }
            
            // Apply priority filter if active
            if (selectedPriority != null) {
              filtered = filtered.where((problem) => problem['priority'] == selectedPriority).toList();
            }
            
            // Always sort by newest first
            filtered.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
            
            filteredProblems = filtered;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch problems')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyCurrentFilter() {
    if (!mounted) return;
    
    List<dynamic> filtered = List.from(problems);
    
    if (searchQuery.isNotEmpty) {
      if (int.tryParse(searchQuery) != null) {
        filtered = filtered.where((problem) =>
          problem['room'].toString().toLowerCase().contains(searchQuery.toLowerCase())
        ).toList();
      } else {
        filtered = filtered.where((problem) =>
          problem['username'].toString().toLowerCase().contains(searchQuery.toLowerCase())
        ).toList();
      }
    } else if (selectedDate != null) {
      filtered = filtered.where((problem) {
        if (problem['timestamp'] != null) {
          DateTime problemDate = DateTime.parse(problem['timestamp']);
          return problemDate.year == selectedDate!.year &&
              problemDate.month == selectedDate!.month &&
              problemDate.day == selectedDate!.day;
        }
        return false;
      }).toList();
    }

    filtered.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
    
    setState(() {
      filteredProblems = filtered;
      // Remove the currentPage reset
      // Only reset page if we have fewer pages than the current page
      int totalPages = (filtered.length / itemsPerPage).ceil();
      if (currentPage >= totalPages) {
        currentPage = totalPages > 0 ? totalPages - 1 : 0;
        if (_problemsPageController.hasClients) {
          _problemsPageController.jumpToPage(currentPage);
        }
      }
    });
  }

  Future<void> getUsers() async {
    if (_isLoading) return;
    
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/get_users'),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (mounted) {
          final newUsers = jsonDecode(response.body);
          if (newUsers.toString() != users.toString()) {
            setState(() {
              users = newUsers;
              filteredUsers = List.from(users);
            });
          }
        }
      } else {
        if (mounted) {
          _showErrorDialog(context, 'Błąd serwera', 
            'Nie udało się pobrać danych użytkowników. Kod błędu: ${response.statusCode}');
        }
      }
    } on TimeoutException {
      if (mounted) {
        _showErrorDialog(context, 'Błąd połączenia', 
          'Przekroczono limit czasu połączenia z serwerem.');
      }
    } on SocketException {
      if (mounted) {
        _showErrorDialog(context, 'Błąd połączenia', 
          'Nie można połączyć się z serwerem. Sprawdź czy serwer jest uruchomiony na localhost:8080');
      }
    } catch (e) {
      if (mounted) {
        print('Error fetching users: $e');
        _showErrorDialog(context, 'Błąd połączenia', 
          'Wystąpił nieoczekiwany błąd podczas pobierania danych użytkowników.');
      }
    }
  }

  void _initializeProblems() {
    setState(() {
      problems.sort((a, b) =>
          DateTime.parse(b['timestamp'])
              .compareTo(DateTime.parse(a['timestamp'])));
      filteredProblems = List.from(problems);
    });
  }

  void _resetFilter() {
    setState(() {
      filteredProblems = problems;
    });
  }

  Widget _buildProblemList() {
    return Expanded(
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
            child: Column(
              children: [
                if (filteredProblems.isEmpty && !_isLoading)
                  Expanded(
                    child: Center(
                      child: Text(
                        'Brak zgłoszeń pasujących do wyszukiwania.',
                        style: TextStyle(fontSize: 16.0, color: Colors.black),
                      ),
                    ),
                  )
                else if (_isLoading)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _problemsPageController,
                            itemCount: (filteredProblems.length / itemsPerPage).ceil(),
                            onPageChanged: (pageIndex) {
                              if (mounted) {
                                setState(() {
                                  currentPage = pageIndex;
                                });
                              }
                            },
                            itemBuilder: (context, pageIndex) {
                              int startIndex = pageIndex * itemsPerPage;
                              int endIndex = (startIndex + itemsPerPage) > filteredProblems.length
                                  ? filteredProblems.length
                                  : startIndex + itemsPerPage;
                              var pageProblems = filteredProblems.sublist(startIndex, endIndex);

                              return GridView.builder(
                                padding: EdgeInsets.fromLTRB(6.0, 80.0, 6.0, 20.0),
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 6.0,
                                  mainAxisSpacing: 8.0,
                                  childAspectRatio: 2.2,
                                ),
                                itemCount: pageProblems.length,
                                itemBuilder: (context, index) => _buildProblemCard(pageProblems[index]),
                              );
                            },
                          ),
                        ),
                        if (filteredProblems.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.chevron_left),
                                  onPressed: currentPage > 0
                                      ? () {
                                          setState(() {
                                            currentPage--;
                                            _problemsPageController.previousPage(
                                              duration: Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          });
                                        }
                                      : null,
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'Strona ${currentPage + 1} z ${(filteredProblems.length / itemsPerPage).ceil()}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.chevron_right),
                                  onPressed: currentPage < (filteredProblems.length / itemsPerPage).ceil() - 1
                                      ? () {
                                          setState(() {
                                            currentPage++;
                                            _problemsPageController.nextPage(
                                              duration: Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          });
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 37.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Title with counter
                    Row(
                      children: [
                        Text(
                          'Zgłoszenia',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4.0,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFFF49402),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${problems.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    // Search bar
                    Container(
                      width: 250,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => hoverStates['searchBar'] = true),
                        onExit: (_) => setState(() => hoverStates['searchBar'] = false),
                        child: TextField(
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Wyszukaj zgłoszenia...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            prefixIcon: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              child: Icon(
                                Icons.search,
                                color: hoverStates['searchBar'] == true
                                    ? Color(0xFFF49402)
                                    : Colors.grey[600],
                                size: hoverStates['searchBar'] == true ? 24 : 22,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: _filterProblems,
                        ),
                      ),
                    ),
                    if (selectedDate != null)
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.black),
                        onPressed: () {
                          setState(() {
                            selectedDate = null;
                            filteredProblems = problems;
                          });
                        },
                      ),
                    if (selectedCategory != null)
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.black),
                        onPressed: () {
                          setState(() {
                            selectedCategory = null;
                            filteredProblems = List.from(problems);
                            if (_problemsPageController.hasClients) {
                              _problemsPageController.jumpToPage(0);
                            }
                          });
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.calendar_today, color: Colors.black),
                      onPressed: () async {
                        Set<DateTime> availableDates = _getAvailableDates();
                        DateTime initialDate = selectedDate ?? DateTime.now();
                        if (!availableDates.any((availableDate) =>
                            availableDate.year == initialDate.year &&
                            availableDate.month == initialDate.month &&
                            availableDate.day == initialDate.day)) {
                          initialDate = availableDates.first;
                        }

                        DateTime? selectedDateTemp = await showDatePicker(
                          context: context,
                          initialDate: initialDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          selectableDayPredicate: (date) {
                            return availableDates.any((availableDate) =>
                                availableDate.year == date.year &&
                                availableDate.month == date.month &&
                                availableDate.day == date.day);
                          },
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                primaryColor: Colors.black,
                                colorScheme: ColorScheme.light(primary: Colors.black),
                                dialogBackgroundColor: Colors.white,
                              ),
                              child: Column(
                                children: [
                                  Expanded(child: child!),
                                ],
                              ),
                            );
                          },
                        );

                        if (selectedDateTemp != null) {
                          setState(() {
                            selectedDate = selectedDateTemp;
                          });
                          _filterByDate(selectedDate!);
                        }
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.filter_alt, color: Colors.black),
                      tooltip: 'Filtruj po kategorii',
                      color: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      onSelected: (String category) {
                        setState(() {
                          if (category == 'all') {
                            selectedCategory = null;
                            filteredProblems = List.from(problems);
                          } else {
                            selectedCategory = category;
                            filteredProblems = problems.where((problem) =>
                              problem['category'] == category
                            ).toList();
                          }
                          
                          filteredProblems.sort((a, b) =>
                            DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
                          
                          if (_problemsPageController.hasClients) {
                            _problemsPageController.jumpToPage(0);
                          }
                        });
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'hardware',
                          child: Row(
                            children: [
                              Icon(Icons.computer, color: Color(0xFFF49402)),
                              SizedBox(width: 12),
                              Text('Sprzęt'),
                            ],
                            mainAxisSize: MainAxisSize.min,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        PopupMenuItem<String>(
                          value: 'software',
                          child: Row(
                            children: [
                              Icon(Icons.apps, color: Color(0xFFF49402)),
                              SizedBox(width: 12),
                              Text('Oprogramowanie'),
                            ],
                            mainAxisSize: MainAxisSize.min,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        PopupMenuItem<String>(
                          value: 'network',
                          child: Row(
                            children: [
                              Icon(Icons.wifi, color: Color(0xFFF49402)),
                              SizedBox(width: 12),
                              Text('Sieć'),
                            ],
                            mainAxisSize: MainAxisSize.min,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        PopupMenuItem<String>(
                          value: 'printer',
                          child: Row(
                            children: [
                              Icon(Icons.print, color: Color(0xFFF49402)),
                              SizedBox(width: 12),
                              Text('Drukarka'),
                            ],
                            mainAxisSize: MainAxisSize.min,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        PopupMenuItem<String>(
                          value: 'other',
                          child: Row(
                            children: [
                              Icon(Icons.more_horiz, color: Color(0xFFF49402)),
                              SizedBox(width: 12),
                              Text('Inne'),
                            ],
                            mainAxisSize: MainAxisSize.min,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        PopupMenuItem<String>(
                          value: 'all',
                          child: Row(
                            children: [
                              Icon(Icons.clear_all, color: Color(0xFFF49402)),
                              SizedBox(width: 12),
                              Text('Wszystkie'),
                            ],
                            mainAxisSize: MainAxisSize.min,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                    // Priority Filter Button
                    PopupMenuButton<String>(
                      icon: Icon(Icons.priority_high, color: Colors.black),
                      tooltip: 'Filtruj po priorytecie',
                      color: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      onSelected: (String priority) {
                        setState(() {
                          if (priority == 'all') {
                            selectedPriority = null;
                            filteredProblems = List.from(problems);
                          } else {
                            selectedPriority = priority;
                            filteredProblems = problems.where((problem) =>
                              problem['priority'] == priority
                            ).toList();
                          }
                          
                          filteredProblems.sort((a, b) =>
                            DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
                          
                          if (_problemsPageController.hasClients) {
                            _problemsPageController.jumpToPage(0);
                          }
                        });
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'high',
                          child: Row(
                            children: [
                              Icon(Icons.arrow_upward, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Wysoki priorytet'),
                            ],
                            mainAxisSize: MainAxisSize.min,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        PopupMenuItem<String>(
                          value: 'medium',
                          child: Row(
                            children: [
                              Icon(Icons.remove, color: Colors.orange),
                              SizedBox(width: 12),
                              Text('Średni priorytet'),
                            ],
                            mainAxisSize: MainAxisSize.min,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        PopupMenuItem<String>(
                          value: 'low',
                          child: Row(
                            children: [
                              Icon(Icons.arrow_downward, color: Colors.green),
                              SizedBox(width: 12),
                              Text('Niski priorytet'),
                            ],
                            mainAxisSize: MainAxisSize.min,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        PopupMenuItem<String>(
                          value: 'all',
                          child: Row(
                            children: [
                              Icon(Icons.clear_all, color: Color(0xFFF49402)),
                              SizedBox(width: 12),
                              Text('Wszystkie'),
                            ],
                            mainAxisSize: MainAxisSize.min,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return Expanded(
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 25.0),
            child: Column(
              children: [
                if (filteredUsers.isEmpty && !_isLoading)
                  Expanded(
                    child: Center(
                      child: Text(
                        'Brak użytkowników.',
                        style: TextStyle(fontSize: 16.0, color: Colors.black),
                      ),
                    ),
                  )
                else if (_isLoading)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _usersPageController,
                            itemCount: (filteredUsers.length / itemsPerPage).ceil(),
                            onPageChanged: (pageIndex) {
                              if (mounted) {
                                setState(() {
                                  currentPage = pageIndex;
                                });
                              }
                            },
                            itemBuilder: (context, pageIndex) {
                              int startIndex = pageIndex * itemsPerPage;
                              int endIndex = (startIndex + itemsPerPage) > filteredUsers.length
                                  ? filteredUsers.length
                                  : startIndex + itemsPerPage;
                              var pageUsers = filteredUsers.sublist(startIndex, endIndex);

                              return GridView.builder(
                                padding: EdgeInsets.fromLTRB(8.0, 40.0, 8.0, 20.0),
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 8.0,
                                  mainAxisSpacing: 8.0,
                                  childAspectRatio: 1.87,
                                ),
                                itemCount: pageUsers.length,
                                itemBuilder: (context, index) => _buildUserCard(pageUsers[index]),
                              );
                            },
                          ),
                        ),
                        if (filteredUsers.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.chevron_left),
                                  onPressed: currentPage > 0
                                      ? () {
                                          setState(() {
                                            currentPage--;
                                            _usersPageController.previousPage(
                                              duration: Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          });
                                        }
                                      : null,
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'Strona ${currentPage + 1} z ${(filteredUsers.length / itemsPerPage).ceil()}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.chevron_right),
                                  onPressed: currentPage < (filteredUsers.length / itemsPerPage).ceil() - 1
                                      ? () {
                                          setState(() {
                                            currentPage++;
                                            _usersPageController.nextPage(
                                              duration: Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          });
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 45.0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Row(
                  children: [
                    Text(
                      'Zarządzanie użytkownikami',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4.0,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Container(
                      width: 200.0,
                      child: MouseRegion(
                        onEnter: (_) => setState(() => hoverStates['user_search'] = true),
                        onExit: (_) => setState(() => hoverStates['user_search'] = false),
                        child: TextField(
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Wyszukaj...',
                            hintStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.search, color: Colors.black),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: Color(0xFFF49402)),
                            ),
                          ),
                          onChanged: _filterUsersByQuery,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.0),
                    MouseRegion(
                      onEnter: (_) => setState(() => hoverStates['add_user'] = true),
                      onExit: (_) => setState(() => hoverStates['add_user'] = false),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        transform: Matrix4.identity()
                          ..scale(hoverStates['add_user'] == true ? 1.1 : 1.0),
                        child: Tooltip(
                          message: 'Dodaj użytkownika',
                          child: ElevatedButton(
                            onPressed: () {
                              _showAddUserDialog(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(10.0),
                              elevation: hoverStates['add_user'] == true ? 4 : 2,
                            ),
                            child: Icon(
                              Icons.add,
                              size: 20.0,
                              color: Color(0xFFF49402),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _removeNewlines(String text) {
    return text.replaceAll(RegExp(r'(\r\n|\n|\r)'), ' '); // Usuwa nowe linie
  }

  void _filterByDate(DateTime selectedDate) {
    setState(() {
      filteredProblems = problems.where((problem) {
        if (problem['timestamp'] != null) {
          DateTime problemDate = DateTime.parse(problem['timestamp']);
          return problemDate.year == selectedDate.year &&
              problemDate.month == selectedDate.month &&
              problemDate.day == selectedDate.day;
        }
        return false;
      }).toList();

      filteredProblems.sort((a, b) =>
          DateTime.parse(b['timestamp'])
              .compareTo(DateTime.parse(a['timestamp'])));

      currentPage = 0;
      if (_problemsPageController.hasClients) {
        _problemsPageController.jumpToPage(0);
      }
    });
  }

  void _filterProblems(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredProblems = problems;
      } else if (int.tryParse(query) != null) {
        filteredProblems = problems
            .where((problem) =>
            problem['room']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      } else {
        filteredProblems = problems
            .where((problem) =>
            problem['username']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }

      filteredProblems.sort((a, b) =>
          DateTime.parse(b['timestamp'])
              .compareTo(DateTime.parse(a['timestamp'])));

      currentPage = 0;
      if (_problemsPageController.hasClients) {
        _problemsPageController.jumpToPage(0);
      }
    });
  }

  Set<DateTime> _getAvailableDates() {
    Set<DateTime> availableDates = <DateTime>{};

    for (var problem in problems) {
      if (problem['timestamp'] != null) {
        DateTime problemDate = DateTime.parse(problem['timestamp']);
        availableDates.add(
            DateTime(problemDate.year, problemDate.month, problemDate.day));
      }
    }

    return availableDates;
  }

  void _filterUsersByQuery(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = List.from(users);
      } else {
        filteredUsers = users.where((user) {
          final username = user['username']?.toLowerCase() ?? '';
          final role = user['role']?.toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          return username.contains(searchQuery) || role.contains(searchQuery);
        }).toList();
      }

      currentPage = 0;
      if (_usersPageController.hasClients) {
        _usersPageController.jumpToPage(currentPage);
      }
    });
  }

  Widget _buildUserCard(dynamic user) {
    return MouseRegion(
      onEnter: (_) => setState(() => hoverStates['user_${user['username']}'] = true),
      onExit: (_) => setState(() => hoverStates['user_${user['username']}'] = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..scale(hoverStates['user_${user['username']}'] == true ? 1.02 : 1.0),
        child: Card(
          margin: EdgeInsets.symmetric(vertical: 5.0),
          elevation: hoverStates['user_${user['username']}'] == true ? 8 : 4,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(
              color: Color(0xFFF49402).withOpacity(0.3),
              width: 1.0,
            ),
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with username and role badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Username with icon
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.person_outline, 
                              size: 20, 
                              color: Colors.grey[800]
                            ),
                          ),
                          SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _truncateText(user['username'] ?? 'Nieznany użytkownik', 15),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    // Role badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Color(0xFFF49402).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: Color(0xFFF49402).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            user['role'] == 'admin' ? Icons.admin_panel_settings : Icons.person,
                            size: 16,
                            color: Color(0xFFF49402),
                          ),
                          SizedBox(width: 6),
                          Text(
                            user['role'] == 'admin' ? 'Admin' : 'User',
                            style: TextStyle(
                              color: Color(0xFFF49402),
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Edit and Password buttons in a row
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 10,
                            child: _buildActionButton(
                              icon: Icons.edit_outlined,
                              label: 'Edytuj',
                              onPressed: () => _changeUsername(user),
                              compact: true,
                            ),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            flex: 10,
                            child: _buildActionButton(
                              icon: Icons.lock_outline,
                              label: 'Hasło',
                              onPressed: () => _changePassword(user),
                              compact: true,
                            ),
                          ),
                          SizedBox(width: 6),
                          // Delete button
                          _buildActionButton(
                            icon: Icons.delete_outline,
                            label: 'Usuń',
                            isDestructive: true,
                            onPressed: () => _deleteUser(user),
                            compact: true,
                            iconOnly: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
    bool compact = false,
    bool iconOnly = false,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isDestructive ? Colors.red.shade700 : Colors.grey[700],
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: 6,
        ),
        backgroundColor: isDestructive 
          ? Colors.red.shade50 
          : Colors.grey[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: Size(0, 32),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDestructive ? Colors.red.shade700 : Colors.grey[700],
          ),
          if (!iconOnly) ...[
            SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _changeUsername(dynamic user) {
    TextEditingController usernameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.edit_outlined, color: Color(0xFFF49402), size: 24),
              SizedBox(width: 12),
              Text(
                'Zmień login',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aktualny login: ${user['username']}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: usernameController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Nowy login',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFF49402), width: 2),
                  ),
                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[800],
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'Anuluj',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                String newUsername = usernameController.text.trim();
                if (newUsername.isNotEmpty) {
                  try {
                    print('Attempting to change username from ${user['username']} to $newUsername');
                    var response = await http.put(
                      Uri.parse('http://localhost:8080/change_username'),
                      body: json.encode({
                        'username': user['username'],
                        'newUsername': newUsername,
                      }),
                      headers: {
                        'Content-Type': 'application/json',
                      },
                    );

                    print('Response status code: ${response.statusCode}');
                    print('Response body: ${response.body}');

                    if (response.statusCode == 200) {
                      setState(() {
                        filteredUsers = filteredUsers.map((u) {
                          if (u['username'] == user['username']) {
                            u['username'] = newUsername;
                          }
                          return u;
                        }).toList();
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Login został zmieniony pomyślnie'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      Navigator.of(context).pop();
                      _showErrorDialog(context, 'Błąd', 
                        'Nie udało się zmienić loginu. Status: ${response.statusCode}, Odpowiedź: ${response.body}');
                    }
                  } catch (e) {
                    print('Error during username change: $e');
                    Navigator.of(context).pop();
                    _showErrorDialog(context, 'Błąd', 
                      'Wystąpił błąd podczas zmiany loginu: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF49402),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Zapisz',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(width: 8),
          ],
        );
      },
    );
  }

  void _changePassword(dynamic user) {
    TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFFF49402), size: 24),
              SizedBox(width: 12),
              Text(
                'Zmień hasło',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Użytkownik: ${user['username']}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                style: TextStyle(color: Colors.black),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nowe hasło',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFF49402), width: 2),
                  ),
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[800],
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'Anuluj',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                String newPassword = passwordController.text.trim();
                if (newPassword.isNotEmpty) {
                  try {
                    print('Changing password for user: ${user['username']}');
                    var response = await http.put(
                      Uri.parse('http://localhost:8080/change_password_for_user'),
                      body: json.encode({
                        'username': user['username'],
                        'newPassword': newPassword,
                        'role': 'admin',
                      }),
                      headers: {
                        'Content-Type': 'application/json',
                      },
                    );

                    print('Response status code: ${response.statusCode}');
                    print('Response body: ${response.body}');

                    if (response.statusCode == 200) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hasło zostało zmienione pomyślnie'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      Navigator.of(context).pop();
                      _showErrorDialog(context, 'Błąd', 
                        'Nie udało się zmienić hasła. Status: ${response.statusCode}, Odpowiedź: ${response.body}');
                    }
                  } catch (e) {
                    print('Error during password change: $e');
                    Navigator.of(context).pop();
                    _showErrorDialog(context, 'Błąd', 
                      'Wystąpił błąd podczas zmiany hasła: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF49402),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Zapisz',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(width: 8),
          ],
        );
      },
    );
  }

  void _deleteUser(dynamic user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          title: Text(
            'Potwierdź usunięcie',
            style: TextStyle(color: Colors.black),
          ),
          content: Text(
            'Czy na pewno chcesz usunąć użytkownika ${user['username']}?',
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: Text('Anuluj'),
            ),
            TextButton(
              onPressed: () async {
                var response = await http.delete(
                  Uri.parse('http://localhost:8080/delete_user'),
                  headers: {
                    'Content-Type': 'application/json',
                    'role': 'admin',
                  },
                  body: json.encode({
                    'username': user['username'],
                  }),
                );

                if (response.statusCode == 200) {
                  print('Użytkownik został usunięty');
                  setState(() {
                    // Usuwanie użytkownika z listy
                    filteredUsers = filteredUsers.where((u) =>
                    u['username'] !=
                        user['username']).toList();
                  });
                  Navigator.of(context).pop(); // Zamknięcie okna dialogowego
                } else {
                  print('Błąd usuwania użytkownika: ${response.body}');
                  Navigator.of(context).pop(); // Zamknięcie okna dialogowego
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: Text('Usuń'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  final TextEditingController _searchController = TextEditingController();

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'HelpDesk Admin Panel',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              SizedBox(
                height: 80.0,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Helpdesk Admin',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 19.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              MouseRegion(
                onEnter: (_) => setState(() => hoverStates['problems'] = true),
                onExit: (_) => setState(() => hoverStates['problems'] = false),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  color: hoverStates['problems'] == true ? Colors.grey[200] : Colors.transparent,
                  child: ListTile(
                    leading: Icon(Icons.report_problem, color: Colors.black),
                    title: Text('Zgłoszenia', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      setState(() {
                        showProblems = true;
                        showUsers = false;
                        if (_problemsPageController.hasClients) {
                          _problemsPageController.jumpToPage(0);
                        }
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
              MouseRegion(
                onEnter: (_) => setState(() => hoverStates['users'] = true),
                onExit: (_) => setState(() => hoverStates['users'] = false),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  color: hoverStates['users'] == true ? Colors.grey[200] : Colors.transparent,
                  child: ListTile(
                    leading: Icon(Icons.group, color: Colors.black),
                    title: Text('Użytkownicy', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      setState(() {
                        showProblems = false;
                        showUsers = true;
                        if (_usersPageController.hasClients) {
                          _usersPageController.jumpToPage(0);
                        }
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
              MouseRegion(
                onEnter: (_) => setState(() => hoverStates['stats'] = true),
                onExit: (_) => setState(() => hoverStates['stats'] = false),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  color: hoverStates['stats'] == true ? Colors.grey[200] : Colors.transparent,
                  child: ListTile(
                    leading: Icon(Icons.bar_chart, color: Colors.black),
                    title: Text('Statystyki', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StatystykiAdminPage(username: widget.username)),
                      );
                    },
                  ),
                ),
              ),
              MouseRegion(
                onEnter: (_) => setState(() => hoverStates['settings'] = true),
                onExit: (_) => setState(() => hoverStates['settings'] = false),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  color: hoverStates['settings'] == true ? Colors.grey[200] : Colors.transparent,
                  child: ListTile(
                    leading: Icon(Icons.settings, color: Colors.black),
                    title: Text('Ustawienia', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage(username: widget.username)),
                      );
                    },
                  ),
                ),
              ),
              MouseRegion(
                onEnter: (_) => setState(() => hoverStates['logout'] = true),
                onExit: (_) => setState(() => hoverStates['logout'] = false),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  color: hoverStates['logout'] == true ? Colors.grey[200] : Colors.transparent,
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.black),
                    title: Text('Wyloguj się', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => LoginPage()),
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  if (showProblems) _buildProblemList(),
                  if (showUsers) _buildUserList(), // Show users
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    String selectedRole = 'user';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          title: Text(
            'Dodaj użytkownika',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 18.0,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pole na login
              TextField(
                controller: usernameController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Login',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF49402)),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Pole na hasło
              TextField(
                controller: passwordController,
                style: TextStyle(color: Colors.black),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Hasło',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF49402)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            // Przycisk anulowania
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Anuluj',
                style: TextStyle(color: Colors.black),
              ),
            ),
            // Przycisk tworzenia użytkownika
            TextButton(
              onPressed: () {
                final username = usernameController.text;
                final password = passwordController.text;

                // Wywołanie funkcji do tworzenia użytkownika
                _createUser(username, password, selectedRole);
                Navigator.of(context).pop();
              },
              child: Text(
                'Stwórz',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void _createUser(String username, String password, String role) async {
    var newUser = {
      "username": username,
      "password": password,
      "role": role,
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(newUser),
      );

      if (response.statusCode == 201) {
        print("Użytkownik stworzony: ${response.body}");

        setState(() {
          users.add(newUser);
          filteredUsers.add(newUser);
        });

        if (searchQuery.isNotEmpty) {
          _filterUsersByQuery(searchQuery);
        }

      } else {
        final responseBody = json.decode(response.body);
        print("Błąd tworzenia użytkownika: ${responseBody['message']}");
      }
    } catch (e) {
      print("Błąd podczas wysyłania zapytania: $e");
    }
  }

  Widget _buildProblemCard(dynamic problem) {
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

    Color getStatusColor(String? status) {
      switch (status) {
        case 'done':
          return Colors.green;
        case 'in_progress':
          return Colors.orange;
        case 'untouched':
        default:
          return Colors.grey;
      }
    }

    String getStatusText(String? status) {
      switch (status) {
        case 'done':
          return 'Zakończone';
        case 'in_progress':
          return 'W trakcie';
        case 'untouched':
        default:
          return 'Nierozpoczęte';
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => hoverStates['problem_${problem['id']}'] = true),
      onExit: (_) => setState(() => hoverStates['problem_${problem['id']}'] = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..scale(hoverStates['problem_${problem['id']}'] == true ? 1.02 : 1.0),
        child: Card(
          margin: EdgeInsets.symmetric(vertical: 5.0),
          elevation: hoverStates['problem_${problem['id']}'] == true ? 8 : 4,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(
              color: getStatusColor(problem['status']).withOpacity(0.3),
              width: 1.0,
            ),
          ),
          child: Container(
            height: 140,
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.room, size: 16, color: Colors.grey[700]),
                        SizedBox(width: 4),
                        Text(
                          'Sala: ${_truncateText(problem['room'] ?? 'Nieznana', 7)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: getStatusColor(problem['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: getStatusColor(problem['status']).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: getStatusColor(problem['status']),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            getStatusText(problem['status']),
                            style: TextStyle(
                              fontSize: 12,
                              color: getStatusColor(problem['status']),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Expanded(
                  child: Text(
                    _truncateText(_removeNewlines(problem['problem'] ?? 'Brak opisu'), 150),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: getPriorityColor(problem['priority']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag,
                            size: 12,
                            color: getPriorityColor(problem['priority']),
                          ),
                          SizedBox(width: 4),
                          Text(
                            problem['priority'] == 'high' ? 'Wysoki' :
                            problem['priority'] == 'medium' ? 'Średni' : 'Niski',
                            style: TextStyle(
                              fontSize: 12,
                              color: getPriorityColor(problem['priority']),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      getRelativeTime(problem['timestamp']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    final response = await http.put(
                      Uri.parse('http://localhost:8080/mark_as_read/${problem['id']}'),
                    );

                    if (response.statusCode == 200) {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              ProblemTempPage(problem: problem),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            var begin = Offset(1.0, 0.0);
                            var end = Offset.zero;
                            var curve = Curves.easeInOut;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                          transitionDuration: Duration(milliseconds: 300),
                        ),
                      ).then((shouldDelete) {
                        if (shouldDelete == true) {
                          getProblems();
                        }
                      });
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size(0, 32),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Szczegóły',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Color(0xFFF49402),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: currentPage > 0
                ? () {
                    setState(() {
                      currentPage--;
                      _problemsPageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    });
                  }
                : null,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Strona ${currentPage + 1} z $totalPages',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages - 1
                ? () {
                    setState(() {
                      currentPage++;
                      _problemsPageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _showProblemDetails(dynamic problem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String status = problem['status'] ?? 'Nieznany';
        Color statusColor = status == 'Rozwiązane' ? Colors.green : Color(0xFFF49402);
        String formattedDate = '';
        
        if (problem['timestamp'] != null) {
          DateTime timestamp = DateTime.parse(problem['timestamp']);
          formattedDate = '${timestamp.day}.${timestamp.month}.${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Szczegóły zgłoszenia',
                style: TextStyle(color: Colors.black),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sala: ${problem['room'] ?? 'Nieznana'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  'Opis:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  problem['description'] ?? 'Brak opisu',
                  style: TextStyle(color: Colors.black),
                ),
                SizedBox(height: 16.0),
                Text(
                  'Zgłaszający: ${problem['username'] ?? 'Nieznany użytkownik'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Data zgłoszenia: $formattedDate',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: [
            if (status != 'Rozwiązane')
              TextButton(
                onPressed: () async {
                  try {
                    var response = await http.put(
                      Uri.parse('http://localhost:8080/update_problem_status'),
                      headers: {
                        'Content-Type': 'application/json',
                      },
                      body: json.encode({
                        'id': problem['id'],
                        'status': 'Rozwiązane',
                      }),
                    );

                    if (response.statusCode == 200) {
                      setState(() {
                        problem['status'] = 'Rozwiązane';
                        _applyCurrentFilter();
                      });
                      Navigator.of(context).pop();
                    } else {
                      print('Błąd aktualizacji statusu: ${response.body}');
                    }
                  } catch (e) {
                    print('Błąd podczas aktualizacji statusu: $e');
                  }
                },
                child: Text(
                  'Oznacz jako rozwiązane',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Zamknij',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateTicketStatus(int problemId, String newStatus) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/update-status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'problemId': problemId,
          'status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        // Refresh the problems list
        await getProblems();
        setState(() {});
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      print('Error updating status: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update ticket status')),
      );
    }
  }

  Widget buildStatusDropdown(dynamic problem) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButton2<String>(
        value: problem['status'] ?? 'untouched',
        items: ['untouched', 'in_progress', 'done'].map((String status) {
          return DropdownMenuItem<String>(
            value: status,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColors[status],
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  status == 'untouched' ? 'Nierozpoczęte' :
                  status == 'in_progress' ? 'W trakcie' : 'Zakończone',
                  style: TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            updateTicketStatus(problem['id'], newValue);
          }
        },
        buttonStyleData: ButtonStyleData(
          height: 36,
          padding: EdgeInsets.symmetric(horizontal: 8),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 200,
          width: 160,
        ),
      ),
    );
  }
}

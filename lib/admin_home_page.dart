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

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await getProblems();
    await getUsers();

    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (!mounted || _isLoading) return;
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
        var newProblems = jsonDecode(response.body);
        if (mounted && newProblems.toString() != problems.toString()) {
          setState(() {
            problems = newProblems;
            _applyCurrentFilter();
          });
        }
      } else {
        if (mounted) {
          _showErrorDialog(context, 'Błąd serwera', 
            'Nie udało się pobrać danych. Kod błędu: ${response.statusCode}');
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
        print('Error fetching problems: $e');
        _showErrorDialog(context, 'Błąd połączenia', 
          'Wystąpił nieoczekiwany błąd podczas pobierania danych.');
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
      currentPage = 0;
      if (_problemsPageController.hasClients) {
        _problemsPageController.jumpToPage(0);
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
                          padding: EdgeInsets.fromLTRB(8.0, 50.0, 8.0, 20.0),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 1.8,
                          ),
                          itemCount: pageProblems.length,
                          itemBuilder: (context, index) => _buildProblemCard(pageProblems[index]),
                        );
                      },
                    ),
                  ),
                if (filteredProblems.isNotEmpty)
                  _buildPaginationControls((filteredProblems.length / itemsPerPage).ceil()),
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
                    Spacer(),
                    SizedBox(
                      width: 200,
                      child: Padding(
                        padding: EdgeInsets.only(right: 6.0),
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
            margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
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
                          padding: EdgeInsets.fromLTRB(8.0, 50.0, 8.0, 20.0),
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
                  _buildPaginationControls((filteredUsers.length / itemsPerPage).ceil()),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60.0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 37.0),
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
                    SizedBox(
                      width: 200.0,
                      child: MouseRegion(
                        onEnter: (_) => setState(() => hoverStates['user_search'] = true),
                        onExit: (_) => setState(() => hoverStates['user_search'] = false),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(hoverStates['user_search'] == true ? 0.1 : 0.05),
                                blurRadius: hoverStates['user_search'] == true ? 8 : 4,
                                spreadRadius: hoverStates['user_search'] == true ? 1 : 0,
                              ),
                            ],
                          ),
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
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Użytkownik: ${user['username'] ?? 'Nieznany użytkownik'}',
                      style: TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Rola: ${user['role'] ?? 'Brak roli'}',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.black),
                      onPressed: () => _changeUsername(user),
                    ),
                    IconButton(
                      icon: Icon(Icons.lock, color: Colors.black),
                      onPressed: () => _changePassword(user),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.black),
                      onPressed: () => _deleteUser(user),
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



  void _changeUsername(dynamic user) {
    TextEditingController usernameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          title: Text(
            'Zmień login',
            style: TextStyle(color: Colors.black),
          ),
          content: TextField(
            controller: usernameController,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              labelText: 'Nowy login',
              labelStyle: TextStyle(color: Colors.black),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF49402)),
              ),
            ),
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
                String newUsername = usernameController.text.trim();
                if (newUsername.isNotEmpty) {
                  var response = await http.put(
                    Uri.parse('http://localhost:8080/change_username'),
                    body: json.encode({
                      'oldUsername': user['username'],
                      'newUsername': newUsername,
                    }),
                    headers: {
                      'Content-Type': 'application/json',
                      'role': 'admin',
                    },
                  );

                  if (response.statusCode == 200) {
                    print('Login został zmieniony');
                    setState(() {
                      filteredUsers = filteredUsers.map((u) {
                        if (u['username'] == user['username']) {
                          u['username'] = newUsername;
                        }
                        return u;
                      }).toList();
                    });
                    Navigator.of(context).pop();
                  } else {
                    print('Błąd zmiany loginu: ${response.body}');
                    Navigator.of(context).pop();
                  }
                }
              },
              child: Text('Zapisz'),
            ),
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
          title: Text(
            'Zmień hasło',
            style: TextStyle(color: Colors.black),
          ),
          content: TextField(
            controller: passwordController,
            style: TextStyle(color: Colors.black),
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Nowe hasło',
              labelStyle: TextStyle(color: Colors.black),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF49402)),
              ),
            ),
          ),
          actions: <Widget>[
            // Przycisk "Anuluj"
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
            // Przycisk "Zapisz"
            TextButton(
              onPressed: () async {
                String newPassword = passwordController.text.trim();
                if (newPassword.isNotEmpty) {
                  var response = await http.put(
                    Uri.parse('http://localhost:8080/change_password'),
                    body: json.encode({
                      'username': user['username'],
                      'newPassword': newPassword,
                    }),
                    headers: {
                      'Content-Type': 'application/json',
                      'role': 'admin',
                    },
                  );

                  if (response.statusCode == 200) {
                    print('Hasło zostało zmienione');
                    Navigator.of(context).pop();
                  } else {
                    print('Błąd zmiany hasła: ${response.body}');
                    Navigator.of(context).pop();
                  }
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: Text('Zapisz'),
            ),
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
              SizedBox(height: 16),
              // Dropdown dla roli
              DropdownButtonFormField2<String>(
                value: selectedRole,
                items: [
                  DropdownMenuItem(
                    value: 'user',
                    child: Text(
                      'User',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text(
                      'Admin',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
                onChanged: (value) {
                  selectedRole = value!;
                },
                decoration: InputDecoration(
                  labelText: 'Rola',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF49402)),
                  ),
                ),
                buttonStyleData: ButtonStyleData(
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                ),
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 150,
                  offset: Offset(0, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                iconStyleData: IconStyleData(
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black,
                  ),
                ),
              )
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
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sala: ${problem['room'] ?? 'Nieznana'}',
                      style: TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Nauczyciel: ${problem['username'] ?? 'Nieznany'}',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kategoria: ${getCategoryName(problem['category'])}',
                      style: TextStyle(color: Colors.grey),
                      maxLines: 1,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Treść: ${_removeNewlines(problem['problem'] ?? 'Brak opisu')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final response = await http.put(
                          Uri.parse('http://localhost:8080/mark_as_read/${problem['id']}'),
                        );

                        if (response.statusCode == 200) {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => ProblemTempPage(problem: problem),
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
                              setState(() {
                                problems.remove(problem);
                              });
                            }
                          });
                        } else {
                          print('Błąd odczytania wiadomości: ${response.body}');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Nie udało się odczytać wiadomości.'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.black, width: 1),
                        ),
                        minimumSize: Size(120, 36),
                        padding: EdgeInsets.symmetric(horizontal: 5.0),
                      ),
                      child: Text(
                        'Rozwiń',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
}

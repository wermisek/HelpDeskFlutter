// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'settings.dart';
import 'package:http/http.dart' as http;
import 'problemtemp.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

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
      home: AdminHomePage(),
    );
  }
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String searchQuery = '';
  List<dynamic> problems = [];
  List<dynamic> filteredProblems = [];
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  Timer? _refreshTimer;
  bool showUsers = false;
  bool showProblems = true;
  int currentPageNumber = 1;
  final PageController _pageController = PageController();
  int currentPage = 0;
  final int itemsPerPage = 12;
  DateTime? selectedDate;

  Future<void> getProblems() async {
    try {
      var response = await HttpClient().getUrl(
          Uri.parse('http://192.168.10.188:8080/get_problems'));
      var data = await response.close();
      String content = await data.transform(utf8.decoder).join();
      List<dynamic> newProblems = jsonDecode(content);

      if (newProblems != problems) {
        setState(() {
          problems = newProblems;
          filteredProblems = List.from(problems);
        });
      }
    } catch (e) {
      _showErrorDialog(
          context, 'Błąd połączenia', 'Nie udało się pobrać danych z serwera.');
    }
  }

  @override
  void initState() {
    super.initState();

    getProblems().then((_) {
      _resetFilter();
    });

    _refreshTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      getProblems();
      getUsers();
    });
  }

  void _resetFilter() {
    setState(() {
      filteredProblems = List.from(problems);
    });
  }


  Future<void> getUsers() async {
    try {
      var response =
      await HttpClient().getUrl(
          Uri.parse('http://192.168.10.188:8080/get_users'));
      var data = await response.close();
      String content = await data.transform(utf8.decoder).join();
      setState(() {
        users = jsonDecode(content);
      });
    } catch (e) {
      _showErrorDialog(context, 'Błąd połączenia',
          'Nie udało się pobrać danych użytkowników.');
    }
  }


  Widget _buildProblemList() {
    filteredProblems.sort((a, b) =>
        DateTime.parse(b['timestamp'])
            .compareTo(DateTime.parse(a['timestamp'])));

    List<List<dynamic>> paginatedProblems = [];
    for (int i = 0; i < filteredProblems.length; i += itemsPerPage) {
      paginatedProblems.add(filteredProblems.sublist(
        i,
        i + itemsPerPage > filteredProblems.length
            ? filteredProblems.length
            : i + itemsPerPage,
      ));
    }

    return Expanded(
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
            child: Column(
              children: [
                filteredProblems.isEmpty
                    ? Expanded(
                  child: Center(
                    child: Text(
                      'Brak zgłoszeń pasujących do wyszukiwania.',
                      style: TextStyle(fontSize: 16.0, color: Colors.black),
                    ),
                  ),
                )
                    : Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: paginatedProblems.length,
                    onPageChanged: (pageIndex) {
                      setState(() {
                        currentPage = pageIndex;
                      });
                    },
                    itemBuilder: (context, pageIndex) {
                      var pageProblems = paginatedProblems[pageIndex];
                      return GridView.builder(
                        padding: EdgeInsets.fromLTRB(8.0, 50.0, 8.0, 20.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 1.87,
                        ),
                        itemCount: pageProblems.length,
                        itemBuilder: (context, index) {
                          var problem = pageProblems[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 5.0),
                            elevation: 10,
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
                                        'Sala: ${problem['room'] ?? 'Nieznana'}',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Nauczyciel: ${problem['username'] ?? 'Nieznany'}',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    'Treść: ${_removeEmptyLines(problem['problem'] ?? 'Brak opisu')}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProblemTempPage(problem: problem),
                                            ),
                                          );
                                          if (result == true) {
                                            setState(() {
                                              filteredProblems = filteredProblems.where((p) => p['id'] != problem['id']).toList();
                                            });
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
                          );
                        },
                      );
                    },
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
                  ],
                ),
              ),
            ),
          ),

          // Paginacja
          if (filteredProblems.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFFF49402)),
                      onPressed: currentPage > 0
                          ? () {
                        _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                          : null,
                    ),
                    Text(
                      '${currentPage + 1} / ${paginatedProblems.length}',
                      style: TextStyle(fontSize: 14.0, color: Colors.black),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, size: 20, color: Color(0xFFF49402)),
                      onPressed: currentPage < paginatedProblems.length - 1
                          ? () {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _removeEmptyLines(String text) {
    return text.split('\n').where((line) => line.trim().isNotEmpty).join('\n');
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
      _pageController.jumpToPage(0);
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
      _pageController.jumpToPage(0);
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
      _pageController.jumpToPage(currentPage);
    });
  }





  Widget _buildUserList() {
    List<List<dynamic>> paginatedUsers = [];
    for (int i = 0; i < filteredUsers.length; i += itemsPerPage) {
      paginatedUsers.add(filteredUsers.sublist(
        i,
        i + itemsPerPage > filteredUsers.length
            ? filteredUsers.length
            : i + itemsPerPage,
      ));
    }

    return Expanded(
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
            child: Column(
              children: [
                filteredUsers.isEmpty
                    ? Expanded(
                  child: Center(
                    child: Text(
                      'Brak użytkowników.',
                      style: TextStyle(fontSize: 16.0, color: Colors.black),
                    ),
                  ),
                )
                    : Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: paginatedUsers.length,
                    onPageChanged: (pageIndex) {
                      setState(() {
                        currentPage = pageIndex;
                      });
                    },
                    itemBuilder: (context, pageIndex) {
                      var pageUsers = paginatedUsers[pageIndex];
                      return GridView.builder(
                        padding: EdgeInsets.fromLTRB(8.0, 50.0, 8.0, 20.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 1.87,
                        ),
                        itemCount: pageUsers.length,
                        itemBuilder: (context, index) {
                          var user = pageUsers[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 5.0),
                            elevation: 10,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 15.0, vertical: 10.0),
                                  title: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Użytkownik: ${user['username'] ?? 'Nieznany użytkownik'}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600),
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Tooltip(
                                        message: 'Zmień login',
                                        child: IconButton(
                                          icon: Icon(
                                              Icons.edit,
                                              color: Colors.black),
                                          onPressed: () {
                                            _changeUsername(user);
                                          },
                                        ),
                                      ),
                                      Tooltip(
                                        message: 'Zmień hasło',
                                        child: IconButton(
                                          icon: Icon(
                                              Icons.lock,
                                              color: Colors.black),
                                          onPressed: () {
                                            _changePassword(user);
                                          },
                                        ),
                                      ),
                                      Tooltip(
                                        message: 'Usuń użytkownika',
                                        child: IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.black),
                                          onPressed: () {
                                            _deleteUser(user);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
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
                    SizedBox(width: 10.0),
                    Tooltip(
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
                        ),
                        child: Icon(Icons.add, size: 20.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Paginacja
          if (filteredUsers.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 25.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, size: 20,
                          color: Color(0xFFF49402)),
                      onPressed: currentPage > 0
                          ? () {
                        _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                          : null,
                    ),
                    Text(
                      '${currentPage + 1} / ${paginatedUsers.length}',
                      style: TextStyle(fontSize: 14.0, color: Colors.black),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, size: 20,
                          color: Color(0xFFF49402)),
                      onPressed: currentPage < paginatedUsers.length - 1
                          ? () {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
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
                    Uri.parse('http://192.168.10.188:8080/change_username'),
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
                    Uri.parse('http://192.168.10.188:8080/change_password'),
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
                padding: EdgeInsets.symmetric(
                    vertical: 12, horizontal: 24),
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
                  Uri.parse('http://192.168.10.188:8080/delete_user'),
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
  void dispose() {
    _refreshTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
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
                      SizedBox(height: 6.0),
                      Divider(
                        color: Color(0xFFF49402),
                        thickness: 1.0,
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.report_problem, color: Colors.black),
                title: Text('Zgłoszenia', style: TextStyle(color: Colors.black)),
                onTap: () {
                  setState(() {
                    showProblems = true;
                    showUsers = false;
                    currentPage = 0;
                    _pageController.jumpToPage(0);
                    searchQuery = '';
                    filteredProblems = problems;
                  });

                  Navigator.pop(context); // Zamknij Drawer
                },
              ),
              ListTile(
                leading: Icon(Icons.group, color: Colors.black),
                title: Text('Użytkownicy', style: TextStyle(color: Colors.black)),
                onTap: () {
                  setState(() {
                    showProblems = false;
                    showUsers = true;
                    currentPage = 0;
                    _pageController.jumpToPage(0);
                    searchQuery = '';
                    filteredUsers = List.from(users);
                  });

                  Navigator.pop(context);

                },
              ),
              ListTile(
                leading: Icon(Icons.settings, color: Colors.black),
                title: Text('Ustawienia', style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                },
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
                  if (showUsers) _buildUserList(),
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
                    borderRadius: BorderRadius.circular(
                        5.0),
                  ),
                  overlayColor: WidgetStateProperty.all(
                      Colors.transparent),
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
        Uri.parse('http://192.168.10.188:8080/register'),
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
}


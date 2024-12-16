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
  late String currentUsername;
  Map<String, bool> hoverStates = {};

  Future<void> getProblems() async {
    try {
      var response = await HttpClient().getUrl(Uri.parse('http://localhost:8080/get_problems'));
      var data = await response.close();
      String content = await data.transform(utf8.decoder).join();
      var newProblems = jsonDecode(content);

      if (newProblems.toString() != problems.toString()) {
        setState(() {
          problems = newProblems;
          _applyCurrentFilter(); // Zastosuj bieżący filtr po aktualizacji danych
        });
      }
    } catch (e) {
      _showErrorDialog(context, 'Błąd połączenia', 'Nie udało się pobrać danych z serwera.');
    }
  }




  void _applyCurrentFilter() {
    if (searchQuery.isNotEmpty) {
      _filterProblems(searchQuery); // Ponownie filtruj na podstawie wyszukiwania
    } else if (selectedDate != null) {
      _filterByDate(selectedDate!); // Filtruj według wybranej daty
    } else {
      filteredProblems = List.from(problems); // Domyślna lista
    }
  }





  @override
  void initState() {
    super.initState();

    const base64Image = 'data:image/png;base64,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'; // existing code
    decodedImage = base64Decode(base64Image.split(',').last);

    getProblems().then((_) => _applyCurrentFilter());
    getUsers().then((_) {
      setState(() {
        filteredUsers = List.from(users);
      });
    });

    // Replace the existing timer with this updated version
    _refreshTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      getProblems().then((_) {
        setState(() {
          _applyCurrentFilter(); // Apply current filter after refresh
        });
      });
      getUsers();
    });
  }

  void _initializeProblems() {
    setState(() {
      problems.sort((a, b) =>
          DateTime.parse(b['timestamp'])
              .compareTo(DateTime.parse(a['timestamp'])));
      filteredProblems = List.from(problems);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilter() {
    setState(() {
      filteredProblems = problems;
    });
  }



  Future<void> getUsers() async {
    try {
      var response =
      await HttpClient().getUrl(Uri.parse('http://localhost:8080/get_users'));
      var data = await response.close();
      String content = await data.transform(utf8.decoder).join();
      setState(() {
        users = jsonDecode(content);
      });
    } catch (e) {
      _showErrorDialog(
          context, 'Błąd połączenia', 'Nie udało się pobrać danych użytkowników.');
    }
  }

  Widget _buildProblemList() {
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
                          itemCount: (filteredProblems.length / itemsPerPage).ceil(),
                    onPageChanged: (pageIndex) {
                      setState(() {
                        currentPage = pageIndex;
                      });
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
                                childAspectRatio: 1.9,
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
                          itemCount: (filteredUsers.length / itemsPerPage).ceil(),
                          onPageChanged: (pageIndex) {
                            setState(() {
                              currentPage = pageIndex;
                            });
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HelpDesk Admin Panel',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(6.0), // Rounded corners
              child: SizedBox(
                width: 40.0, // Set the width of the image box
                height: 40.0, // Set the height of the image box
                child: Image.memory(
                  decodedImage, // Użyj statycznie przechowywanego obrazu
                  fit: BoxFit.cover, // Ensures the image fits without distortion
                ),
              ),
            ),
          ],
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
                        indent: 0,
                        endIndent: 0,
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
                    _pageController.jumpToPage(0);
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.group, color: Colors.black),
                title: Text('Użytkownicy', style: TextStyle(color: Colors.black)),
                onTap: () {
                  setState(() {
                    showProblems = false;
                    showUsers = true;
                    _pageController.jumpToPage(0);
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
                    MaterialPageRoute(builder: (context) => SettingsPage(username: widget.username)),
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
                      maxLines: 1,
                    ),
                  ],
                ),
                subtitle: Text(
                  'Treść: ${_removeNewlines(problem['problem'] ?? 'Brak opisu')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
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
                      _pageController.previousPage(
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
                      _pageController.nextPage(
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

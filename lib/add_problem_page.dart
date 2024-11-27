import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'settings.dart';
import 'package:http/http.dart' as http;


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UserHomePage(username: 'TestUser'),
    );
  }
}

class UserHomePage extends StatefulWidget {
  final String username;

  const UserHomePage({super.key, required this.username});

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

enum CurrentView { home, myProblems }

class _UserHomePageState extends State<UserHomePage> {
  final _teacherController = TextEditingController(
      text: 'Wypełnione automatycznie');
  final _roomController = TextEditingController();
  final _problemController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  CurrentView currentView = CurrentView.home;
  final int itemsPerPage = 12;
  PageController _pageController = PageController();
  int currentPage = 0;
  List<dynamic> problems = [];


  @override
  void initState() {
    super.initState();
    _fetchUserProblems();
  }

  void _fetchUserProblems() async {
    try {
      final response = await HttpClient().getUrl(
          Uri.parse('http://192.168.10.188:8080/get_problems/'));
      final data = await response.close();
      String content = await data.transform(utf8.decoder).join();

      // Debug log, żeby sprawdzić odpowiedź serwera
      print("Response from server: $content");

      // Przekształcamy odpowiedź na listę problemów
      List<dynamic> allProblems = jsonDecode(content);

      // Sprawdzamy zawartość
      print("All Problems: $allProblems");

      // Filtrowanie problemów dla bieżącego użytkownika
      List<dynamic> userProblems = allProblems.where((problem) {
        return problem['username'] ==
            widget.username; // Filtrowanie po nazwie użytkownika
      }).toList();

      // Debug log, żeby sprawdzić, czy filtracja działa poprawnie
      print("Filtered Problems: $userProblems");

      setState(() {
        problems = userProblems; // Przypisanie problemów użytkownika
      });
    } catch (e) {
      _showDialog(context, title: 'Błąd połączenia',
          message: 'Nie udało się połączyć z serwerem.');
    }
  }

  void _switchView(CurrentView view) {
    setState(() {
      currentView = view;
    });
  }

  Future<void> _submitProblem(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      String room = _roomController.text;
      String problem = _problemController.text;

      Map<String, dynamic> problemData = {
        'username': widget.username,
        'room': room,
        'problem': problem,
        'read': 0,
      };

      try {
        final request = await HttpClient().postUrl(
            Uri.parse('http://192.168.10.188:8080/add_problem'));
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(problemData));

        final response = await request.close();

        if (response.statusCode == 201) {
          _showDialog(context, title: 'Problem wysłany',
              message: 'Dziękujemy, ${widget
                  .username}. Twój problem został przesłany.');
          _fetchUserProblems(); // Refresh problems after submission
        } else {
          _showDialog(context, title: 'Błąd',
              message: 'Nie udało się wysłać problemu. Serwer zwrócił: ${response
                  .reasonPhrase}');
        }
      } catch (e) {
        _showDialog(context, title: 'Błąd połączenia',
            message: 'Nie udało się połączyć z serwerem. Sprawdź połączenie sieciowe.');
      }
    }
  }

  void _showDialog(BuildContext context,
      {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(title, style: TextStyle(color: Colors.black)),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool isTeacherField = false,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.black),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          hoverColor: Colors.transparent,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        style: TextStyle(
          color: isTeacherField && controller.text.isNotEmpty
              ? Colors.grey
              : Colors.black,
        ),
        validator: validator,
        onChanged: (text) {
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentView == CurrentView.home
              ? 'HelpDesk Strona Główna'
              : 'Moje Problemy',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        bottom: currentView == CurrentView.myProblems
            ? PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            color: Color(0xFF8A8A8A),  // Kolor dopasowany do aplikacji
            thickness: 1.0,  // Grubość tak jak w zakładce wysyłania zgłoszenia
            height: 1.0,
          ),
        )
            : null,
      ),
      body: currentView == CurrentView.home
          ? _buildHomeView()
          : _buildMyProblemsView(),
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
                        'Helpdesk Drzewniak',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 19.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6.0),
                      Divider(
                        color: Color(0xFF8A8A8A),  // Kolor dopasowany do aplikacji
                        thickness: 1.0,  // Grubość identyczna jak w zakładce wysyłania zgłoszenia
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.report_problem, color: Colors.black),
                title: Text(
                    'Dodaj problem', style: TextStyle(color: Colors.black)),
                onTap: () {
                  _switchView(CurrentView.home);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.group, color: Colors.black),
                title: Text(
                    'Moje problemy', style: TextStyle(color: Colors.black)),
                onTap: () {
                  _switchView(CurrentView.myProblems);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.settings, color: Colors.black),
                title: Text(
                    'Ustawienia', style: TextStyle(color: Colors.black)),
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
    );
  }

  Widget _buildHomeView() {
    return Column(
      children: [
        Divider(
          color: Color(0xFF8A8A8A), // Kolor dopasowany do aplikacji
          thickness: 1.0,  // Grubość identyczna jak w zakładce wysyłania zgłoszenia
          height: 1.0,
        ),
        Expanded(
          child: Container(
            color: Colors.white,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Zgłoś problem',
                        style: TextStyle(fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 120.0, bottom: 20),
                              child: SizedBox(
                                height: 90.0,
                                child: _buildInputField(
                                  controller: _teacherController,
                                  labelText: 'Nauczyciel',
                                  enabled: false,
                                  isTeacherField: true,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  right: 120.0, left: 30, bottom: 20),
                              child: SizedBox(
                                height: 90.0,
                                child: _buildInputField(
                                  controller: _roomController,
                                  labelText: 'Sala',
                                  maxLines: 2,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Wprowadź nazwę Sali';
                                    }
                                    return null;
                                  },
                                  maxLength: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      FractionallySizedBox(
                        widthFactor: 0.8,
                        child: SizedBox(
                          height: 160.0,
                          child: _buildInputField(
                            controller: _problemController,
                            labelText: 'Opis problemu',
                            maxLines: 5,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Wprowadź opis problemu';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      Padding(
                        padding: const EdgeInsets.only(top: 50.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 310,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: () => _submitProblem(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  foregroundColor: Colors.black,
                                  elevation: 2.0,
                                ),
                                child: Text(
                                  'Wyślij',
                                  style: TextStyle(fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyProblemsView() {
    List<List<dynamic>> paginatedProblems = [];
    for (int i = 0; i < problems.length; i += itemsPerPage) {
      paginatedProblems.add(problems.sublist(i,
          i + itemsPerPage > problems.length ? problems.length : i +
              itemsPerPage));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
        child: paginatedProblems.isEmpty
            ? Center(
          child: Text(
            'Brak zgłoszeń.',
            style: TextStyle(fontSize: 16.0, color: Colors.black),
          ),
        )
            : Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              ],
            ),
            SizedBox(height: 10.0),
            Expanded(
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
                    padding: EdgeInsets.symmetric(vertical: 3.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 1.9,
                    ),
                    itemCount: pageProblems.length,
                    itemBuilder: (context, index) {
                      var problem = pageProblems[index];
                      return IntrinsicHeight(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: Offset(-3, 0),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: Offset(3, 0),
                              ),
                            ],
                          ),
                          margin: EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 10.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sala: ${problem['room'] ?? 'Nieznana'}',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Nauczyciel: ${problem['username'] ??
                                      'Nieznany'}',
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 14),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Treść: ${problem['problem'] ??
                                      'Brak opisu'}',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.only(top: 15.0),
                                  child: Center(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final response = await http.put(
                                          Uri.parse(
                                              'http://192.168.10.188:8080/mark_as_read/${problem['id']}'),
                                        );

                                        if (response.statusCode == 200) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProblemTempPage(
                                                      problem: problem),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Nie udało się oznaczyć zgłoszenia jako przeczytane.'),
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              20),
                                          side: BorderSide(
                                              color: Colors.black, width: 1),
                                        ),
                                        minimumSize: Size(120, 36),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20.0),
                                      ),
                                      child: Text(
                                        'Rozwiń',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                        Icons.arrow_back_ios, size: 20, color: Colors.black),
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
                    icon: Icon(
                        Icons.arrow_forward_ios, size: 20, color: Colors.black),
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
          ],
        ),
      ),
    );
  }
  }

  class ProblemTempPage extends StatelessWidget {
  final dynamic problem;

  ProblemTempPage({required this.problem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Problem Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Problem ID: ${problem['id']}'),
            Text('Room: ${problem['room']}'),
            Text('Description: ${problem['problem']}'),
          ],
        ),
      ),
    );
  }
}






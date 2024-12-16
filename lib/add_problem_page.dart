// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'settings.dart';
import 'package:http/http.dart' as http;
import 'usertempp.dart';
import 'dart:async';


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
  // ignore: library_private_types_in_public_api
  _UserHomePageState createState() => _UserHomePageState();
}

enum CurrentView { home, myProblems }

class _UserHomePageState extends State<UserHomePage> {
  final _teacherController = TextEditingController();
  final _roomController = TextEditingController();
  final _problemController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  CurrentView currentView = CurrentView.home;
  final int itemsPerPage = 12;
  final PageController _pageController = PageController();
  int currentPage = 0;
  List<dynamic> problems = [];
  bool isLoading = false;
  Timer? _timer;
  Map<String, bool> hoverStates = {};

  @override
  void initState() {
    super.initState();
    _fetchUserProblems();
    _teacherController.text = widget.username;

    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        _fetchUserProblems();
      }
    });
  }

  // Odświeżenie danych
  Future<void> _fetchUserProblems() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      
      final request = await client
          .getUrl(Uri.parse('http://localhost:8080/get_problems'))
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('The connection has timed out');
            },
          );

      final response = await request.close().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('The request has timed out');
        },
      );

      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        List<dynamic> fetchedProblems = List<dynamic>.from(json.decode(responseBody));
        List<dynamic> userProblems = fetchedProblems
            .where((problem) => problem['username'] == widget.username)
            .toList();

        // Sort problems by timestamp, newest first
        userProblems.sort((a, b) =>
            DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp']))
        );

        if (userProblems.toString() != problems.toString()) {
          setState(() {
            problems = userProblems;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorSnackBar('Błąd pobierania danych: ${_getErrorMessage(response.statusCode, responseBody)}');
      }
    } on TimeoutException {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Przekroczono limit czasu połączenia');
    } on SocketException {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Nie można połączyć się z serwerem');
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Wystąpił nieoczekiwany błąd: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _teacherController.dispose();
    _roomController.dispose();
    _problemController.dispose();
    _pageController.dispose();
    super.dispose();
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
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        
        final request = await client
            .postUrl(Uri.parse('http://localhost:8080/add_problem'))
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('The connection has timed out');
              },
            );
            
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(problemData));

        final response = await request.close().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('The request has timed out');
          },
        );

        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 201) {
          _showDialog(
            context,
            title: 'Problem wysłany',
            message: 'Dziękujemy, ${widget.username}. Twój problem został przesłany.',
          );
          _fetchUserProblems();
          // Clear form after successful submission
          _roomController.clear();
          _problemController.clear();
        } else {
          _showDialog(
            context,
            title: 'Błąd',
            message: 'Nie udało się wysłać problemu. ${_getErrorMessage(response.statusCode, responseBody)}',
          );
        }
      } on TimeoutException {
        _showDialog(
          context,
          title: 'Błąd połączenia',
          message: 'Przekroczono limit czasu połączenia. Spróbuj ponownie później.',
        );
      } on SocketException {
        _showDialog(
          context,
          title: 'Błąd połączenia',
          message: 'Nie można połączyć się z serwerem. Sprawdź połączenie sieciowe.',
        );
      } catch (e) {
        _showDialog(
          context,
          title: 'Błąd',
          message: 'Wystąpił nieoczekiwany błąd: ${e.toString()}',
        );
      }
    }
  }

  String _getErrorMessage(int statusCode, String responseBody) {
    try {
      final Map<String, dynamic> response = jsonDecode(responseBody);
      return response['message'] ?? 'Unknown error';
    } catch (e) {
      switch (statusCode) {
        case 400:
          return 'Nieprawidłowe dane';
        case 401:
          return 'Brak autoryzacji';
        case 403:
          return 'Brak dostępu';
        case 404:
          return 'Nie znaleziono zasobu';
        case 500:
          return 'Błąd serwera';
        default:
          return 'Nieznany błąd (kod: $statusCode)';
      }
    }
  }

  void _showDialog(BuildContext context, {required String title, required String message}) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionBuilder: (context, animation1, animation2, child) {
        return FadeTransition(
          opacity: animation1,
          child: ScaleTransition(
            scale: animation1,
            child: AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                title,
                style: TextStyle(color: Colors.black),
              ),
              content: Text(
                message,
                style: TextStyle(color: Colors.black),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'OK',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 300),
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
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
            color: Color(0xFFF49402),
            thickness: 1.0,
            height: 1.0,
          ),
        )
            : null,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: '',
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
                        'Helpdesk Drzewniak',
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
              MouseRegion(
                onEnter: (_) => setState(() => hoverStates['problem'] = true),
                onExit: (_) => setState(() => hoverStates['problem'] = false),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  color: hoverStates['problem'] == true ? Colors.grey[200] : Colors.transparent,
                  child: ListTile(
                    leading: Icon(Icons.report_problem, color: Colors.black),
                    title: Text('Dodaj problem', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      _switchView(CurrentView.home);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
              MouseRegion(
                onEnter: (_) => setState(() => hoverStates['myProblems'] = true),
                onExit: (_) => setState(() => hoverStates['myProblems'] = false),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  color: hoverStates['myProblems'] == true ? Colors.grey[200] : Colors.transparent,
                  child: ListTile(
                    leading: Icon(Icons.group, color: Colors.black),
                    title: Text('Moje problemy', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      _switchView(CurrentView.myProblems);
                      setState(() {
                        currentPage = 0;
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
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => SettingsPage(username: widget.username),
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
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: currentView == CurrentView.home
            ? _buildHomeView()
            : _buildMyProblemsView(),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0.1, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeView() {
    return Column(
      children: [
        Divider(
          color: Color(0xFFF49402),
          thickness: 1.0,
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
                      SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 120.0, bottom: 20),
                              child: SizedBox(
                                height: 90.0,
                                child: MouseRegion(
                                  onEnter: (_) => setState(() => hoverStates['teacher'] = true),
                                  onExit: (_) => setState(() => hoverStates['teacher'] = false),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(hoverStates['teacher'] == true ? 0.6 : 0.5),
                                          offset: Offset(0, hoverStates['teacher'] == true ? 4 : 2),
                                          blurRadius: hoverStates['teacher'] == true ? 8 : 4,
                                        ),
                                      ],
                                    ),
                                    child: _buildInputField(
                                      controller: _teacherController,
                                      labelText: 'Nauczyciel',
                                      enabled: false,
                                      isTeacherField: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 120.0, left: 30, bottom: 20),
                              child: SizedBox(
                                height: 90.0,
                                child: MouseRegion(
                                  onEnter: (_) => setState(() => hoverStates['room'] = true),
                                  onExit: (_) => setState(() => hoverStates['room'] = false),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(hoverStates['room'] == true ? 0.6 : 0.5),
                                          offset: Offset(0, hoverStates['room'] == true ? 4 : 2),
                                          blurRadius: hoverStates['room'] == true ? 8 : 4,
                                        ),
                                      ],
                                    ),
                                    child: _buildInputField(
                                      controller: _roomController,
                                      labelText: 'Sala',
                                      maxLines: 1,
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
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      FractionallySizedBox(
                        widthFactor: 0.8,
                        child: SizedBox(
                          height: 160.0,
                          child: MouseRegion(
                            onEnter: (_) => setState(() => hoverStates['problem'] = true),
                            onExit: (_) => setState(() => hoverStates['problem'] = false),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(hoverStates['problem'] == true ? 0.6 : 0.5),
                                    offset: Offset(0, hoverStates['problem'] == true ? 4 : 2),
                                    blurRadius: hoverStates['problem'] == true ? 8 : 4,
                                  ),
                                ],
                              ),
                              child: _buildInputField(
                                controller: _problemController,
                                labelText: 'Opis problemu',
                                maxLines: 5,
                                maxLength: 275,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Wprowadź opis problemu';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      Padding(
                        padding: const EdgeInsets.only(top: 50.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            MouseRegion(
                              onEnter: (_) => setState(() => hoverStates['submit'] = true),
                              onExit: (_) => setState(() => hoverStates['submit'] = false),
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                child: SizedBox(
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
                                      elevation: hoverStates['submit'] == true ? 4.0 : 2.0,
                                    ),
                                    child: Text(
                                      'Wyślij',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: hoverStates['submit'] == true
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
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
      paginatedProblems.add(problems.sublist(
          i, i + itemsPerPage > problems.length ? problems.length : i + itemsPerPage));
    }

    if (isLoading) {
      return Center(child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF49402)),
      ));
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
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
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
                      bool isRead = problem['read'] == 1;
                      String cardKey = 'card_${problem['id']}';

                      return MouseRegion(
                        onEnter: (_) => setState(() => hoverStates[cardKey] = true),
                        onExit: (_) => setState(() => hoverStates[cardKey] = false),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(hoverStates[cardKey] == true ? 0.15 : 0.1),
                                blurRadius: hoverStates[cardKey] == true ? 15 : 10,
                                spreadRadius: hoverStates[cardKey] == true ? 1 : 0,
                                offset: Offset(-3, 0),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(hoverStates[cardKey] == true ? 0.15 : 0.1),
                                blurRadius: hoverStates[cardKey] == true ? 15 : 10,
                                spreadRadius: hoverStates[cardKey] == true ? 1 : 0,
                                offset: Offset(3, 0),
                              ),
                            ],
                          ),
                          margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Sala: ${problem['room'] ?? 'Nieznana'}',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration: Duration(milliseconds: 200),
                                      child: Icon(
                                        isRead ? Icons.visibility : Icons.visibility_off,
                                        key: ValueKey<bool>(isRead),
                                        color: isRead ? Colors.green : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Nauczyciel: ${problem['username'] ??
                                      'Nieznany'}',
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 14),
                                ),
                                SizedBox(height: 4),
                                Flexible(
                                  child: Text(
                                    'Treść: ${problem['problem'] ?? 'Brak opisu'}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.only(top: 15.0),
                                  child: Center(
                                    child: MouseRegion(
                                      onEnter: (_) => setState(() => hoverStates['expand_${problem['id']}'] = true),
                                      onExit: (_) => setState(() => hoverStates['expand_${problem['id']}'] = false),
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 200),
                                        transform: Matrix4.identity()
                                          ..scale(hoverStates['expand_${problem['id']}'] == true ? 1.05 : 1.0),
                                        child: ElevatedButton(
                                          onPressed: () async {
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
                                            ).then((deleted) {
                                              if (deleted == true) {
                                                _fetchUserProblems();
                                              }
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                              side: BorderSide(
                                                color: Colors.black,
                                                width: hoverStates['expand_${problem['id']}'] == true ? 1.5 : 1,
                                              ),
                                            ),
                                            minimumSize: Size(120, 36),
                                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                                            elevation: hoverStates['expand_${problem['id']}'] == true ? 4 : 2,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Rozwiń',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: hoverStates['expand_${problem['id']}'] == true
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(
                                                Icons.arrow_forward,
                                                size: 18,
                                                color: Colors.black,
                                              ),
                                            ],
                                          ),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MouseRegion(
                    onEnter: (_) => setState(() => hoverStates['prev_page'] = true),
                    onExit: (_) => setState(() => hoverStates['prev_page'] = false),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      transform: Matrix4.identity()
                        ..translate(hoverStates['prev_page'] == true ? -2.0 : 0.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          size: 20,
                          color: currentPage > 0 ? Color(0xFFF49402) : Colors.grey,
                        ),
                        onPressed: currentPage > 0
                            ? () {
                                _pageController.previousPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: AnimatedDefaultTextStyle(
                      duration: Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      child: Text(
                        '${currentPage + 1} / ${paginatedProblems.length}',
                      ),
                    ),
                  ),
                  MouseRegion(
                    onEnter: (_) => setState(() => hoverStates['next_page'] = true),
                    onExit: (_) => setState(() => hoverStates['next_page'] = false),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      transform: Matrix4.identity()
                        ..translate(hoverStates['next_page'] == true ? 2.0 : 0.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: currentPage < paginatedProblems.length - 1 ? Color(0xFFF49402) : Colors.grey,
                        ),
                        onPressed: currentPage < paginatedProblems.length - 1
                            ? () {
                                _pageController.nextPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                      ),
                    ),
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
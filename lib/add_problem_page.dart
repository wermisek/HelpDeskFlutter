// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'settings.dart';
import 'package:http/http.dart' as http;
import 'usertempp.dart';
import 'dart:async';
import 'login.dart';

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
  bool _isFetching = false;
  List<dynamic> get filteredProblems => problems;
  String? selectedCategory;
  String? selectedRoom;
  bool isManualRoomInput = false;
  String? selectedPriority;
   
  final List<Map<String, dynamic>> categories = [
    {'id': 'hardware', 'name': 'Sprzęt', 'icon': Icons.computer},
    {'id': 'software', 'name': 'Oprogramowanie', 'icon': Icons.apps},
    {'id': 'network', 'name': 'Sieć', 'icon': Icons.wifi},
    {'id': 'printer', 'name': 'Drukarka', 'icon': Icons.print},
    {'id': 'other', 'name': 'Inne', 'icon': Icons.more_horiz},
  ];

  final List<String> rooms = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10',
    '11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
    '21', '22', '23', '24', '25', '26', '27', '28', '29', '30',
    '31', '32', '33', '34', '35', '36', '37', '38', '39', '40',
    'Sala gimnastyczna', 'Biblioteka', 'Świetlica', 'Aula'
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProblems();
    _teacherController.text = widget.username;

    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted && !_isFetching) {
        _fetchUserProblems();
      }
    });
  }

  Future<void> _fetchUserProblems() async {
    if (!mounted || _isFetching) return;
    _isFetching = true;

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      
      final request = await client
          .getUrl(Uri.parse('http://localhost:8080/get_problems'))
          .timeout(Duration(seconds: 30));

      final response = await request.close().timeout(Duration(seconds: 30));
      final responseBody = await response.transform(utf8.decoder).join();

      if (!mounted) return;

      if (response.statusCode == 200) {
        List<dynamic> fetchedProblems = List<dynamic>.from(json.decode(responseBody))
            .where((problem) => problem['username'] == widget.username)
            .toList()
          ..sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));

        if (mounted && fetchedProblems.toString() != problems.toString()) {
          setState(() {
            problems = fetchedProblems;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('Błąd pobierania danych: ${_getErrorMessage(response.statusCode, responseBody)}');
        }
      }
    } catch (e) {
      if (mounted) {
        if (e is TimeoutException) {
          _showErrorSnackBar('Przekroczono limit czasu połączenia');
        } else if (e is SocketException) {
          _showErrorSnackBar('Nie można połączyć się z serwerem');
        } else {
          _showErrorSnackBar('Wystąpił nieoczekiwany błąd: ${e.toString()}');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      _isFetching = false;
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
        'category': selectedCategory ?? 'other',
        'priority': selectedPriority ?? 'low',
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
          setState(() {
            selectedCategory = null;
            selectedRoom = null;
          });
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
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        maxLength: maxLength,
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
          if (maxLength == null) return null;
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(
              '$currentLength/$maxLength',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          );
        },
        style: TextStyle(
          color: isTeacherField ? Colors.grey[700] : Colors.black87,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.red[400]!, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.red[400]!, width: 1),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          errorStyle: TextStyle(
            color: Colors.red[400],
            fontSize: 12,
          ),
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
            color: Colors.grey[50],
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Zgłoś problem',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 80.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, 
                              size: 18, 
                              color: Color(0xFFF49402)
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Informacje podstawowe',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.0),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 0,
                                blurRadius: 20,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _teacherController,
                                        enabled: false,
                                        decoration: InputDecoration(
                                          labelText: 'Nauczyciel',
                                          alignLabelWithHint: true,
                                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                            borderSide: BorderSide(color: Color(0xFFF49402), width: 2),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                            borderSide: BorderSide(color: Colors.red[400]!, width: 1),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                            borderSide: BorderSide(color: Colors.red[400]!, width: 1),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          contentPadding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                                          labelStyle: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          floatingLabelStyle: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          counterText: '',
                                        ),
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16.0),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _roomController,
                                        decoration: InputDecoration(
                                          labelText: 'Sala',
                                          alignLabelWithHint: true,
                                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                            borderSide: BorderSide(color: Color(0xFFF49402), width: 2),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                            borderSide: BorderSide(color: Colors.red[400]!, width: 1),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                            borderSide: BorderSide(color: Colors.red[400]!, width: 1),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                                          labelStyle: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          floatingLabelStyle: TextStyle(
                                            color: _roomController.selection.isValid ? Color(0xFFF49402) : Colors.grey[600],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          counterText: '',
                                        ),
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'Wprowadź nazwę Sali';
                                          }
                                          return null;
                                        },
                                        maxLength: 15,
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          value: selectedCategory,
                                          decoration: InputDecoration(
                                            labelText: 'Kategoria problemu',
                                            alignLabelWithHint: true,
                                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12.0),
                                              borderSide: BorderSide(color: Colors.grey[300]!),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12.0),
                                              borderSide: BorderSide(color: Colors.grey[300]!),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12.0),
                                              borderSide: BorderSide(color: Color(0xFFF49402), width: 2),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12.0),
                                              borderSide: BorderSide(color: Colors.red[400]!, width: 1),
                                            ),
                                            focusedErrorBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12.0),
                                              borderSide: BorderSide(color: Colors.red[400]!, width: 1),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                                            labelStyle: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            floatingLabelStyle: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 15,
                                          ),
                                          icon: Icon(Icons.arrow_drop_down, color: Color(0xFFF49402)),
                                          isExpanded: true,
                                          dropdownColor: Colors.white,
                                          validator: (value) {
                                            if (value == null) {
                                              return 'Wybierz kategorię';
                                            }
                                            return null;
                                          },
                                          items: categories.map((category) {
                                            return DropdownMenuItem<String>(
                                              value: category['id'],
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      category['icon'],
                                                      size: 20,
                                                      color: Color(0xFFF49402),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text(
                                                      category['name'],
                                                      style: TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              selectedCategory = newValue;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Container(
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          value: selectedPriority,
                                          decoration: InputDecoration(
                                            labelText: 'Priorytet',
                                            alignLabelWithHint: true,
                                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12.0),
                                              borderSide: BorderSide(color: Colors.grey[300]!),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12.0),
                                              borderSide: BorderSide(color: Colors.grey[300]!),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12.0),
                                              borderSide: BorderSide(color: Color(0xFFF49402), width: 2),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12.0),
                                              borderSide: BorderSide(color: Colors.red[400]!, width: 1),
                                            ),
                                            focusedErrorBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12.0),
                                              borderSide: BorderSide(color: Colors.red[400]!, width: 1),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                                            labelStyle: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            floatingLabelStyle: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 15,
                                          ),
                                          icon: Icon(Icons.arrow_drop_down, color: Color(0xFFF49402)),
                                          isExpanded: true,
                                          dropdownColor: Colors.white,
                                          validator: (value) {
                                            if (value == null) {
                                              return 'Wybierz priorytet';
                                            }
                                            return null;
                                          },
                                          items: [
                                            DropdownMenuItem<String>(
                                              value: 'low',
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.arrow_downward,
                                                      size: 20,
                                                      color: Colors.green,
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text(
                                                      'Niski',
                                                      style: TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            DropdownMenuItem<String>(
                                              value: 'medium',
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.remove,
                                                      size: 20,
                                                      color: Colors.orange,
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text(
                                                      'Średni',
                                                      style: TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            DropdownMenuItem<String>(
                                              value: 'high',
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.arrow_upward,
                                                      size: 20,
                                                      color: Colors.red,
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text(
                                                      'Wysoki',
                                                      style: TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              selectedPriority = newValue;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 12.0),
                        Row(
                          children: [
                            Icon(Icons.description_outlined, 
                              size: 18, 
                              color: Color(0xFFF49402)
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Szczegóły problemu',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.0),
                        Container(
                          height: 250,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: TextFormField(
                                  controller: _problemController,
                                  expands: true,
                                  maxLines: null,
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: InputDecoration(
                                    labelText: 'Opis problemu',
                                    alignLabelWithHint: true,
                                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(color: Color(0xFFF49402), width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(color: Colors.red[400]!, width: 1),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(color: Colors.red[400]!, width: 1),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                                    labelStyle: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    floatingLabelStyle: TextStyle(
                                      color: _problemController.selection.isValid ? Color(0xFFF49402) : Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    counterText: '',
                                  ),
                                  maxLength: 275,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 15,
                                  ),
                                  onChanged: (text) {
                                    setState(() {});
                                  },
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Wprowadź opis problemu';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 16,
                                child: Text(
                                  '${_problemController.text.length}/275',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12.0),
                        Center(
                          child: MouseRegion(
                            onEnter: (_) => setState(() => hoverStates['submit'] = true),
                            onExit: (_) => setState(() => hoverStates['submit'] = false),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              transform: Matrix4.identity()
                                ..scale(hoverStates['submit'] == true ? 1.02 : 1.0),
                              child: ElevatedButton(
                                onPressed: () => _submitProblem(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFF49402),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: hoverStates['submit'] == true ? 8 : 4,
                                  shadowColor: Color(0xFFF49402).withOpacity(0.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.send, size: 18, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Wyślij zgłoszenie',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyProblemsView() {
    return Column(
        children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
            child: Column(
              children: [
                if (filteredProblems.isEmpty)
                  Expanded(
                        child: Center(
                          child: Text(
                            'Brak zgłoszeń.',
                            style: TextStyle(fontSize: 16.0, color: Colors.black),
                          ),
                        ),
                      )
                else
                  Expanded(
                        child: GridView.builder(
                          padding: EdgeInsets.symmetric(vertical: 3.0),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 1.9,
                          ),
                          itemCount: problems.length,
                          itemBuilder: (context, index) {
                            var problem = problems[index];
                            bool isRead = problem['read'] == 1;

                            return Card(
                              color: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                                        Icon(
                                          isRead ? Icons.visibility : Icons.visibility_off,
                                          color: isRead ? Colors.green : Colors.grey,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Nauczyciel: ${problem['username'] ?? 'Nieznany'}',
                                      style: TextStyle(color: Colors.black, fontSize: 14),
                                    ),
                                    SizedBox(height: 4),
                                    Flexible(
                                      child: Text(
                                        'Treść: ${problem['problem'] ?? 'Brak opisu'}',
                                        style: TextStyle(color: Colors.black, fontSize: 14),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: Center(
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProblemTempPage(problem: problem),
                                            ),
                                          ).then((deleted) {
                                            if (deleted == true) {
                                              _fetchUserProblems();
                                            }
                                          }),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                            elevation: 1,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              side: BorderSide(color: Colors.black),
                                            ),
                                          ),
                                          child: Text('Rozwiń'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, size: 20),
                      onPressed: currentPage > 0
                          ? () {
                              setState(() {
                                currentPage--;
                                _pageController.jumpToPage(currentPage);
                              });
                            }
                          : null,
                    ),
                    Text('${currentPage + 1} / ${(problems.length / itemsPerPage).ceil()}'),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, size: 20),
                      onPressed: currentPage < (problems.length / itemsPerPage).ceil() - 1
                          ? () {
                              setState(() {
                                currentPage++;
                                _pageController.jumpToPage(currentPage);
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
      ),
      ],
    );
  }
}
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'settings.dart';
import 'package:http/http.dart' as http;
import 'usertempp.dart';
import 'dart:async';
import 'login.dart';
import 'models/issue_template.dart';
import 'statystyki_user.dart';

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
  bool isLoading = false;
  Timer? _timer;
  Map<String, bool> hoverStates = {
    'submit': false,
    'template': false,
  };
  bool _isFetching = false;
  List<dynamic> _problems = [];
  List<dynamic> _filteredProblems = [];
  String? selectedCategory;
  String? selectedRoom;
  bool isManualRoomInput = false;
  String? selectedPriority;
  int selectedFloor = 0;
  String searchQuery = '';
  String? selectedSortOption;
  late String currentUsername;
  final Map<String, Color> statusColors = {
    'untouched': Colors.grey,
    'in_progress': Colors.orange,
    'done': Colors.green,
  };

  List<dynamic> get problems => _problems;
  List<dynamic> get filteredProblems => _filteredProblems.isEmpty ? _problems : _filteredProblems;

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

  Color _getStatusColor(String? status) {
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

  String _getStatusText(String? status) {
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

  String _getPriorityText(String priority) {
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'printer':
        return Icons.print;
      case 'hardware':
        return Icons.computer;
      case 'network':
        return Icons.wifi;
      case 'software':
        return Icons.apps;
      default:
        return Icons.help_outline;
    }
  }

  IconData _getPriorityIconData(String priority) {
    switch (priority) {
      case 'high':
        return Icons.arrow_upward;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.arrow_downward;
      default:
        return Icons.remove;
    }
  }

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

        if (mounted && fetchedProblems.toString() != _problems.toString()) {
          setState(() {
            _problems = fetchedProblems;
            
            // Apply current filters if any are active
            if (selectedCategory != null || selectedPriority != null || searchQuery.isNotEmpty) {
              List<dynamic> filtered = List.from(_problems);
              
              // Apply search filter if active
              if (searchQuery.isNotEmpty) {
                filtered = filtered.where((problem) {
                  final roomMatch = problem['room'].toString().toLowerCase().contains(searchQuery.toLowerCase());
                  final descriptionMatch = problem['problem'].toString().toLowerCase().contains(searchQuery.toLowerCase());
                  return roomMatch || descriptionMatch;
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
              
              _filteredProblems = filtered;
            } else {
              _filteredProblems = [];
            }
            
            // Apply current sorting if active
            if (selectedSortOption != null) {
              _applySorting();
            }
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

  Widget _buildPriorityButton(String value, String label, IconData icon, Color color) {
    bool isSelected = selectedPriority == value;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedPriority = value;
            });
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(11.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? color : Colors.grey[600],
                ),
                SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? color : Colors.grey[600],
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String value, String label, IconData icon) {
    bool isSelected = selectedCategory == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedCategory = value;
          });
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFF49402).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(11.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Color(0xFFF49402) : Colors.grey[600],
              ),
              SizedBox(width: 2),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Color(0xFFF49402) : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialRoomsSheet() {
    final List<Map<String, dynamic>> specialRooms = [
      {'name': 'Sala gimnastyczna', 'icon': Icons.fitness_center},
      {'name': 'Biblioteka', 'icon': Icons.local_library},
      {'name': 'Sekretariat', 'icon': Icons.business_center},
      {'name': 'Księgowa', 'icon': Icons.account_balance},
      {'name': 'Pedagog', 'icon': Icons.psychology},
      {'name': 'Aula', 'icon': Icons.meeting_room},
    ];
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
        minHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      padding: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF49402).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.room_preferences,
                    color: Color(0xFFF49402),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Pomieszczenia specjalne',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Divider(height: 1),
          // Scroll indicator
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey[400],
                  size: 20,
                ),
                SizedBox(width: 4),
                Text(
                  'Przewiń w dół',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Room buttons
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              physics: BouncingScrollPhysics(),
              child: Column(
                children: specialRooms.map((room) {
                  bool isSelected = _roomController.text == room['name'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _roomController.text = room['name'] as String;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Color(0xFFF49402).withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Color(0xFFF49402) : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected 
                                  ? Color(0xFFF49402).withOpacity(0.1)
                                  : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                room['icon'] as IconData,
                                color: isSelected ? Color(0xFFF49402) : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              room['name'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Color(0xFFF49402) : Colors.black87,
                              ),
                            ),
                            if (isSelected) ...[
                              Spacer(),
                              Icon(
                                Icons.check_circle,
                                color: Color(0xFFF49402),
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Bottom padding
          SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showTemplateSelection() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (BuildContext context) => Container(
        padding: EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFFF49402).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: Color(0xFFF49402),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Wybierz szablon zgłoszenia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: IssueTemplate.predefinedTemplates.length,
                itemBuilder: (context, index) {
                  final template = IssueTemplate.predefinedTemplates[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _problemController.text = template.description;
                          selectedCategory = template.category;
                          selectedPriority = template.priority;
                          if (template.roomSuggestion.isNotEmpty) {
                            _roomController.text = template.roomSuggestion;
                          }
                        });
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF49402).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(template.category),
                                    color: Color(0xFFF49402),
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    template.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(template.priority).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getPriorityIconData(template.priority),
                                        color: _getPriorityColor(template.priority),
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        _getPriorityText(template.priority),
                                        style: TextStyle(
                                          color: _getPriorityColor(template.priority),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              template.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  }

  String _removeNewlines(String text) {
    return text.replaceAll('\n', ' ');
  }

  String getRelativeTime(String timestamp) {
    final now = DateTime.now();
    final date = DateTime.parse(timestamp);
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'dzień' : 'dni'} temu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'godzina' : 'godzin'} temu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuta' : 'minut'} temu';
    } else {
      return 'Przed chwilą';
    }
  }

  void _filterProblems(String query) {
    if (!mounted) return;
    
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        _filteredProblems = [];
      } else {
        _filteredProblems = _problems.where((problem) {
          final roomMatch = problem['room'].toString().toLowerCase().contains(query.toLowerCase());
          final descriptionMatch = problem['problem'].toString().toLowerCase().contains(query.toLowerCase());
          return roomMatch || descriptionMatch;
        }).toList();
      }
      
      // Only reset page if current page is beyond the new total pages
      int totalPages = (_filteredProblems.isEmpty ? _problems.length : _filteredProblems.length) ~/ itemsPerPage + 1;
      if (currentPage >= totalPages) {
        currentPage = totalPages > 0 ? totalPages - 1 : 0;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(currentPage);
        }
      }
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      if (category == 'all') {
        selectedCategory = null;
        _filteredProblems = [];
      } else {
        selectedCategory = category;
        _filteredProblems = _problems.where((problem) =>
          problem['category'] == category
        ).toList();
      }
      
      // Only reset page if current page is beyond the new total pages
      int totalPages = (_filteredProblems.isEmpty ? _problems.length : _filteredProblems.length) ~/ itemsPerPage + 1;
      if (currentPage >= totalPages) {
        currentPage = totalPages > 0 ? totalPages - 1 : 0;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(currentPage);
        }
      }
    });
  }

  void _filterByPriority(String priority) {
    setState(() {
      if (priority == 'all') {
        selectedPriority = null;
        _filteredProblems = [];
      } else {
        selectedPriority = priority;
        _filteredProblems = _problems.where((problem) =>
          problem['priority'] == priority
        ).toList();
      }
      
      // Only reset page if current page is beyond the new total pages
      int totalPages = (_filteredProblems.isEmpty ? _problems.length : _filteredProblems.length) ~/ itemsPerPage + 1;
      if (currentPage >= totalPages) {
        currentPage = totalPages > 0 ? totalPages - 1 : 0;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(currentPage);
        }
      }
    });
  }

  void _applySorting() {
    if (!mounted) return;
    
    setState(() {
      var problemsToSort = List<dynamic>.from(_filteredProblems.isEmpty ? _problems : _filteredProblems);
      
      switch (selectedSortOption) {
        case 'newest':
          problemsToSort.sort((a, b) => 
            DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
          break;
        case 'oldest':
          problemsToSort.sort((a, b) => 
            DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));
          break;
        case 'room':
          problemsToSort.sort((a, b) => 
            int.parse(a['room'].toString()).compareTo(int.parse(b['room'].toString())));
          break;
        case 'priority':
          final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
          problemsToSort.sort((a, b) => 
            (priorityOrder[a['priority']] ?? 3).compareTo(priorityOrder[b['priority']] ?? 3));
          break;
      }
      
      _filteredProblems = problemsToSort;
    });
  }

  Widget _buildFilterButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<String>(
          icon: Icon(Icons.sort, color: Colors.black),
          tooltip: 'Sortuj',
          color: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          onSelected: (String option) {
            if (mounted) {
              setState(() {
                selectedSortOption = option;
                _applySorting();
              });
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            _buildPopupMenuItem('newest', Icons.arrow_downward, 'Najnowsze'),
            _buildPopupMenuItem('oldest', Icons.arrow_upward, 'Najstarsze'),
            _buildPopupMenuItem('room', Icons.meeting_room, 'Numer sali'),
            _buildPopupMenuItem('priority', Icons.priority_high, 'Priorytet'),
          ],
        ),
        SizedBox(width: 8),
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
                _filteredProblems = List.from(_problems);
              } else {
                selectedCategory = category;
                _filteredProblems = _problems.where((problem) =>
                  problem['category'] == category
                ).toList();
              }
              
              _filteredProblems.sort((a, b) =>
                DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
              
              if (_pageController.hasClients) {
                _pageController.jumpToPage(0);
              }
            });
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            _buildPopupMenuItem('hardware', Icons.computer, 'Sprzęt'),
            _buildPopupMenuItem('software', Icons.apps, 'Oprogramowanie'),
            _buildPopupMenuItem('network', Icons.wifi, 'Sieć'),
            _buildPopupMenuItem('printer', Icons.print, 'Drukarka'),
            _buildPopupMenuItem('other', Icons.more_horiz, 'Inne'),
            _buildPopupMenuItem('all', Icons.clear_all, 'Wszystkie'),
          ],
        ),
        SizedBox(width: 8),
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
                _filteredProblems = List.from(_problems);
              } else {
                selectedPriority = priority;
                _filteredProblems = _problems.where((problem) =>
                  problem['priority'] == priority
                ).toList();
              }
              
              _filteredProblems.sort((a, b) =>
                DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
              
              if (_pageController.hasClients) {
                _pageController.jumpToPage(0);
              }
            });
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            _buildPopupMenuItem('high', Icons.arrow_upward, 'Wysoki priorytet'),
            _buildPopupMenuItem('medium', Icons.remove, 'Średni priorytet'),
            _buildPopupMenuItem('low', Icons.arrow_downward, 'Niski priorytet'),
            _buildPopupMenuItem('all', Icons.clear_all, 'Wszystkie'),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFF49402)),
          SizedBox(width: 12),
          Text(text),
        ],
        mainAxisSize: MainAxisSize.min,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                onEnter: (_) => setState(() => hoverStates['stats'] = true),
                onExit: (_) => setState(() => hoverStates['stats'] = false),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  color: hoverStates['stats'] == true ? Colors.grey[200] : Colors.transparent,
                  child: ListTile(
                    leading: Icon(Icons.bar_chart, color: Colors.black),
                    title: Text('Moje statystyki', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StatystykiUserPage(username: widget.username)),
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
                      _handleLogout();
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
      children: <Widget>[
        Divider(
          color: Color(0xFFF49402),
          thickness: 1.0,
          height: 1.0,
        ),
        Expanded(
          child: Container(
            color: Colors.grey[50],
            padding: const EdgeInsets.fromLTRB(16.0, 2.0, 16.0, 0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 15.0),
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
                  SizedBox(height: 15.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 55.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
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
                            Spacer(),
                            MouseRegion(
                              onEnter: (_) => setState(() => hoverStates['template'] = true),
                              onExit: (_) => setState(() => hoverStates['template'] = false),
                              child: TextButton.icon(
                                onPressed: _showTemplateSelection,
                                icon: Icon(Icons.description_outlined, color: Color(0xFFF49402)),
                                label: Text(
                                  'Użyj szablonu',
                                  style: TextStyle(
                                    color: Color(0xFFF49402),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: hoverStates['template'] == true
                                      ? Color(0xFFF49402).withOpacity(0.15)
                                      : Color(0xFFF49402).withOpacity(0.1),
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
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
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
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
                                          prefixIcon: Icon(
                                            Icons.meeting_room_outlined,
                                            color: _roomController.text.isEmpty ? Colors.grey[600] : Color(0xFFF49402),
                                            size: 20,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              Icons.more_vert,
                                              color: Colors.grey[600],
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              showModalBottomSheet(
                                                context: context,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.vertical(
                                                    top: Radius.circular(20),
                                                  ),
                                                ),
                                                builder: (context) => _buildSpecialRoomsSheet(),
                                              );
                                            },
                                          ),
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
                                            color: _roomController.text.isNotEmpty ? Color(0xFFF49402) : Colors.grey[600],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          counterText: '',
                                        ),
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'Wprowadź numer sali';
                                          }
                                          return null;
                                        },
                                        maxLength: 15,
                                        onChanged: (text) {
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                                            child: Text(
                                              'Kategoria problemu',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12.0),
                                              border: Border.all(color: Colors.grey[300]!),
                                            ),
                                            child: Row(
                                              children: categories.map((category) {
                                                return Expanded(
                                                  child: Row(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: Padding(
                                                          padding: EdgeInsets.symmetric(horizontal: 2),
                                                          child: _buildCategoryButton(
                                                            category['id'],
                                                            category['name'],
                                                            category['icon'],
                                                          ),
                                                        ),
                                                      ),
                                                      if (category != categories.last)
                                                        Container(width: 1, height: 24, color: Colors.grey[300]),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                                            child: Text(
                                              'Priorytet',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12.0),
                                              border: Border.all(color: Colors.grey[300]!),
                                            ),
                                            child: Row(
                                              children: <Widget>[
                                                _buildPriorityButton('low', 'Niski', Icons.arrow_downward, Colors.green),
                                                Container(width: 1, height: 24, color: Colors.grey[300]),
                                                _buildPriorityButton('medium', 'Średni', Icons.remove, Colors.orange),
                                                Container(width: 1, height: 24, color: Colors.grey[300]),
                                                _buildPriorityButton('high', 'Wysoki', Icons.arrow_upward, Colors.red),
                                              ],
                                            ),
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
                        SizedBox(height: 12.0),
                        Row(
                          children: <Widget>[
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
                            children: <Widget>[
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
                              margin: EdgeInsets.only(bottom: 0),
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
                                  children: <Widget>[
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
    if (filteredProblems.isEmpty) {
      return Column(
        children: <Widget>[
          _buildSearchBar(),
          Expanded(
            child: Center(
              child: Text(
                'Brak zgłoszeń.',
                style: TextStyle(fontSize: 16.0, color: Colors.black),
              ),
            ),
          ),
        ],
      );
    }

    final int totalPages = (filteredProblems.length / itemsPerPage).ceil();
    if (currentPage >= totalPages) {
      currentPage = totalPages - 1;
    }
    if (currentPage < 0) {
      currentPage = 0;
    }
    
    final int startIndex = currentPage * itemsPerPage;
    final int endIndex = (startIndex + itemsPerPage > filteredProblems.length) 
        ? filteredProblems.length 
        : startIndex + itemsPerPage;
    final List<dynamic> currentPageProblems = filteredProblems.sublist(startIndex, endIndex);

    return Column(
      children: <Widget>[
        _buildSearchBar(),
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.symmetric(vertical: 3.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 1.9,
                    ),
                    itemCount: currentPageProblems.length,
                    itemBuilder: (context, index) {
                      var problem = currentPageProblems[index];
                      return _buildProblemCard(problem);
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, size: 20),
                        onPressed: currentPage > 0
                            ? () {
                                setState(() {
                                  currentPage--;
                                });
                              }
                            : null,
                        color: currentPage > 0 ? Colors.black : Colors.grey,
                      ),
                      Text(
                        '${currentPage + 1} / $totalPages',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios, size: 20),
                        onPressed: currentPage < totalPages - 1
                            ? () {
                                setState(() {
                                  currentPage++;
                                });
                              }
                            : null,
                        color: currentPage < totalPages - 1 ? Colors.black : Colors.grey,
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

  Widget _buildSearchBar() {
    return Container(
      height: 60,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 37.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
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
                  onChanged: _filterProblems,
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
                ),
              ),
            ),
            SizedBox(width: 8),
            _buildFilterButtons(),
          ],
        ),
      ),
    );
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
            side: BorderSide(
              color: _getStatusColor(problem['status']).withOpacity(0.3),
              width: 1.0,
            ),
          ),
          child: Padding(
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
                          'Sala ${problem['room']}',
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
                        color: _getStatusColor(problem['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(problem['status']).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(problem['status']),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            _getStatusText(problem['status']),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(problem['status']),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
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
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(problem['priority']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag,
                            size: 12,
                            color: _getPriorityColor(problem['priority']),
                          ),
                          SizedBox(width: 4),
                          Text(
                            _getPriorityText(problem['priority']),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getPriorityColor(problem['priority']),
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
                    TextButton(
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
                              _fetchUserProblems();
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }
}
class IssueTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final String priority;
  final String roomSuggestion;

  IssueTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.priority,
    this.roomSuggestion = '',
  });

  // Predefined templates
  static List<IssueTemplate> predefinedTemplates = [
    IssueTemplate(
      id: 'printer_not_working',
      name: 'Drukarka nie drukuje',
      description: 'Próbowałem/am wydrukować dokument, ale nic się nie dzieje. Drukarka jest włączona i ma papier.',
      category: 'printer',
      priority: 'high',
      roomSuggestion: '',
    ),
    IssueTemplate(
      id: 'projector_black_screen',
      name: 'Czarny ekran projektora',
      description: 'Projektor jest włączony, ale ekran jest czarny. Komputer jest podłączony kablem.',
      category: 'hardware',
      priority: 'high',
      roomSuggestion: '',
    ),
    IssueTemplate(
      id: 'program_not_working',
      name: 'Program nie chce się otworzyć',
      description: 'Próbuję otworzyć program potrzebny na lekcji, ale pokazuje błąd i się nie uruchamia.',
      category: 'software',
      priority: 'high',
      roomSuggestion: '',
    ),
    IssueTemplate(
      id: 'mouse_keyboard_not_working',
      name: 'Myszka lub klawiatura nie działa',
      description: 'Myszka lub klawiatura przestała działać. Próbowałem/am odłączyć i podłączyć ponownie ale nadal nie działa.',
      category: 'hardware',
      priority: 'high',
      roomSuggestion: '',
    ),
    IssueTemplate(
      id: 'computer_slow_startup',
      name: 'Komputer bardzo długo się włącza',
      description: 'Komputer uruchamia się niezwykle wolno, czekam już ponad 10 minut. Potrzebuję go na lekcję.',
      category: 'hardware',
      priority: 'high',
      roomSuggestion: '',
    ),
  ];
} 
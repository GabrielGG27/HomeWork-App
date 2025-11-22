import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homework Tracker',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const HomeworkListScreen(),
    );
  }
}

class Homework {
  String id;
  String title;
  String subject;
  DateTime dueDate;
  bool isCompleted;

  Homework({
    required this.title,
    required this.subject,
    required this.dueDate,
    this.isCompleted = false,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'dueDate': dueDate.millisecondsSinceEpoch,
        'isCompleted': isCompleted,
      };

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'],
        subject: json['subject'],
        dueDate: DateTime.fromMillisecondsSinceEpoch(json['dueDate']),
        isCompleted: json['isCompleted'],
      );
}

class HomeworkListScreen extends StatefulWidget {
  const HomeworkListScreen({super.key});

  @override
  State<HomeworkListScreen> createState() => _HomeworkListScreenState();
}

class _HomeworkListScreenState extends State<HomeworkListScreen> {
  late Future<List<Homework>> _homeworkFuture;

  @override
  void initState() {
    super.initState();
    _homeworkFuture = _loadHomework();
  }

  Future<List<Homework>> _loadHomework() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('homework') ?? [];
    return data.map((item) => Homework.fromJson(jsonDecode(item))).toList();
  }

  Future<void> _saveHomework(List<Homework> homeworkList) async {
    final prefs = await SharedPreferences.getInstance();
    final data = homeworkList.map((h) => jsonEncode(h.toJson())).toList();
    await prefs.setStringList('homework', data);
  }

  void _addHomework(Homework homework) async {
    final list = await _loadHomework();
    list.add(homework);
    await _saveHomework(list);
    setState(() {
      _homeworkFuture = _loadHomework();
    });
  }

  void _updateHomework(int index, Homework updatedHomework) async {
    final list = await _loadHomework();
    list[index] = updatedHomework;
    await _saveHomework(list);
    setState(() {
      _homeworkFuture = _loadHomework();
    });
  }

  void _deleteHomework(int index) async {
    final list = await _loadHomework();
    list.removeAt(index);
    await _saveHomework(list);
    setState(() {
      _homeworkFuture = _loadHomework();
    });
  }

  void _toggleCompleted(Homework homework) async {
    final list = await _loadHomework();
    final index = list.indexWhere((h) => h.id == homework.id);
    if (index != -1) {
      list[index].isCompleted = !list[index].isCompleted;
      await _saveHomework(list);
      setState(() {
        _homeworkFuture = _loadHomework();
      });
    }
  }

  void _editHomework(Homework homework, List<Homework> fullList) async {
    final updatedHomework = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddHomeworkScreen(homework: homework),
      ),
    );
    if (updatedHomework != null) {
      final index = fullList.indexWhere((h) => h.id == homework.id);
      if (index != -1) {
        _updateHomework(index, updatedHomework);
      }
    }
  }

  void _deleteFromFullList(Homework homework, List<Homework> fullList) {
    final index = fullList.indexWhere((h) => h.id == homework.id);
    if (index != -1) {
      _deleteHomework(index);
    }
  }



// FUNCIÓN PARA AGRUPAR LAS TAREAS POR FECHA

Map<String, List<Homework>> _groupHomeworkByDate(List<Homework> homeworkList) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final endOfWeek = today.add(const Duration(days: 7)); // 👈 7 días desde hoy

  final Map<String, List<Homework>> groups = {
    'Vencidas': [],
    'Hoy': [],
    'Mañana': [],
    'Esta semana': [],
    'Próximamente': [],
  };

  for (final hw in homeworkList) {
    final due = DateTime(hw.dueDate.year, hw.dueDate.month, hw.dueDate.day);
    
    if (due.isBefore(today)) {
      groups['Vencidas']!.add(hw);
    } else if (due.isAtSameMomentAs(today)) {
      groups['Hoy']!.add(hw);
    } else if (due.isAtSameMomentAs(tomorrow)) {
      groups['Mañana']!.add(hw);
    } else if (due.isAfter(tomorrow) && !due.isAfter(endOfWeek)) {
      // Entre pasado mañana y dentro de 7 días (incluido el día 7)
      groups['Esta semana']!.add(hw);
    } else if (due.isAfter(endOfWeek)) {
      groups['Próximamente']!.add(hw);
    }
  }

  groups.removeWhere((key, value) => value.isEmpty);
  return groups;
}

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Homework Tracker'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pendientes'),
              Tab(text: 'Completadas'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final homework = await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddHomeworkScreen()),
            );
            if (homework != null) {
              _addHomework(homework);
            }
          },
          child: const Icon(Icons.add),
        ),
        body: FutureBuilder<List<Homework>>(
          future: _homeworkFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final allHomework = snapshot.data!;

            final pending = allHomework.where((h) => !h.isCompleted).toList();
            final completed = allHomework.where((h) => h.isCompleted).toList();

            pending.sort((a, b) => a.dueDate.compareTo(b.dueDate));
            completed.sort((a, b) => a.dueDate.compareTo(b.dueDate));

            return TabBarView(
              children: [
                _buildHomeworkList(context, pending, allHomework, true),
                _buildHomeworkList(context, completed, allHomework, false),
              ],
            );
          },
        ),
      ),
    );
  }

      Widget _buildHomeworkList(
    BuildContext context,
    List<Homework> filteredList,
    List<Homework> fullList,
    bool isPendingTab,
  ) {
    if (filteredList.isEmpty) {
      return Center(
        child: Text(
          isPendingTab ? 'No hay tareas pendientes' : 'No hay tareas completadas',
        ),
      );
    }

    if (isPendingTab) {
      final grouped = _groupHomeworkByDate(filteredList);
      return ListView.builder(
        itemCount: grouped.keys.length,
        itemBuilder: (context, sectionIndex) {
          final sectionTitle = grouped.keys.elementAt(sectionIndex);
          final sectionTasks = grouped.values.elementAt(sectionIndex);

          // Define estilo por sección
          Color textColor;
          IconData icon;
          double fontSize;

          switch (sectionTitle) {
            case 'Vencidas':
              textColor = Colors.red[800]!;
              icon = Icons.hourglass_empty;
              fontSize = 23;
              break;
            case 'Hoy':
              textColor = Colors.red;
              icon = Icons.warning;
              fontSize = 23;
              break;
            case 'Mañana':
              textColor = Colors.orange;
              icon = Icons.calendar_today;
              fontSize = 23;
              break;
            case 'Esta semana':
              textColor = const Color.fromARGB(250, 245, 225, 10);
              icon = Icons.calendar_view_week;
              fontSize = 23;
              break;
            case 'Próximamente':
              textColor = Colors.grey[700]!;
              icon = Icons.date_range;
              fontSize = 23;
              break;
            default:
              textColor = Colors.blueGrey;
              icon = Icons.label;
              fontSize = 16;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: textColor),
                    const SizedBox(width: 8),
                    Text(
                      sectionTitle,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              ...sectionTasks.map((hw) {
                final formattedDate = DateFormat('MMM dd, yyyy – hh:mm a').format(hw.dueDate);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    onTap: () => _editHomework(hw, fullList),
                    leading: Checkbox(
                      value: hw.isCompleted,
                      onChanged: (value) => _toggleCompleted(hw),
                    ),
                    title: Text(
                      hw.title,
                      style: TextStyle(
                        decoration: hw.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text('${hw.subject} • $formattedDate'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteFromFullList(hw, fullList),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      );
    } else {
      // Completadas: lista simple (sin agrupación por ahora)
      return ListView.builder(
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final hw = filteredList[index];
          final formattedDate = DateFormat('MMM dd, yyyy – hh:mm a').format(hw.dueDate);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              onTap: () => _editHomework(hw, fullList),
              leading: Checkbox(
                value: hw.isCompleted,
                onChanged: (value) => _toggleCompleted(hw),
              ),
              title: Text(
                hw.title,
                style: const TextStyle(decoration: TextDecoration.lineThrough),
              ),
              subtitle: Text('${hw.subject} • $formattedDate'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteFromFullList(hw, fullList),
              ),
            ),
          );
        },
      );
    }
  }
}

class AddHomeworkScreen extends StatefulWidget {
  final Homework? homework;

  const AddHomeworkScreen({super.key, this.homework});

  @override
  State<AddHomeworkScreen> createState() => _AddHomeworkScreenState();
}

class _AddHomeworkScreenState extends State<AddHomeworkScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subjectController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();

    if (widget.homework != null) {
      _titleController = TextEditingController(text: widget.homework!.title);
      _subjectController = TextEditingController(text: widget.homework!.subject);
      _selectedDate = widget.homework!.dueDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.homework!.dueDate);
    } else {
      _titleController = TextEditingController();
      _subjectController = TextEditingController();
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.homework != null ? 'Edit Homework' : 'Add Homework'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value?.isEmpty == true ? 'Enter a title' : null,
              ),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (value) => value?.isEmpty == true ? 'Enter a subject' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Due Date'),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Due Time'),
                      subtitle: Text(_selectedTime.format(context)),
                      onTap: () => _selectTime(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final due = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    );
                    final homework = Homework(
                      id: widget.homework?.id, // 👈 Conserva el ID al editar
                      title: _titleController.text,
                      subject: _subjectController.text,
                      dueDate: due,
                      isCompleted: widget.homework?.isCompleted ?? false,
                    );
                    Navigator.of(context).pop(homework);
                  }
                },
                child: Text(widget.homework != null ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
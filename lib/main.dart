import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';

import 'dart:async';

// Canal de notificaciones
const String notificationChannelId = 'homework_channel_id';
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // ✅ Crear el canal correctamente
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'Homework Notifications',
    description: 'Notificaciones para tareas próximas',
    importance: Importance.high,
    playSound: true,
  );

  final androidPlatform = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await androidPlatform?.createNotificationChannel(channel);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homework Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
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
  bool enableNotification;
  int notificationOffset;

  Homework({
    required this.title,
    required this.subject,
    required this.dueDate,
    this.isCompleted = false,
    this.enableNotification = true,
    this.notificationOffset = 0,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'dueDate': dueDate.millisecondsSinceEpoch,
    'isCompleted': isCompleted,
    'enableNotification': enableNotification,
    'notificationOffset': notificationOffset,
  };

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: json['title'],
    subject: json['subject'],
    dueDate: DateTime.fromMillisecondsSinceEpoch(json['dueDate']),
    isCompleted: json['isCompleted'],
    enableNotification: json['enableNotification'] ?? true,
    notificationOffset: json['notificationOffset'] ?? 0,
  );
}

class HomeworkListScreen extends StatefulWidget {
  final String? subjectFilter;
  const HomeworkListScreen({super.key, this.subjectFilter});

  @override
  State<HomeworkListScreen> createState() => _HomeworkListScreenState();
}

class _HomeworkListScreenState extends State<HomeworkListScreen> {
  late Future<List<Homework>> _homeworkFuture;
  Timer? _timer;
  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _homeworkFuture = _loadHomework();
    _loadSubjects();
    _requestPermissions(); // 🔥 NUEVO: Pedir permisos al iniciar
    _schedulePendingNotifications();

    // 🔥 NUEVO: Esto actualiza la UI cada minuto para mover tareas a "Vencidas" en tiempo real
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // Al hacer setState, se reconstruye el widget, se ejecuta _groupHomeworkByDate
          // y DateTime.now() tendrá el valor actual, moviendo las tareas automáticamente.
        });
      }
    });
  }

  @override
  void dispose() {
    _timer
        ?.cancel(); // 🔥 NUEVO: Importante cancelar el timer al cerrar la pantalla
    super.dispose();
  }

  // 🔥 NUEVO: Función para pedir permisos en Android 13+
  void _requestPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<List<Homework>> _loadHomework() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('homework') ?? [];
    return data.map((item) => Homework.fromJson(jsonDecode(item))).toList();
  }

  Future<void> _loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _subjects = prefs.getStringList('subjects') ?? [];
    });
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
    _scheduleNotification(homework);
    setState(() {
      _homeworkFuture = _loadHomework();
      _loadSubjects(); // Reload subjects in case a new one was added
    });
  }

  void _updateHomework(int index, Homework updatedHomework) async {
    final list = await _loadHomework();
    list[index] = updatedHomework;
    await _saveHomework(list);
    _scheduleNotification(updatedHomework); // Re-programar notificación
    setState(() {
      _homeworkFuture = _loadHomework();
      _loadSubjects(); // Reload subjects
    });
  }

  void _deleteHomework(int index) async {
    final list = await _loadHomework();
    // Cancelar notificación si se borra la tarea (Opcional pero recomendado)
    // flutterLocalNotificationsPlugin.cancel(list[index].id.hashCode & 0x7FFFFFFF);
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
      // Si se completa, quizás quieras cancelar la notificación:
      if (list[index].isCompleted) {
        final notificationId = homework.id.hashCode & 0x7FFFFFFF;
        await flutterLocalNotificationsPlugin.cancel(notificationId);
      }
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

  // ... (Tu función _groupHomeworkByDate se queda igual) ...
  Map<String, List<Homework>> _groupHomeworkByDate(
    List<Homework> homeworkList,
  ) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final tomorrowStart = todayEnd;
    final tomorrowEnd = tomorrowStart.add(const Duration(days: 1));
    final endOfWeek = todayStart.add(const Duration(days: 7));

    final Map<String, List<Homework>> groups = {
      'Vencidas': [],
      'Hoy': [],
      'Mañana': [],
      'Esta semana': [],
      'Próximamente': [],
    };

    for (final hw in homeworkList) {
      if (hw.dueDate.isBefore(now)) {
        groups['Vencidas']!.add(hw);
      } else if (hw.dueDate.isAfter(now) && hw.dueDate.isBefore(todayEnd)) {
        groups['Hoy']!.add(hw);
      } else if (hw.dueDate.isAfter(todayEnd) &&
          hw.dueDate.isBefore(tomorrowEnd)) {
        groups['Mañana']!.add(hw);
      } else if (hw.dueDate.isAfter(tomorrowEnd) &&
          hw.dueDate.isBefore(endOfWeek)) {
        groups['Esta semana']!.add(hw);
      } else if (hw.dueDate.isAfter(endOfWeek)) {
        groups['Próximamente']!.add(hw);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  void _confirmClearCompleted(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Vaciar tareas completadas?'),
        content: const Text(
          'Se eliminarán todas las tareas marcadas como completadas. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearCompletedTasks();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _clearCompletedTasks() async {
    final allTasks = await _loadHomework();
    final pendingTasks = allTasks.where((task) => !task.isCompleted).toList();
    await _saveHomework(pendingTasks);
    setState(() {
      _homeworkFuture = _loadHomework();
    });
  }

  Future<void> _schedulePendingNotifications() async {
    final allTasks = await _loadHomework();
    final pendingTasks = allTasks.where((task) => !task.isCompleted).toList();
    for (final task in pendingTasks) {
      _scheduleNotification(task);
    }
  }

  Future<void> _scheduleNotification(Homework homework) async {
    // 1. Verificar si las notificaciones están habilitadas para esta tarea
    if (!homework.enableNotification) {
      final notificationId = homework.id.hashCode & 0x7FFFFFFF;
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      return;
    }

    // 2. Calcular la fecha/hora de la notificación
    final scheduledDate = homework.dueDate.subtract(
      Duration(minutes: homework.notificationOffset),
    );
    final now = DateTime.now();

    // 3. Si la fecha programada ya pasó, no hacer nada
    if (scheduledDate.isBefore(now)) return;

    final notificationId = homework.id.hashCode & 0x7FFFFFFF;

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Tarea próxima: ${homework.title}',
        'Vence ${DateFormat('MMM dd, hh:mm a').format(homework.dueDate)}',
        tz.TZDateTime.from(scheduledDate, tz.local), // Usar scheduledDate
        const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            'Homework Notifications',
            channelDescription: 'Notificaciones para tareas próximas',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print(
        "Notificación programada para: $scheduledDate (Vence: ${homework.dueDate})",
      );
    } catch (e) {
      print("Error al programar notificación: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.subjectFilter ?? 'Homework Tracker'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pendientes'),
              Tab(text: 'Completadas'),
            ],
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text(
                  'Materias',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('Todas las tareas'),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  // If we are in a filtered view, replace current screen with main screen
                  if (widget.subjectFilter != null) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomeworkListScreen(),
                      ),
                      (route) => route.isFirst,
                    );
                  }
                },
              ),
              const Divider(),
              if (_subjects.isEmpty)
                const ListTile(title: Text('No hay materias guardadas'))
              else
                ..._subjects.map(
                  (subject) => ListTile(
                    leading: const Icon(Icons.book),
                    title: Text(subject),
                    onTap: () async {
                      Navigator.pop(context);
                      // Await the pushed filtered screen so we can refresh when it returns.
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HomeworkListScreen(subjectFilter: subject),
                        ),
                      );
                      // When returning from the filtered screen, reload homework and subjects
                      // so the main "All tasks" list reflects any additions/changes made there.
                      if (mounted) {
                        setState(() {
                          _homeworkFuture = _loadHomework();
                          _loadSubjects();
                        });
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final homework = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddHomeworkScreen(),
              ),
            );
            if (homework != null) {
              _addHomework(homework);
            }
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'Nueva',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: FutureBuilder<List<Homework>>(
          future: _homeworkFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final allHomework = snapshot.data!;

            // Filter by subject if needed
            final filteredHomework = widget.subjectFilter != null
                ? allHomework
                      .where((h) => h.subject == widget.subjectFilter)
                      .toList()
                : allHomework;

            final pending = filteredHomework
                .where((h) => !h.isCompleted)
                .toList();
            final completed = filteredHomework
                .where((h) => h.isCompleted)
                .toList();

            pending.sort((a, b) => a.dueDate.compareTo(b.dueDate));
            completed.sort((a, b) => a.dueDate.compareTo(b.dueDate));

            return Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: TabBarView(
                children: [
                  _buildHomeworkList(context, pending, allHomework, true),
                  _buildHomeworkList(context, completed, allHomework, false),
                ],
              ),
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
          isPendingTab
              ? 'No hay tareas pendientes'
              : 'No hay tareas completadas',
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
              textColor = const Color(0xFF00bb2d);
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                final formattedDate = DateFormat(
                  'MMM dd, yyyy – hh:mm a',
                ).format(hw.dueDate);
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    onTap: () => _editHomework(hw, fullList),
                    leading: Checkbox(
                      value: hw.isCompleted,
                      onChanged: (value) => _toggleCompleted(hw),
                    ),
                    title: Text(
                      hw.title,
                      style: TextStyle(
                        decoration: hw.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
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
      if (filteredList.isEmpty) {
        return Center(child: Text('No hay tareas completadas'));
      }

      return ListView.builder(
        itemCount: filteredList.length + 1,
        itemBuilder: (context, index) {
          if (index == filteredList.length) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => _confirmClearCompleted(context),
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                label: const Text(
                  'Vaciar tareas completadas',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            );
          }

          final hw = filteredList[index];
          final formattedDate = DateFormat(
            'MMM dd, yyyy – hh:mm a',
          ).format(hw.dueDate);
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
  bool _enableNotification = true;
  int _notificationOffset = 0;

  List<String> _subjects = [];
  String? _selectedSubject;
  final String _createNewSubjectLabel = 'Crear nueva materia...';

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    if (widget.homework != null) {
      _titleController = TextEditingController(text: widget.homework!.title);
      _subjectController = TextEditingController(
        text: widget.homework!.subject,
      );
      _selectedSubject = widget.homework!.subject;
      _selectedDate = widget.homework!.dueDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.homework!.dueDate);
      _enableNotification = widget.homework!.enableNotification;
      _notificationOffset = widget.homework!.notificationOffset;
    } else {
      _titleController = TextEditingController();
      _subjectController = TextEditingController();
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = TimeOfDay.now();
      _enableNotification = true;
      _notificationOffset = 0;
    }
  }

  Future<void> _loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _subjects = prefs.getStringList('subjects') ?? [];
      // Ensure the current subject is in the list if editing
      if (widget.homework != null &&
          !_subjects.contains(widget.homework!.subject)) {
        _subjects.add(widget.homework!.subject);
      }
    });
  }

  Future<void> _saveSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('subjects', _subjects);
  }

  Future<void> _addNewSubject() async {
    String? newSubject = await showDialog<String>(
      context: context,
      builder: (context) {
        String value = '';
        return AlertDialog(
          title: const Text('Nueva materia'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nombre de la materia'),
            onChanged: (text) {
              value = text;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, value),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (newSubject != null && newSubject.trim().isNotEmpty) {
      setState(() {
        if (!_subjects.contains(newSubject)) {
          _subjects.add(newSubject);
          _saveSubjects();
        }
        _selectedSubject = newSubject;
        _subjectController.text = newSubject;
      });
    } else {
      // Reset selection if cancelled or empty
      setState(() {
        _selectedSubject = _subjectController.text.isNotEmpty
            ? _subjectController.text
            : null;
      });
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Enter a title' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _subjects.contains(_selectedSubject)
                      ? _selectedSubject
                      : null,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: [
                    ..._subjects.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s)),
                    ),
                    DropdownMenuItem(
                      value: _createNewSubjectLabel,
                      child: Row(
                        children: const [
                          Icon(Icons.add, size: 20),
                          SizedBox(width: 8),
                          Text('Crear nueva materia...'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == _createNewSubjectLabel) {
                      _addNewSubject();
                    } else {
                      setState(() {
                        _selectedSubject = value;
                        _subjectController.text = value ?? '';
                      });
                    }
                  },
                  validator: (value) =>
                      (value == null && _subjectController.text.isEmpty)
                      ? 'Select or create a subject'
                      : null,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Due Date'),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy').format(_selectedDate),
                        ),
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
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text('Recibir notificación'),
                  value: _enableNotification,
                  onChanged: (value) {
                    setState(() {
                      _enableNotification = value;
                    });
                  },
                ),
                if (_enableNotification)
                  DropdownButtonFormField<int>(
                    value: _notificationOffset,
                    decoration: const InputDecoration(
                      labelText: 'Anticipación',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 0,
                        child: Text('A la hora de vencimiento'),
                      ),
                      DropdownMenuItem(
                        value: 10,
                        child: Text('10 minutos antes'),
                      ),
                      DropdownMenuItem(
                        value: 30,
                        child: Text('30 minutos antes'),
                      ),
                      DropdownMenuItem(value: 60, child: Text('1 hora antes')),
                      DropdownMenuItem(
                        value: 120,
                        child: Text('2 horas antes'),
                      ),
                      DropdownMenuItem(value: 1440, child: Text('1 día antes')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _notificationOffset = value;
                        });
                      }
                    },
                  ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() &&
                        _subjectController.text.isNotEmpty) {
                      final due = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        _selectedTime.hour,
                        _selectedTime.minute,
                      );
                      final homework = Homework(
                        id: widget.homework?.id,
                        title: _titleController.text,
                        subject: _subjectController.text,
                        dueDate: due,
                        isCompleted: widget.homework?.isCompleted ?? false,
                        enableNotification: _enableNotification,
                        notificationOffset: _notificationOffset,
                      );
                      Navigator.of(context).pop(homework);
                    } else if (_subjectController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a subject'),
                        ),
                      );
                    }
                  },
                  child: Text(widget.homework != null ? 'Update' : 'Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

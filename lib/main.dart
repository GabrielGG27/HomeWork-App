import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:homework_app/icons_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'dart:async';

//emojis
// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

// Notification channel
const String notificationChannelId = 'homework_channel_id';
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz_data.initializeTimeZones();
  // Try to use the device timezone via flutter_timezone package.
  try {
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    final deviceTimeZone = tzInfo?.identifier ?? 'UTC';
    tz.setLocalLocation(tz.getLocation(deviceTimeZone));
  } catch (e) {
    // Fallback to UTC if timezone lookup fails
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('icon_app');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // ✅ Crear el canal correctamente
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'Homework Notifications',
    description: 'Notifications for upcoming homework assignments',
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode');
    if (languageCode != null) {
      setState(() {
        _locale = Locale(languageCode);
      });
    }
  }

  void setLocale(Locale value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', value.languageCode);
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
      ],
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
  // NEW: important flag
  bool isImportant;
  // NEW: description field
  String description;

  Homework({
    required this.title,
    required this.subject,
    required this.dueDate,
    this.isCompleted = false,
    this.enableNotification = true,
    this.notificationOffset = 0,
    this.isImportant = false, // default false
    this.description = '',
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
    'isImportant': isImportant, // persist
    'description': description,
  };

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: json['title'],
    subject: json['subject'],
    dueDate: DateTime.fromMillisecondsSinceEpoch(json['dueDate']),
    isCompleted: json['isCompleted'] ?? false,
    enableNotification: json['enableNotification'] ?? true,
    notificationOffset: json['notificationOffset'] ?? 0,
    isImportant: json['isImportant'] ?? false, // read back
    description: json['description'] ?? '',
  );
}

//Homework List Screen

class HomeworkListScreen extends StatefulWidget {
  final String? subjectFilter;
  final bool showImportant; // NEW: flag to show only important tasks
  const HomeworkListScreen({
    super.key,
    this.subjectFilter,
    this.showImportant = false,
  });

  @override
  State<HomeworkListScreen> createState() => _HomeworkListScreenState();
}

class _HomeworkListScreenState extends State<HomeworkListScreen> {
  List<Homework> _homeworkList = [];
  bool _isLoading = true;
  Timer? _timer;
  List<String> _subjects = [];
  Map<String, int> _subjectIcons = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _requestPermissions(); // NEW: request notification permissions on start
    _schedulePendingNotifications();

    // NEW: update UI every minute so overdue tasks move automatically
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // setState triggers rebuild and _groupHomeworkByDate will use current DateTime
        });
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    // Load subjects
    await _loadSubjects();
    // Load homework
    final loaded = await _loadHomework();
    setState(() {
      _homeworkList = loaded;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _timer
        ?.cancel(); // 🔥 NUEVO: Importante cancelar el timer al cerrar la pantalla
    super.dispose();
  }

  // NEW: request Android 13+ notifications permission
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

    List<Homework> loaded = [];
    bool needsSave = false;
    // Base timestamp to ensure unique IDs for migrated tasks
    int baseId = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < data.length; i++) {
      try {
        Map<String, dynamic> json = jsonDecode(data[i]);
        // Fix missing ID
        if (json['id'] == null) {
          json['id'] = '${baseId + i}';
          needsSave = true;
        }
        loaded.add(Homework.fromJson(json));
      } catch (e) {
        // Skip malformed data
        print('Error loading homework item: $e');
      }
    }

    if (needsSave) {
      final fixedData = loaded.map((h) => jsonEncode(h.toJson())).toList();
      await prefs.setStringList('homework', fixedData);
    }

    return loaded;
  }

  Future<void> _loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _subjects = prefs.getStringList('subjects') ?? [];
      final iconsJson = prefs.getString('subject_icons');
      if (iconsJson != null) {
        _subjectIcons = Map<String, int>.from(jsonDecode(iconsJson));
      }
    });
  }

  Future<void> _saveHomework(List<Homework> homeworkList) async {
    final prefs = await SharedPreferences.getInstance();
    final data = homeworkList.map((h) => jsonEncode(h.toJson())).toList();
    await prefs.setStringList('homework', data);
  }

  void _addHomework(Homework homework) async {
    setState(() {
      _homeworkList.add(homework);
    });
    await _saveHomework(_homeworkList);
    _scheduleNotification(homework);
    // Subjects might have changed if a new one was added in the Add screen?
    // Usually AddHomeworkScreen doesn't add subjects to prefs directly,
    // but if we want to be safe we can reload subjects or manage them in memory too.
    _loadSubjects();
  }

  void _updateHomework(int index, Homework updatedHomework) async {
    setState(() {
      _homeworkList[index] = updatedHomework;
    });
    await _saveHomework(_homeworkList);
    _scheduleNotification(updatedHomework); // Re-programar notificación
    _loadSubjects(); // Reload subjects
  }

  void _deleteHomework(int index) async {
    // Cancel notification if the task is deleted (optional but recommended)
    // flutterLocalNotificationsPlugin.cancel(list[index].id.hashCode & 0x7FFFFFFF);
    setState(() {
      _homeworkList.removeAt(index);
    });
    await _saveHomework(_homeworkList);
  }

  void _toggleCompleted(Homework homework) async {
    final index = _homeworkList.indexWhere((h) => h.id == homework.id);
    if (index != -1) {
      setState(() {
        _homeworkList[index].isCompleted = !_homeworkList[index].isCompleted;
      });

      await _saveHomework(_homeworkList);

      // Toggle notification logic
      if (_homeworkList[index].isCompleted) {
        final notificationId = homework.id.hashCode & 0x7FFFFFFF;
        await flutterLocalNotificationsPlugin.cancel(notificationId);
      } else {
        await _scheduleNotification(_homeworkList[index]);
      }
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
        // We need the index in the MAIN list (_homeworkList), not the filtered fullList passed here.
        // Actually fullList IS _homeworkList in the build method, so index is correct relative to _homeworkList structure?
        // Wait, fullList is passed from build. If we use _homeworkList directly we are safer.
        final mainIndex = _homeworkList.indexWhere((h) => h.id == homework.id);
        if (mainIndex != -1) {
          _updateHomework(mainIndex, updatedHomework);
        }
      }
    }
  }

  void _deleteFromFullList(Homework homework, List<Homework> fullList) {
    final index = _homeworkList.indexWhere((h) => h.id == homework.id);
    if (index != -1) {
      _deleteHomework(index);
    }
  }

  // ... (Your _groupHomeworkByDate function remains the same) ...
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
      'overdue': [],
      'today': [],
      'tomorrow': [],
      'week': [],
      'upcoming': [],
    };

    for (final hw in homeworkList) {
      if (hw.dueDate.isBefore(now)) {
        groups['overdue']!.add(hw);
      } else if (hw.dueDate.isAfter(now) && hw.dueDate.isBefore(todayEnd)) {
        groups['today']!.add(hw);
      } else if (hw.dueDate.isAfter(todayEnd) &&
          hw.dueDate.isBefore(tomorrowEnd)) {
        groups['tomorrow']!.add(hw);
      } else if (hw.dueDate.isAfter(tomorrowEnd) &&
          hw.dueDate.isBefore(endOfWeek)) {
        groups['week']!.add(hw);
      } else if (hw.dueDate.isAfter(endOfWeek)) {
        groups['upcoming']!.add(hw);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  void _confirmClearCompleted(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.clearCompletedTitle),
        content: Text(AppLocalizations.of(context)!.clearCompletedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearCompletedTasks();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              AppLocalizations.of(context)!.deleteAssignment,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _clearCompletedTasks() async {
    setState(() {
      _homeworkList.removeWhere((task) => task.isCompleted);
    });
    await _saveHomework(_homeworkList);
  }

  Future<void> _schedulePendingNotifications() async {
    final allTasks = await _loadHomework();
    final pendingTasks = allTasks.where((task) => !task.isCompleted).toList();
    for (final task in pendingTasks) {
      _scheduleNotification(task);
    }
  }

  Future<void> _scheduleNotification(Homework homework) async {
    // 1. Check if notifications are enabled for this task
    if (!homework.enableNotification) {
      final notificationId = homework.id.hashCode & 0x7FFFFFFF;
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      return;
    }

    // 2. Calculate scheduled date/time for the notification
    final scheduledDate = homework.dueDate.subtract(
      Duration(minutes: homework.notificationOffset),
    );
    final now = DateTime.now();

    // 3. If scheduled time is in the past, do nothing
    if (scheduledDate.isBefore(now)) return;

    final notificationId = homework.id.hashCode & 0x7FFFFFFF;

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Upcoming assignment: ${homework.title}',
        'Due ${DateFormat('MMM dd, hh:mm a').format(homework.dueDate)}',
        tz.TZDateTime.from(scheduledDate, tz.local), // Use local timezone
        const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            'Homework Notifications',
            channelDescription: 'Notifications for upcoming homework tasks',
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
        "Notification scheduled for: $scheduledDate (Due: ${homework.dueDate})",
      );
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  // NEW: helper to confirm & delete a subject
  Future<void> _deleteSubject(String subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteSubject),
        content: Text(
          AppLocalizations.of(context)!.deleteSubjectConfirmation(subject),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(context)!.deleteAssignment),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList('subjects') ?? [];
    current.remove(subject);
    await prefs.setStringList('subjects', current);

    // Remove icon
    final iconsJson = prefs.getString('subject_icons');
    if (iconsJson != null) {
      final icons = Map<String, dynamic>.from(jsonDecode(iconsJson));
      icons.remove(subject);
      await prefs.setString('subject_icons', jsonEncode(icons));
    }

    if (mounted) {
      setState(() {
        _subjects = current;
        _subjectIcons.remove(subject);
        // _homeworkFuture = _loadHomework(); // No longer needed
        // If we want to delete tasks associated with this subject, we should do it here?
        // Original code didn't seem to delete tasks, just the subject from the list.
      });
    }

    // Close drawer if still open
    Navigator.pop(context);

    // If user is viewing the deleted subject, go back to All tasks
    if (widget.subjectFilter == subject) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (ctx) => const HomeworkListScreen()),
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.showImportant
                ? AppLocalizations.of(context)!.important
                : (widget.subjectFilter ??
                      AppLocalizations.of(context)!.appTitle),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.pending),
              Tab(text: AppLocalizations.of(context)!.completed),
            ],
          ),
        ),
        drawer: Drawer(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: const BoxDecoration(color: Colors.blue),
                      child: Text(
                        AppLocalizations.of(context)!.subjects,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.list),
                      title: Text(AppLocalizations.of(context)!.allAssignments),
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        if (widget.subjectFilter != null ||
                            widget.showImportant) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const HomeworkListScreen(),
                            ),
                            (route) => route.isFirst,
                          );
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.priority_high,
                        color: Colors.red,
                      ),
                      title: Text(AppLocalizations.of(context)!.important),
                      onTap: () async {
                        Navigator.pop(context); // close drawer
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const HomeworkListScreen(showImportant: true),
                          ),
                        );
                        if (mounted) {
                          setState(() {
                            // _homeworkFuture = _loadHomework();
                            _loadSubjects();
                          });
                        }
                      },
                    ),
                    const Divider(),
                    if (_subjects.isEmpty)
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.noSavedSubjects,
                        ),
                      )
                    else
                      ..._subjects.map(
                        (subject) => ListTile(
                          leading: Icon(
                            _subjectIcons.containsKey(subject)
                                ? getIconFromCodePoint(_subjectIcons[subject]!)
                                : Icons.book,
                          ),
                          title: Text(subject),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteSubject(subject),
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    HomeworkListScreen(subjectFilter: subject),
                              ),
                            );
                            if (mounted) {
                              setState(() {
                                // _homeworkFuture = _loadHomework();
                                _loadSubjects();
                              });
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(),
              // Language Toggle moved to bottom
              ListTile(
                leading: const Icon(Icons.language, color: Colors.blue),
                title: Text(AppLocalizations.of(context)!.language),
                subtitle: Text(
                  Localizations.localeOf(context).languageCode == 'en'
                      ? 'English'
                      : 'Español',
                ),
                onTap: () {
                  Navigator.pop(context);
                  final current = Localizations.localeOf(context);
                  final newLocale = current.languageCode == 'en'
                      ? const Locale('es')
                      : const Locale('en');
                  MyApp.setLocale(context, newLocale);
                },
              ),
              const SizedBox(height: 16), // Bottom padding
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
          label: Text(
            AppLocalizations.of(context)!.newButton,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: Builder(
          builder: (context) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final allHomework = _homeworkList;

            // Filter according to subjectFilter or important flag
            late final List<Homework> filteredHomework;
            if (widget.showImportant) {
              filteredHomework = allHomework
                  .where((h) => h.isImportant)
                  .toList();
            } else if (widget.subjectFilter != null) {
              filteredHomework = allHomework
                  .where((h) => h.subject == widget.subjectFilter)
                  .toList();
            } else {
              filteredHomework = allHomework;
            }

            final pending = filteredHomework
                .where((h) => !h.isCompleted)
                .toList();
            final completed = filteredHomework
                .where((h) => h.isCompleted)
                .toList();

            // NEW: sort important first, then by due date
            int importanceCompare(Homework a, Homework b) {
              if (a.isImportant && !b.isImportant) return -1;
              if (!a.isImportant && b.isImportant) return 1;
              return a.dueDate.compareTo(b.dueDate);
            }

            pending.sort(importanceCompare);
            completed.sort(importanceCompare);

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
              ? AppLocalizations.of(context)!.noPendingAssignments
              : AppLocalizations.of(context)!.noCompletedAssignments,
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

          String displayTitle;

          switch (sectionTitle) {
            case 'overdue':
              displayTitle = AppLocalizations.of(context)!.sectionOverdue;
              textColor = Colors.red[800]!;
              icon = Icons.hourglass_empty;
              fontSize = 23;
              break;
            case 'today':
              displayTitle = AppLocalizations.of(context)!.sectionToday;
              textColor = Colors.red;
              icon = Icons.warning;
              fontSize = 23;
              break;
            case 'tomorrow':
              displayTitle = AppLocalizations.of(context)!.sectionTomorrow;
              textColor = Colors.orange;
              icon = Icons.calendar_today;
              fontSize = 23;
              break;
            case 'week':
              displayTitle = AppLocalizations.of(context)!.sectionThisWeek;
              textColor = const Color.fromARGB(250, 245, 225, 10);
              icon = Icons.calendar_view_week;
              fontSize = 23;
              break;
            case 'upcoming':
              displayTitle = AppLocalizations.of(context)!.sectionUpcoming;
              textColor = const Color(0xFF00bb2d);
              icon = Icons.date_range;
              fontSize = 23;
              break;
            default:
              displayTitle = sectionTitle;
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
                      displayTitle,
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
                  'MMM dd, yyyy - hh:mm a',
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
                    title: Row(
                      children: [
                        if (hw.isImportant)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Text(
                              '!!!', // choose '!' or '!!!'
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            hw.title,
                            style: TextStyle(
                              decoration: hw.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${hw.subject} ',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(
                                  _subjectIcons.containsKey(hw.subject)
                                      ? getIconFromCodePoint(
                                          _subjectIcons[hw.subject]!,
                                        )
                                      : Icons.book,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              TextSpan(
                                text: ' • $formattedDate',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                          // overflow: TextOverflow.ellipsis, // Allow wrapping so time is visible
                        ),
                        if (hw.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              hw.description,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
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
        return Center(child: Text('No completed assignments'));
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
                label: Text(
                  AppLocalizations.of(context)!.clearCompletedButton,
                  style: const TextStyle(
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
              title: Row(
                children: [
                  if (hw.isImportant)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Text(
                        '!!!',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      hw.title,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${hw.subject} ',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        _subjectIcons.containsKey(hw.subject)
                            ? getIconFromCodePoint(_subjectIcons[hw.subject]!)
                            : Icons.book,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    TextSpan(
                      text: ' • $formattedDate',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                // overflow: TextOverflow.ellipsis, // Allow wrapping so time is visible
              ),
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

// Add/Edit Homework Screen

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
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _enableNotification = true;
  int _notificationOffset = 0;
  // NEW: important flag for the form
  bool _isImportant = false;

  List<String> _subjects = [];
  Map<String, int> _subjectIcons = {};
  String? _selectedSubject;
  final String _createNewSubjectLabel = 'Create new subject...';

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    if (widget.homework != null) {
      _titleController = TextEditingController(text: widget.homework!.title);
      _subjectController = TextEditingController(
        text: widget.homework!.subject,
      );
      _descriptionController = TextEditingController(
        text: widget.homework!.description,
      );
      _selectedSubject = widget.homework!.subject;
      _selectedDate = widget.homework!.dueDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.homework!.dueDate);
      _enableNotification = widget.homework!.enableNotification;
      _notificationOffset = widget.homework!.notificationOffset;
      _isImportant = widget.homework!.isImportant; // load existing flag
    } else {
      _titleController = TextEditingController();
      _subjectController = TextEditingController();
      _descriptionController = TextEditingController();
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = TimeOfDay.now();
      _enableNotification = true;
      _notificationOffset = 0;
      _isImportant = false;
    }
  }

  Future<void> _loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _subjects = prefs.getStringList('subjects') ?? [];
      final iconsJson = prefs.getString('subject_icons');
      if (iconsJson != null) {
        _subjectIcons = Map<String, int>.from(jsonDecode(iconsJson));
      }
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
    await prefs.setString('subject_icons', jsonEncode(_subjectIcons));
  }

  Future<void> _addNewSubject() async {
    // Define available icons
    final List<IconData> availableIcons = kAvailableIcons;

    IconData selectedIcon = Icons.book;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        String value = '';
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.createNewSubject),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.subjectName,
                        ),
                        onChanged: (text) {
                          value = text;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.selectIcon,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: availableIcons.length,
                        itemBuilder: (context, index) {
                          final icon = availableIcons[index];
                          final isSelected = selectedIcon == icon;
                          return InkWell(
                            onTap: () {
                              setState(() => selectedIcon = icon);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue.withOpacity(0.2)
                                    : null,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.blue, width: 2)
                                    : null,
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? Colors.blue : Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, {
                    'name': value,
                    'icon': selectedIcon.codePoint,
                  }),
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null &&
        result['name'] != null &&
        result['name'].toString().trim().isNotEmpty) {
      final newSubject = result['name'].toString().trim();
      final iconCodePoint = result['icon'] as int;

      setState(() {
        if (!_subjects.contains(newSubject)) {
          _subjects.add(newSubject);
          _subjectIcons[newSubject] = iconCodePoint;
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
    _descriptionController.dispose();
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
        title: Text(
          widget.homework != null
              ? AppLocalizations.of(context)!.update
              : AppLocalizations.of(context)!.newButton,
        ), // Simplified: leveraging Update/New strings, or could add dedicated Edit/Add Homework strings
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.title,
                    ),
                    validator: (value) => value?.isEmpty == true
                        ? AppLocalizations.of(context)!.enterTitleValidator
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _subjects.contains(_selectedSubject)
                        ? _selectedSubject
                        : null,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.subject,
                    ),
                    items: [
                      ..._subjects.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s)),
                      ),
                      DropdownMenuItem(
                        value: _createNewSubjectLabel,
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 20),
                            SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.createNewSubject,
                            ),
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
                        ? AppLocalizations.of(context)!.selectSubjectValidator
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // MOVED: single-line description field (same style as title)
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.description,
                    ),
                    // optional: no validator so it's not required
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: Text(AppLocalizations.of(context)!.dueDate),
                          subtitle: Text(
                            DateFormat('MMM dd, yyyy').format(_selectedDate),
                          ),
                          onTap: () => _selectDate(context),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: Text(AppLocalizations.of(context)!.dueTime),
                          subtitle: Text(_selectedTime.format(context)),
                          onTap: () => _selectTime(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: Text(
                      AppLocalizations.of(context)!.receiveNotification,
                    ),
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
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        )!.notificationOffset,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Text(AppLocalizations.of(context)!.atDueTime),
                        ),
                        DropdownMenuItem(
                          value: 10,
                          child: Text(
                            AppLocalizations.of(context)!.minutesBefore(10),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text(
                            AppLocalizations.of(context)!.minutesBefore(30),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text(AppLocalizations.of(context)!.hourBefore),
                        ),
                        DropdownMenuItem(
                          value: 120,
                          child: Text(
                            AppLocalizations.of(context)!.hoursBefore(2),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 1440,
                          child: Text(AppLocalizations.of(context)!.dayBefore),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _notificationOffset = value;
                          });
                        }
                      },
                    ),
                  const SizedBox(height: 20),
                  // NEW: important toggle
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.markAsImportant),
                    value: _isImportant,
                    onChanged: (value) {
                      setState(() {
                        _isImportant = value;
                      });
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
                          isImportant: _isImportant, // pass flag
                          description: _descriptionController.text.trim(),
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
                    child: Text(
                      widget.homework != null
                          ? AppLocalizations.of(context)!.update
                          : AppLocalizations.of(context)!.save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

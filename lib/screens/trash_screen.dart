import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:homework_app/l10n/app_localizations.dart';
import 'package:homework_app/models/homework.dart';
import 'package:homework_app/services/homework_service.dart';
import 'package:homework_app/services/notification_service.dart';
import 'package:homework_app/icons_helper.dart';
import 'package:homework_app/main.dart';
import 'package:homework_app/screens/homework_list_screen.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  bool _isLoading = true;
  List<Homework> _deletedTasks = [];
  List<String> _subjects = [];
  Map<String, int> _subjectIcons = {};

  @override
  void initState() {
    super.initState();
    _loadDeletedTasks();
    _loadSubjects();
  }

  Future<void> _loadDeletedTasks() async {
    setState(() {
      _isLoading = true;
    });
    final all = await HomeworkService.loadHomework();
    setState(() {
      _deletedTasks = all.where((t) => t.isDeleted).toList();
      _isLoading = false;
    });
  }

  Future<void> _loadSubjects() async {
    final subjects = await HomeworkService.loadSubjects();
    final icons = await HomeworkService.loadSubjectIcons();
    setState(() {
      _subjects = subjects;
      _subjectIcons = icons;
    });
  }

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

  Future<void> _restoreTask(Homework task) async {
    final all = await HomeworkService.loadHomework();
    final index = all.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    all[index].isDeleted = false;
    await HomeworkService.saveHomework(all);
    await NotificationService.scheduleNotification(all[index]);
    await _loadDeletedTasks();
  }

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

    await HomeworkService.deleteSubject(subject);

    if (mounted) {
      setState(() {
        _subjects.remove(subject);
        _subjectIcons.remove(subject);
      });
    }
  }

  Future<void> _confirmDeleteForever(Homework task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDeleteForeverTitle),
        content: Text(AppLocalizations.of(context)!
            .confirmDeleteForeverMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppLocalizations.of(context)!.deleteForever,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _deleteForever(task);
  }

  Future<void> _deleteForever(Homework task) async {
    final all = await HomeworkService.loadHomework();
    all.removeWhere((t) => t.id == task.id);
    await HomeworkService.saveHomework(all);
    await NotificationService.cancelNotification(task.id);
    await _loadDeletedTasks();
  }

  Future<void> _emptyTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.emptyTrashTitle),
        content: Text(AppLocalizations.of(context)!.emptyTrashMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppLocalizations.of(context)!.deleteForever,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final all = await HomeworkService.loadHomework();
    all.removeWhere((t) => t.isDeleted);
    await HomeworkService.saveHomework(all);
    for (final task in _deletedTasks) {
      await NotificationService.cancelNotification(task.id);
    }
    await _loadDeletedTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.trash),
        actions: [
          if (!_isLoading && _deletedTasks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: AppLocalizations.of(context)!.emptyTrash,
              onPressed: _emptyTrash,
            ),
        ],
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
                      Navigator.pop(context);
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (ctx) => const HomeworkListScreen(),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.priority_high,
                      color: Colors.red,
                    ),
                    title: Text(AppLocalizations.of(context)!.important),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const HomeworkListScreen(showImportant: true),
                        ),
                      );
                      if (mounted) {
                        _loadSubjects();
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.grey),
                    title: Text(AppLocalizations.of(context)!.trash),
                    onTap: () {
                      Navigator.pop(context);
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
                            _loadSubjects();
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
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
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_deletedTasks.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.emptyTrash),
            );
          }

          final grouped = _groupHomeworkByDate(_deletedTasks);
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
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
                                    child: Text(hw.title),
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
                                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                                            color: Theme.of(context).colorScheme.outline,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' • $formattedDate',
                                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (hw.description.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        hw.description,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.restore, color: Colors.green),
                                    tooltip: AppLocalizations.of(context)!.restore,
                                    onPressed: () => _restoreTask(hw),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever,
                                        color: Colors.red),
                                    tooltip: AppLocalizations.of(context)!.deleteForever,
                                    onPressed: () => _confirmDeleteForever(hw),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Text(
                  AppLocalizations.of(context)!.autoDeleteMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

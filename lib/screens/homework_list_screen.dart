import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:homework_app/utils/date_formatter.dart';
import 'package:homework_app/l10n/app_localizations.dart';
import 'package:homework_app/models/homework.dart';
import 'package:homework_app/services/homework_service.dart';
import 'package:homework_app/services/notification_service.dart';
import 'package:homework_app/icons_helper.dart';
import 'package:homework_app/main.dart';
import 'package:homework_app/screens/trash_screen.dart';
import 'package:in_app_review/in_app_review.dart';
import 'add_homework_screen.dart';

class HomeworkListScreen extends StatefulWidget {
  final String? subjectFilter;
  final bool showImportant;

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
    NotificationService.requestNotificationsPermission();
    _schedulePendingNotifications();

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadSubjects();
    final loaded = await HomeworkService.loadHomework();
    setState(() {
      _homeworkList = loaded;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final subjects = await HomeworkService.loadSubjects();
    final icons = await HomeworkService.loadSubjectIcons();
    setState(() {
      _subjects = subjects;
      _subjectIcons = icons;
    });
  }

  void _addHomework(Homework homework) async {
    setState(() {
      _homeworkList.add(homework);
    });
    await HomeworkService.saveHomework(_homeworkList);
    await NotificationService.scheduleNotification(homework);
    _loadSubjects();
    _checkAndRequestReview();
  }

  Future<void> _checkAndRequestReview() async {
    final prefs = await SharedPreferences.getInstance();
    // Increment the number of times a homework has been added.
    int homeworkAddedCount = (prefs.getInt('homeworkAddedCount') ?? 0) + 1;
    await prefs.setInt('homeworkAddedCount', homeworkAddedCount);

    // If exactly 5 tasks have been added, trigger the review prompt.
    if (homeworkAddedCount == 5) {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        inAppReview.requestReview();
      }
    }
  }

  void _updateHomework(int index, Homework updatedHomework) async {
    setState(() {
      _homeworkList[index] = updatedHomework;
    });
    await HomeworkService.saveHomework(_homeworkList);
    await NotificationService.scheduleNotification(updatedHomework);
    _loadSubjects();
  }

  void _deleteHomework(int index) async {
    setState(() {
      _homeworkList[index].isDeleted = true;
      _homeworkList[index].deletedAt = DateTime.now();
    });
    await HomeworkService.saveHomework(_homeworkList);
    await NotificationService.cancelNotification(_homeworkList[index].id);
  }

  void _toggleCompleted(Homework homework) async {
    final index = _homeworkList.indexWhere((h) => h.id == homework.id);
    if (index != -1) {
      setState(() {
        _homeworkList[index].isCompleted = !_homeworkList[index].isCompleted;
      });

      await HomeworkService.saveHomework(_homeworkList);

      if (_homeworkList[index].isCompleted) {
        await NotificationService.cancelNotification(homework.id);
      } else {
        await NotificationService.scheduleNotification(_homeworkList[index]);
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
      final mainIndex = _homeworkList.indexWhere((h) => h.id == homework.id);
      if (mainIndex != -1) {
        _updateHomework(mainIndex, updatedHomework);
      }
    }
  }

  void _deleteFromFullList(Homework homework, List<Homework> fullList) {
    final index = _homeworkList.indexWhere((h) => h.id == homework.id);
    if (index != -1) {
      _deleteHomework(index);
    }
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
      'no_date': [],
    };

    for (final hw in homeworkList) {
      if (!hw.hasDueDate) {
        groups['no_date']!.add(hw);
      } else if (hw.dueDate.isBefore(now)) {
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
    final now = DateTime.now();
    setState(() {
      for (final task in _homeworkList) {
        if (task.isCompleted) {
          task.isDeleted = true;
          task.deletedAt = now;
        }
      }
    });
    await HomeworkService.saveHomework(_homeworkList);
  }

  Future<void> _schedulePendingNotifications() async {
    final allTasks = await HomeworkService.loadHomework();
    final pendingTasks = allTasks.where((t) => !t.isDeleted).toList();
    await NotificationService.schedulePendingNotifications(pendingTasks);
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
      Navigator.pop(context);

      if (widget.subjectFilter == subject) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const HomeworkListScreen()),
          (route) => route.isFirst,
        );
      }
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
                        Navigator.pop(context);
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
                        Navigator.pop(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const HomeworkListScreen(showImportant: true),
                          ),
                        );
                        if (mounted) {
                          setState(() {
                            _loadSubjects();
                          });
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.grey),
                      title: Text(AppLocalizations.of(context)!.trash),
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TrashScreen(),
                          ),
                        );
                        if (mounted) {
                          _loadData();
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
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode, color: Colors.blue),
                title: Text(AppLocalizations.of(context)!.darkMode),
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (bool value) {
                  MyApp.setThemeMode(
                    context,
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text(AppLocalizations.of(context)!.rateApp),
                onTap: () async {
                  Navigator.pop(context);
                  final InAppReview inAppReview = InAppReview.instance;
                  if (await inAppReview.isAvailable()) {
                    inAppReview.requestReview();
                  }
                },
              ),
              const SizedBox(height: 16),
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
            final allHomework = _homeworkList.where((h) => !h.isDeleted).toList();

            late final List<Homework> filteredHomework;
            if (widget.showImportant) {
              filteredHomework = allHomework.where((h) => h.isImportant).toList();
            } else if (widget.subjectFilter != null) {
              filteredHomework = allHomework
                  .where((h) => h.subject == widget.subjectFilter)
                  .toList();
            } else {
              filteredHomework = allHomework;
            }

            final pending = filteredHomework.where((h) => !h.isCompleted).toList();
            final completed = filteredHomework.where((h) => h.isCompleted).toList();

            int importanceCompare(Homework a, Homework b) {
              if (a.isImportant && !b.isImportant) return -1;
              if (!a.isImportant && b.isImportant) return 1;
              if (a.hasDueDate && !b.hasDueDate) return -1;
              if (!a.hasDueDate && b.hasDueDate) return 1;
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
              displayTitle = AppLocalizations.of(context)!.sectionNext7Days;
              textColor = const Color.fromARGB(250, 245, 225, 10);
              icon = Icons.calendar_view_week;
              fontSize = 23;
              break;
            case 'upcoming':
              displayTitle = AppLocalizations.of(context)!.sectionLater;
              textColor = const Color(0xFF00bb2d);
              icon = Icons.date_range;
              fontSize = 23;
              break;
            case 'no_date':
              displayTitle = AppLocalizations.of(context)!.sectionNoDate;
              textColor = Colors.grey;
              icon = Icons.event_busy;
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
                final formattedDate = SmartDateFormatter.formatForCard(hw.dueDate, sectionTitle);
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
                              if (hw.hasDueDate)
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
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteFromFullList(hw, fullList),
                    ),
                  ),
                );
              }),
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
          final formattedDate = SmartDateFormatter.formatForCompletedCard(hw.dueDate);
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
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        _subjectIcons.containsKey(hw.subject)
                            ? getIconFromCodePoint(_subjectIcons[hw.subject]!)
                            : Icons.book,
                        size: 16,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    if (hw.hasDueDate)
                      TextSpan(
                        text: ' • $formattedDate',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
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

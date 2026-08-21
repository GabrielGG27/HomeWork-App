import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homework_app/l10n/app_localizations.dart';
import 'package:homework_app/models/homework.dart';
import 'package:homework_app/models/attachment.dart';
import 'package:homework_app/widgets/attachment_picker.dart';
import 'package:homework_app/services/attachment_storage_service.dart';
import 'package:homework_app/icons_helper.dart';
import 'package:homework_app/services/notification_service.dart';
import 'package:homework_app/services/homework_service.dart';
import 'package:homework_app/widgets/onboarding_message_card.dart';

class AddHomeworkScreen extends StatefulWidget {
  final Homework? homework;
  final bool startWalkthrough;

  const AddHomeworkScreen({
    super.key,
    this.homework,
    this.startWalkthrough = false,
  });

  @override
  State<AddHomeworkScreen> createState() => _AddHomeworkScreenState();
}

class _AddHomeworkScreenState extends State<AddHomeworkScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _titleTutorialKey = GlobalKey();
  final GlobalKey _subjectTutorialKey = GlobalKey();
  final GlobalKey _detailsTutorialKey = GlobalKey();
  final GlobalKey _scheduleTutorialKey = GlobalKey();
  final GlobalKey _notificationTutorialKey = GlobalKey();
  final GlobalKey _importanceTutorialKey = GlobalKey();
  final GlobalKey _saveTutorialKey = GlobalKey();
  late TextEditingController _titleController;
  late TextEditingController _subjectController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _enableNotification = true;
  List<int> _notificationOffsets = <int>[0];
  int _notificationFieldsRevision = 0;
  bool _isImportant = false;
  bool _hasDueDate = true;

  List<Attachment> _attachments = [];
  late final Set<String> _initialAttachmentIds;
  bool _didSubmit = false;
  bool _isSubmitting = false;

  List<String> _subjects = [];
  Map<String, int> _subjectIcons = {};
  String? _selectedSubject;
  final String _createNewSubjectLabel = 'Create new subject...';
  int? _firstTaskTutorialStep;

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
      _notificationOffsets = widget.homework!.notificationOffsets.isEmpty
          ? <int>[0]
          : List<int>.from(widget.homework!.notificationOffsets);
      _isImportant = widget.homework!.isImportant;
      _hasDueDate = widget.homework!.hasDueDate;
      _attachments = widget.homework!.attachments;
    } else {
      _titleController = TextEditingController();
      _subjectController = TextEditingController();
      _descriptionController = TextEditingController();
      final now = DateTime.now();
      _selectedDate = widget.startWalkthrough
          ? DateTime(now.year, now.month, now.day + 1)
          : DateTime(now.year, now.month, now.day);
      _selectedTime = widget.startWalkthrough
          ? const TimeOfDay(hour: 18, minute: 0)
          : TimeOfDay.now();
      _enableNotification = widget.startWalkthrough ? false : true;
      _notificationOffsets = <int>[0];
      _isImportant = false;
      _hasDueDate = true;
      _attachments = [];
    }
    _initialAttachmentIds = _attachments.map((a) => a.id).toSet();
    if (widget.startWalkthrough && widget.homework == null) {
      _firstTaskTutorialStep = 0;
    }
  }

  List<({GlobalKey key, IconData icon, String title, String description})>
  _tutorialSteps(AppLocalizations l10n) => [
    (
      key: _titleTutorialKey,
      icon: Icons.title_rounded,
      title: l10n.walkthroughTaskTitleTitle,
      description: l10n.walkthroughTaskTitleDescription,
    ),
    (
      key: _subjectTutorialKey,
      icon: Icons.auto_stories_rounded,
      title: l10n.walkthroughTaskSubjectTitle,
      description: l10n.walkthroughTaskSubjectDescription,
    ),
    (
      key: _detailsTutorialKey,
      icon: Icons.notes_rounded,
      title: l10n.firstTaskDetailsTitle,
      description: l10n.firstTaskDetailsDescription,
    ),
    (
      key: _scheduleTutorialKey,
      icon: Icons.event_available_rounded,
      title: l10n.firstTaskScheduleTitle,
      description: l10n.firstTaskScheduleDescription,
    ),
    (
      key: _notificationTutorialKey,
      icon: Icons.notifications_active_rounded,
      title: l10n.firstTaskReminderTitle,
      description: l10n.firstTaskReminderDescription,
    ),
    (
      key: _importanceTutorialKey,
      icon: Icons.priority_high_rounded,
      title: l10n.firstTaskImportanceTitle,
      description: l10n.firstTaskImportanceDescription,
    ),
    (
      key: _saveTutorialKey,
      icon: Icons.task_alt_rounded,
      title: l10n.firstTaskSaveTitle,
      description: l10n.firstTaskSaveDescription,
    ),
  ];

  bool get _canAdvanceTutorial => switch (_firstTaskTutorialStep) {
    0 => _titleController.text.trim().isNotEmpty,
    1 => _subjectController.text.trim().isNotEmpty,
    _ => true,
  };

  Future<void> _advanceTutorial() async {
    final current = _firstTaskTutorialStep;
    if (current == null || !_canAdvanceTutorial) return;
    final l10n = AppLocalizations.of(context)!;
    final steps = _tutorialSteps(l10n);
    if (current >= steps.length - 1) {
      setState(() => _firstTaskTutorialStep = null);
      return;
    }
    final next = current + 1;
    setState(() => _firstTaskTutorialStep = next);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    final targetContext = steps[next].key.currentContext;
    if (targetContext != null && targetContext.mounted) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: 0.2,
      );
    }
  }

  Widget _tutorialTarget({
    required int step,
    required GlobalKey key,
    required Widget child,
  }) {
    final active = _firstTaskTutorialStep == step;
    final locked = _firstTaskTutorialStep != null && !active;
    return IgnorePointer(
      ignoring: locked,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: locked ? 0.34 : 1,
        child: KeyedSubtree(
          key: key,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: active
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _tutorialCompanion({required int step, required Widget child}) {
    final locked =
        _firstTaskTutorialStep != null && _firstTaskTutorialStep != step;
    return IgnorePointer(
      ignoring: locked,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: locked ? 0.34 : 1,
        child: child,
      ),
    );
  }

  Widget _buildTutorialCard(AppLocalizations l10n) {
    final current = _firstTaskTutorialStep!;
    final step = _tutorialSteps(l10n)[current];
    final isLastStep = current == _tutorialSteps(l10n).length - 1;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Center(
        heightFactor: 1,
        child: OnboardingMessageCard(
          icon: step.icon,
          title: step.title,
          description: step.description,
          compact: true,
          actions: isLastStep
              ? null
              : SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canAdvanceTutorial ? _advanceTutorial : null,
                    child: Text(l10n.next),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _loadSubjects() async {
    final subjects = await HomeworkService.loadSubjects();
    final subjectIcons = await HomeworkService.loadSubjectIcons();
    if (!mounted) return;
    setState(() {
      _subjects = subjects;
      _subjectIcons = subjectIcons;
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
                                    ? Colors.blue.withValues(alpha: 0.2)
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

    if (!mounted) return;
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
      setState(() {
        _selectedSubject = _subjectController.text.isNotEmpty
            ? _subjectController.text
            : null;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (!_didSubmit) {
      final stagedAttachments = _attachments.where(
        (attachment) => !_initialAttachmentIds.contains(attachment.id),
      );
      unawaited(AttachmentStorageService.deleteManagedFiles(stagedAttachments));
    }
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
    if (!mounted) return;
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  static const List<int> _notificationPresets = <int>[0, 10, 30, 60, 120, 1440];

  String _notificationOffsetLabel(AppLocalizations l10n, int minutes) {
    if (minutes == 0) return l10n.atDueTime;
    if (minutes % 1440 == 0) {
      final days = minutes ~/ 1440;
      return days == 1 ? l10n.dayBefore : l10n.daysBefore(days);
    }
    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return hours == 1 ? l10n.hourBefore : l10n.hoursBefore(hours);
    }
    if (minutes == 1) return l10n.minuteBefore;
    return l10n.minutesBefore(minutes);
  }

  void _setNotificationOffset(int index, int minutes) {
    if (_notificationOffsets.indexed.any(
      (entry) => entry.$1 != index && entry.$2 == minutes,
    )) {
      setState(() => _notificationFieldsRevision++);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.remindersMustBeDifferent),
        ),
      );
      return;
    }
    setState(() {
      _notificationOffsets[index] = minutes;
      _notificationFieldsRevision++;
    });
  }

  Future<void> _chooseCustomNotificationOffset(int index) async {
    final l10n = AppLocalizations.of(context)!;
    final currentMinutes = _notificationOffsets[index];
    var selectedUnit = currentMinutes > 0 && currentMinutes % 1440 == 0
        ? 1440
        : currentMinutes > 0 && currentMinutes % 60 == 0
        ? 60
        : 1;
    final initialAmount = currentMinutes <= 0
        ? 1
        : currentMinutes ~/ selectedUnit;
    final controller = TextEditingController(text: '$initialAmount');
    String? errorText;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.customReminder),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.timeAmount,
                    errorText: errorText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: selectedUnit,
                items: [
                  DropdownMenuItem(value: 1, child: Text(l10n.minutes)),
                  DropdownMenuItem(value: 60, child: Text(l10n.hours)),
                  DropdownMenuItem(value: 1440, child: Text(l10n.days)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedUnit = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final amount = int.tryParse(controller.text);
                if (amount == null || amount <= 0) {
                  setDialogState(() => errorText = l10n.enterPositiveNumber);
                  return;
                }
                Navigator.pop(dialogContext, amount * selectedUnit);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (!mounted) return;
    if (result == null) {
      setState(() => _notificationFieldsRevision++);
      return;
    }
    _setNotificationOffset(index, result);
  }

  Widget _buildNotificationOffsetField(AppLocalizations l10n, int index) {
    final current = _notificationOffsets[index];
    final values = <int>[
      ..._notificationPresets,
      if (!_notificationPresets.contains(current)) current,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            key: ValueKey(
              'reminder-$index-$current-$_notificationFieldsRevision',
            ),
            initialValue: current,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.reminderNumber(index + 1),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            items: [
              ...values.map(
                (minutes) => DropdownMenuItem(
                  value: minutes,
                  child: Text(
                    _notificationOffsetLabel(l10n, minutes),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DropdownMenuItem(value: -1, child: Text(l10n.customReminder)),
            ],
            onChanged: (value) {
              if (value == null) return;
              if (value == -1) {
                _chooseCustomNotificationOffset(index);
              } else {
                _setNotificationOffset(index, value);
              }
            },
          ),
        ),
        if (index > 0) ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: l10n.removeReminder,
            onPressed: () {
              setState(() => _notificationOffsets.removeAt(index));
            },
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.homework != null
              ? AppLocalizations.of(context)!.update
              : AppLocalizations.of(context)!.newButton,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                bottom: _firstTaskTutorialStep == null ? 0 : 24,
              ),
              child: Column(
                children: [
                  _tutorialTarget(
                    step: 0,
                    key: _titleTutorialKey,
                    child: TextFormField(
                      controller: _titleController,
                      onChanged: (_) {
                        if (_firstTaskTutorialStep == 0) setState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.title,
                      ),
                      validator: (value) => value?.isEmpty == true
                          ? AppLocalizations.of(context)!.enterTitleValidator
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _tutorialTarget(
                    step: 1,
                    key: _subjectTutorialKey,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_selectedSubject),
                      initialValue: _subjects.contains(_selectedSubject)
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
                              const Icon(Icons.add, size: 20),
                              const SizedBox(width: 8),
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
                  ),
                  const SizedBox(height: 16),
                  _tutorialTarget(
                    step: 2,
                    key: _detailsTutorialKey,
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.description,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _tutorialCompanion(
                    step: 2,
                    child: AttachmentPicker(
                      initialAttachments: _attachments,
                      onChanged: (list) => setState(() => _attachments = list),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _tutorialTarget(
                    step: 3,
                    key: _scheduleTutorialKey,
                    child: SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.hasDueDate),
                      value: _hasDueDate,
                      onChanged: (value) {
                        setState(() {
                          _hasDueDate = value;
                        });
                      },
                    ),
                  ),
                  if (_hasDueDate) ...[
                    _tutorialCompanion(
                      step: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: Text(
                                AppLocalizations.of(context)!.dueDate,
                              ),
                              subtitle: Text(
                                DateFormat(
                                  'MMM dd, yyyy',
                                ).format(_selectedDate),
                              ),
                              onTap: () => _selectDate(context),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: Text(
                                AppLocalizations.of(context)!.dueTime,
                              ),
                              subtitle: Text(_selectedTime.format(context)),
                              onTap: () => _selectTime(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _tutorialTarget(
                      step: 4,
                      key: _notificationTutorialKey,
                      child: SwitchListTile(
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
                    ),
                    if (_enableNotification)
                      _tutorialCompanion(
                        step: 4,
                        child: Column(
                          children: [
                            for (
                              var index = 0;
                              index < _notificationOffsets.length;
                              index++
                            ) ...[
                              _buildNotificationOffsetField(l10n, index),
                              if (index < _notificationOffsets.length - 1)
                                const SizedBox(height: 12),
                            ],
                            if (_notificationOffsets.length < 2)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () {
                                    final defaultOffset =
                                        _notificationOffsets.contains(60)
                                        ? 0
                                        : 60;
                                    setState(
                                      () => _notificationOffsets.add(
                                        defaultOffset,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add_alert_rounded),
                                  label: Text(l10n.addReminder),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                  _tutorialTarget(
                    step: 5,
                    key: _importanceTutorialKey,
                    child: SwitchListTile(
                      title: Text(
                        AppLocalizations.of(context)!.markAsImportant,
                      ),
                      value: _isImportant,
                      onChanged: (value) {
                        setState(() {
                          _isImportant = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  _tutorialTarget(
                    step: 6,
                    key: _saveTutorialKey,
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate() &&
                                  _subjectController.text.isNotEmpty) {
                                setState(() => _isSubmitting = true);
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
                                  hasDueDate: _hasDueDate,
                                  isCompleted:
                                      widget.homework?.isCompleted ?? false,
                                  notificationOffsets:
                                      _hasDueDate && _enableNotification
                                      ? List<int>.from(_notificationOffsets)
                                      : const <int>[],
                                  isImportant: _isImportant,
                                  description: _descriptionController.text
                                      .trim(),
                                  attachments: _attachments,
                                );
                                if (_hasDueDate && _enableNotification) {
                                  await NotificationService.requestNotificationsPermission();
                                  if (!context.mounted) return;
                                }
                                _didSubmit = true;
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _firstTaskTutorialStep == null
          ? null
          : SafeArea(
              top: false,
              maintainBottomViewPadding: true,
              child: _buildTutorialCard(l10n),
            ),
    );
  }
}

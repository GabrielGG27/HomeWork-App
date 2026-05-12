import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homework_app/l10n/app_localizations.dart';
import 'package:homework_app/models/homework.dart';
import 'package:homework_app/models/attachment.dart';
import 'package:homework_app/widgets/attachment_picker.dart';
import 'package:homework_app/icons_helper.dart';

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
  bool _isImportant = false;

  List<Attachment> _attachments = [];

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
      _isImportant = widget.homework!.isImportant;
      _attachments = widget.homework!.attachments;

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
      _attachments = []; 
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
        ),
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.description,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AttachmentPicker(
                    initialAttachments: _attachments,
                    onChanged: (list) => setState(() => _attachments = list),
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
                      key: ValueKey(_notificationOffset),
                      initialValue: _notificationOffset,
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
                          isImportant: _isImportant,
                          description: _descriptionController.text.trim(),
                          attachments: _attachments,
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

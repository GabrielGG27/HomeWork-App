// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HomeWork App';

  @override
  String get pending => 'Pending';

  @override
  String get completed => 'Completed';

  @override
  String get subjects => 'Subjects';

  @override
  String get allAssignments => 'All Assignments';

  @override
  String get important => 'Important';

  @override
  String get noSavedSubjects => 'No saved subjects';

  @override
  String get newButton => 'New';

  @override
  String get deleteAssignment => 'Delete';

  @override
  String get trash => 'Trash';

  @override
  String get restore => 'Restore';

  @override
  String get deleteForever => 'Delete forever';

  @override
  String get confirmDeleteForeverTitle => 'Delete permanently?';

  @override
  String get confirmDeleteForeverMessage =>
      'This will permanently delete this task. This action cannot be undone.';

  @override
  String get emptyTrash => 'Empty trash';

  @override
  String get emptyTrashTitle => 'Empty trash?';

  @override
  String get emptyTrashMessage =>
      'This will permanently delete all tasks in the trash. This action cannot be undone.';

  @override
  String get autoDeleteMessage =>
      'Tasks in trash will be permanently deleted after 30 days.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get update => 'Update';

  @override
  String get title => 'Title';

  @override
  String get subject => 'Subject';

  @override
  String get description => 'Description';

  @override
  String get dueDate => 'Due Date';

  @override
  String get dueTime => 'Due Time';

  @override
  String get receiveNotification => 'Receive notification';

  @override
  String get notificationOffset => 'Notification Offset';

  @override
  String get markAsImportant => 'Mark as important';

  @override
  String get deleteSubject => 'Delete Subject';

  @override
  String deleteSubjectConfirmation(String subject) {
    return 'Delete the subject \"$subject\"? This action will remove the subject from the subject list. Tasks will not be automatically deleted.';
  }

  @override
  String get clearCompletedTitle => 'Clear Completed Assignments?';

  @override
  String get clearCompletedMessage =>
      'All completed assignments will be moved to the trash. You can restore them from there.';

  @override
  String get clearCompletedButton => 'Clear completed assignments';

  @override
  String get noPendingAssignments => 'No pending assignments';

  @override
  String get noCompletedAssignments => 'No completed assignments';

  @override
  String get sectionOverdue => 'Overdue';

  @override
  String get sectionToday => 'Today';

  @override
  String get sectionTomorrow => 'Tomorrow';

  @override
  String get sectionNext7Days => 'Next 7 Days';

  @override
  String get sectionLater => 'Later';

  @override
  String get createNewSubject => 'Create new subject...';

  @override
  String get selectIcon => 'Select Icon:';

  @override
  String get subjectName => 'Subject Name';

  @override
  String get enterTitleValidator => 'Enter a title';

  @override
  String get selectSubjectValidator => 'Select or create a subject';

  @override
  String get language => 'Language';

  @override
  String get atDueTime => 'At due time';

  @override
  String minutesBefore(int minutes) {
    return '$minutes minutes before';
  }

  @override
  String get hourBefore => '1 hour before';

  @override
  String hoursBefore(int hours) {
    return '$hours hours before';
  }

  @override
  String get dayBefore => '1 day before';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get rateApp => 'Rate App';

  @override
  String get hasDueDate => 'Due Date';

  @override
  String get sectionNoDate => 'No Date';

  @override
  String get settings => 'Settings';

  @override
  String get settingsDescription =>
      'Language, theme, and application preferences';

  @override
  String get restorePurchases => 'Restore Purchases';
}

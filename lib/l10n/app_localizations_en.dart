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
  String get minuteBefore => '1 minute before';

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
  String daysBefore(int days) {
    return '$days days before';
  }

  @override
  String reminderNumber(int number) {
    return 'Reminder $number';
  }

  @override
  String get addReminder => 'Add another reminder';

  @override
  String get removeReminder => 'Remove reminder';

  @override
  String get customReminder => 'Custom time…';

  @override
  String get timeAmount => 'Amount';

  @override
  String get minutes => 'Minutes';

  @override
  String get hours => 'Hours';

  @override
  String get days => 'Days';

  @override
  String get enterPositiveNumber => 'Enter a number greater than zero';

  @override
  String get remindersMustBeDifferent =>
      'Choose a different time for each reminder';

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

  @override
  String get removeAds => 'Remove Ads';

  @override
  String get removeAdsPermanently => 'Permanently remove ads';

  @override
  String get storeNotAvailable => 'Store not available';

  @override
  String get productNotFound => 'Product not found in the store';

  @override
  String get supportAndMore => 'Support & More';

  @override
  String get premiumActive => 'Premium Active ✅';

  @override
  String get adsRemoved => 'Ads removed';

  @override
  String get processingPurchase => 'Processing purchase...';

  @override
  String get restoringPurchases => 'Restoring purchases...';

  @override
  String get skip => 'Skip';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get onboardingWelcomeTitle => 'Your assignments, under control';

  @override
  String get onboardingWelcomeDescription =>
      'Keep schoolwork organized in one simple place and always know what comes next.';

  @override
  String get onboardingSubjectsTitle => 'Organize by subject';

  @override
  String get onboardingSubjectsDescription =>
      'Create subjects with their own icons so every assignment is easy to find.';

  @override
  String get onboardingRemindersTitle => 'Never miss a deadline';

  @override
  String get onboardingRemindersDescription =>
      'Add due dates and optional reminders. Notification access is requested only when you choose to use one.';

  @override
  String get onboardingProgressTitle => 'See your progress';

  @override
  String get onboardingProgressDescription =>
      'Move between pending and completed assignments, and highlight the work that matters most.';

  @override
  String onboardingProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get viewIntroduction => 'View task creation guide';

  @override
  String get viewIntroductionDescription =>
      'Replay the step-by-step assignment creation and organization guide';

  @override
  String get skipWalkthrough => 'Skip walkthrough';

  @override
  String get walkthroughDialogLabel => 'App walkthrough';

  @override
  String get walkthroughTabsTitle => 'Track every assignment';

  @override
  String get walkthroughTabsDescription =>
      'Switch between pending work and assignments you have already completed.';

  @override
  String get walkthroughNewTaskTitle => 'Create an assignment';

  @override
  String get walkthroughNewTaskDescription =>
      'Tap New to add its subject, due date, reminder, importance, and notes.';

  @override
  String get walkthroughMenuTitle => 'Everything is within reach';

  @override
  String get walkthroughMenuDescription =>
      'Use the menu to filter by subject, find important assignments, open the trash, or change settings.';

  @override
  String get walkthroughTaskTitleTitle => 'Give your assignment a title';

  @override
  String get walkthroughTaskTitleDescription =>
      'Use a short, clear name so you can recognize it at a glance.';

  @override
  String get walkthroughTaskSubjectTitle => 'Choose or create a subject';

  @override
  String get walkthroughTaskSubjectDescription =>
      'Subjects keep related assignments together. You can create your first one here.';

  @override
  String get walkthroughTaskScheduleTitle => 'Plan the deadline';

  @override
  String get walkthroughTaskScheduleDescription =>
      'Choose a due date and time, then decide whether you want a reminder.';

  @override
  String get walkthroughTaskSaveTitle => 'Create your first assignment';

  @override
  String get walkthroughTaskSaveDescription =>
      'Complete the required title and subject, then tap Save. Your walkthrough will finish when the assignment is created.';

  @override
  String get walkthroughCreateTaskPrompt =>
      'Now complete the form and save your first assignment.';

  @override
  String get walkthroughCompleteTitle => 'Walkthrough complete!';

  @override
  String get walkthroughCompleteDescription =>
      'Your first assignment is ready. You now know everything you need to stay organized.';

  @override
  String get firstTaskIntroTitle => 'Create your first assignment';

  @override
  String get firstTaskIntroDescription =>
      'HomeWork App will organize it for you.';

  @override
  String get firstTaskDetailsTitle => 'Add details if you need them';

  @override
  String get firstTaskDetailsDescription =>
      'You can add instructions, notes, or any other information. This step is optional.';

  @override
  String get firstTaskScheduleTitle => 'Choose when it is due';

  @override
  String get firstTaskScheduleDescription =>
      'Set a due date and time. HomeWork App will automatically place the assignment in the right section.';

  @override
  String get firstTaskReminderTitle => 'Get a heads-up before it is due';

  @override
  String get firstTaskReminderDescription =>
      'Reminders are optional. Turn them on to choose when HomeWork App should notify you. You can add up to two and use a custom lead time.';

  @override
  String get firstTaskImportanceTitle => 'Highlight what matters most';

  @override
  String get firstTaskImportanceDescription =>
      'Important assignments appear first within their section. Turning this on is optional.';

  @override
  String get firstTaskSaveTitle => 'Save your first assignment';

  @override
  String get firstTaskSaveDescription =>
      'Everything is ready. Tap Save to see it organized in your list.';

  @override
  String get firstTaskCompletedTitle =>
      'Congratulations! You created your first assignment.';

  @override
  String get firstTaskCompletedDescription =>
      'Now relax: HomeWork App will organize your homework for you.';

  @override
  String get starterSubjectMath => 'Mathematics';

  @override
  String get starterSubjectSpanish => 'English';

  @override
  String get starterSubjectGeography => 'Geography';

  @override
  String get starterSubjectHistory => 'History';

  @override
  String get starterSubjectBiology => 'Biology';

  @override
  String get demoTaskToday => 'Solve algebra exercises';

  @override
  String get demoTaskTomorrow => 'Read the next chapter';

  @override
  String get demoTaskWeek => 'Prepare a geography presentation';

  @override
  String get demoTaskHistory => 'Submit a history summary';

  @override
  String get demoTaskBiology => 'Study cells';

  @override
  String get done => 'Done';

  @override
  String get privacyOptions => 'Privacy options';

  @override
  String get privacyOptionsDescription =>
      'Review or change your advertising consent';

  @override
  String get privacyOptionsError =>
      'Privacy options could not be opened. Please try again.';
}

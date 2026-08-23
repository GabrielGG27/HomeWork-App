import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HomeWork App'**
  String get appTitle;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @subjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjects;

  /// No description provided for @allAssignments.
  ///
  /// In en, this message translates to:
  /// **'All Assignments'**
  String get allAssignments;

  /// No description provided for @important.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get important;

  /// No description provided for @noSavedSubjects.
  ///
  /// In en, this message translates to:
  /// **'No saved subjects'**
  String get noSavedSubjects;

  /// No description provided for @newButton.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newButton;

  /// No description provided for @deleteAssignment.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAssignment;

  /// No description provided for @confirmDeleteTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get confirmDeleteTaskTitle;

  /// No description provided for @confirmDeleteTaskMessage.
  ///
  /// In en, this message translates to:
  /// **'This task will be moved to the trash.'**
  String get confirmDeleteTaskMessage;

  /// No description provided for @trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get deleteForever;

  /// No description provided for @confirmDeleteForeverTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently?'**
  String get confirmDeleteForeverTitle;

  /// No description provided for @confirmDeleteForeverMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this task. This action cannot be undone.'**
  String get confirmDeleteForeverMessage;

  /// No description provided for @emptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get emptyTrash;

  /// No description provided for @emptyTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty trash?'**
  String get emptyTrashTitle;

  /// No description provided for @emptyTrashMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all tasks in the trash. This action cannot be undone.'**
  String get emptyTrashMessage;

  /// No description provided for @autoDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Tasks in trash will be permanently deleted after 30 days.'**
  String get autoDeleteMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @dueTime.
  ///
  /// In en, this message translates to:
  /// **'Due Time'**
  String get dueTime;

  /// No description provided for @receiveNotification.
  ///
  /// In en, this message translates to:
  /// **'Receive notification'**
  String get receiveNotification;

  /// No description provided for @notificationOffset.
  ///
  /// In en, this message translates to:
  /// **'Notification Offset'**
  String get notificationOffset;

  /// No description provided for @markAsImportant.
  ///
  /// In en, this message translates to:
  /// **'Mark as important'**
  String get markAsImportant;

  /// No description provided for @deleteSubject.
  ///
  /// In en, this message translates to:
  /// **'Delete Subject'**
  String get deleteSubject;

  /// No description provided for @deleteSubjectConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete the subject \"{subject}\"? This action will remove the subject from the subject list. Tasks will not be automatically deleted.'**
  String deleteSubjectConfirmation(String subject);

  /// No description provided for @clearCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Completed Assignments?'**
  String get clearCompletedTitle;

  /// No description provided for @clearCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'All completed assignments will be moved to the trash. You can restore them from there.'**
  String get clearCompletedMessage;

  /// No description provided for @clearCompletedButton.
  ///
  /// In en, this message translates to:
  /// **'Clear completed assignments'**
  String get clearCompletedButton;

  /// No description provided for @noPendingAssignments.
  ///
  /// In en, this message translates to:
  /// **'No pending assignments'**
  String get noPendingAssignments;

  /// No description provided for @noCompletedAssignments.
  ///
  /// In en, this message translates to:
  /// **'No completed assignments'**
  String get noCompletedAssignments;

  /// No description provided for @sectionOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get sectionOverdue;

  /// No description provided for @sectionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get sectionToday;

  /// No description provided for @sectionTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get sectionTomorrow;

  /// No description provided for @sectionNext7Days.
  ///
  /// In en, this message translates to:
  /// **'Next 7 Days'**
  String get sectionNext7Days;

  /// No description provided for @sectionLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get sectionLater;

  /// No description provided for @createNewSubject.
  ///
  /// In en, this message translates to:
  /// **'Create new subject...'**
  String get createNewSubject;

  /// No description provided for @selectIcon.
  ///
  /// In en, this message translates to:
  /// **'Select Icon:'**
  String get selectIcon;

  /// No description provided for @subjectName.
  ///
  /// In en, this message translates to:
  /// **'Subject Name'**
  String get subjectName;

  /// No description provided for @enterTitleValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get enterTitleValidator;

  /// No description provided for @selectSubjectValidator.
  ///
  /// In en, this message translates to:
  /// **'Select or create a subject'**
  String get selectSubjectValidator;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @atDueTime.
  ///
  /// In en, this message translates to:
  /// **'At due time'**
  String get atDueTime;

  /// No description provided for @minuteBefore.
  ///
  /// In en, this message translates to:
  /// **'1 minute before'**
  String get minuteBefore;

  /// No description provided for @minutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes before'**
  String minutesBefore(int minutes);

  /// No description provided for @hourBefore.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get hourBefore;

  /// No description provided for @hoursBefore.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours before'**
  String hoursBefore(int hours);

  /// No description provided for @dayBefore.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get dayBefore;

  /// No description provided for @daysBefore.
  ///
  /// In en, this message translates to:
  /// **'{days} days before'**
  String daysBefore(int days);

  /// No description provided for @reminderNumber.
  ///
  /// In en, this message translates to:
  /// **'Reminder {number}'**
  String reminderNumber(int number);

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add another reminder'**
  String get addReminder;

  /// No description provided for @removeReminder.
  ///
  /// In en, this message translates to:
  /// **'Remove reminder'**
  String get removeReminder;

  /// No description provided for @customReminder.
  ///
  /// In en, this message translates to:
  /// **'Custom time…'**
  String get customReminder;

  /// No description provided for @timeAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get timeAmount;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @enterPositiveNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number greater than zero'**
  String get enterPositiveNumber;

  /// No description provided for @remindersMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'Choose a different time for each reminder'**
  String get remindersMustBeDifferent;

  /// No description provided for @reminderMustBeFuture.
  ///
  /// In en, this message translates to:
  /// **'One or more reminders would occur in the past. Change the due date, due time, or reminder time.'**
  String get reminderMustBeFuture;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @hasDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get hasDueDate;

  /// No description provided for @sectionNoDate.
  ///
  /// In en, this message translates to:
  /// **'No Date'**
  String get sectionNoDate;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Language, theme, and application preferences'**
  String get settingsDescription;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @removeAds.
  ///
  /// In en, this message translates to:
  /// **'Remove Ads'**
  String get removeAds;

  /// No description provided for @removeAdsPermanently.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove ads'**
  String get removeAdsPermanently;

  /// No description provided for @storeNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Store not available'**
  String get storeNotAvailable;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found in the store'**
  String get productNotFound;

  /// No description provided for @supportAndMore.
  ///
  /// In en, this message translates to:
  /// **'Support & More'**
  String get supportAndMore;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium Active ✅'**
  String get premiumActive;

  /// No description provided for @adsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Ads removed'**
  String get adsRemoved;

  /// No description provided for @processingPurchase.
  ///
  /// In en, this message translates to:
  /// **'Processing purchase...'**
  String get processingPurchase;

  /// No description provided for @restoringPurchases.
  ///
  /// In en, this message translates to:
  /// **'Restoring purchases...'**
  String get restoringPurchases;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your assignments, under control'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep schoolwork organized in one simple place and always know what comes next.'**
  String get onboardingWelcomeDescription;

  /// No description provided for @onboardingSubjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Organize by subject'**
  String get onboardingSubjectsTitle;

  /// No description provided for @onboardingSubjectsDescription.
  ///
  /// In en, this message translates to:
  /// **'Create subjects with their own icons so every assignment is easy to find.'**
  String get onboardingSubjectsDescription;

  /// No description provided for @onboardingRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Never miss a deadline'**
  String get onboardingRemindersTitle;

  /// No description provided for @onboardingRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Add due dates and optional reminders. Notification access is requested only when you choose to use one.'**
  String get onboardingRemindersDescription;

  /// No description provided for @onboardingProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'See your progress'**
  String get onboardingProgressTitle;

  /// No description provided for @onboardingProgressDescription.
  ///
  /// In en, this message translates to:
  /// **'Move between pending and completed assignments, and highlight the work that matters most.'**
  String get onboardingProgressDescription;

  /// No description provided for @onboardingProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingProgress(int current, int total);

  /// No description provided for @viewIntroduction.
  ///
  /// In en, this message translates to:
  /// **'View task creation guide'**
  String get viewIntroduction;

  /// No description provided for @viewIntroductionDescription.
  ///
  /// In en, this message translates to:
  /// **'Replay the step-by-step assignment creation and organization guide'**
  String get viewIntroductionDescription;

  /// No description provided for @skipWalkthrough.
  ///
  /// In en, this message translates to:
  /// **'Skip walkthrough'**
  String get skipWalkthrough;

  /// No description provided for @walkthroughDialogLabel.
  ///
  /// In en, this message translates to:
  /// **'App walkthrough'**
  String get walkthroughDialogLabel;

  /// No description provided for @walkthroughTabsTitle.
  ///
  /// In en, this message translates to:
  /// **'Track every assignment'**
  String get walkthroughTabsTitle;

  /// No description provided for @walkthroughTabsDescription.
  ///
  /// In en, this message translates to:
  /// **'Switch between pending work and assignments you have already completed.'**
  String get walkthroughTabsDescription;

  /// No description provided for @walkthroughNewTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an assignment'**
  String get walkthroughNewTaskTitle;

  /// No description provided for @walkthroughNewTaskDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap New to add its subject, due date, reminder, importance, and notes.'**
  String get walkthroughNewTaskDescription;

  /// No description provided for @walkthroughMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything is within reach'**
  String get walkthroughMenuTitle;

  /// No description provided for @walkthroughMenuDescription.
  ///
  /// In en, this message translates to:
  /// **'Use the menu to filter by subject, find important assignments, open the trash, or change settings.'**
  String get walkthroughMenuDescription;

  /// No description provided for @walkthroughTaskTitleTitle.
  ///
  /// In en, this message translates to:
  /// **'Give your assignment a title'**
  String get walkthroughTaskTitleTitle;

  /// No description provided for @walkthroughTaskTitleDescription.
  ///
  /// In en, this message translates to:
  /// **'Use a short, clear name so you can recognize it at a glance.'**
  String get walkthroughTaskTitleDescription;

  /// No description provided for @walkthroughTaskSubjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose or create a subject'**
  String get walkthroughTaskSubjectTitle;

  /// No description provided for @walkthroughTaskSubjectDescription.
  ///
  /// In en, this message translates to:
  /// **'Subjects keep related assignments together. You can create your first one here.'**
  String get walkthroughTaskSubjectDescription;

  /// No description provided for @walkthroughTaskScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan the deadline'**
  String get walkthroughTaskScheduleTitle;

  /// No description provided for @walkthroughTaskScheduleDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a due date and time, then decide whether you want a reminder.'**
  String get walkthroughTaskScheduleDescription;

  /// No description provided for @walkthroughTaskSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first assignment'**
  String get walkthroughTaskSaveTitle;

  /// No description provided for @walkthroughTaskSaveDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete the required title and subject, then tap Save. Your walkthrough will finish when the assignment is created.'**
  String get walkthroughTaskSaveDescription;

  /// No description provided for @walkthroughCreateTaskPrompt.
  ///
  /// In en, this message translates to:
  /// **'Now complete the form and save your first assignment.'**
  String get walkthroughCreateTaskPrompt;

  /// No description provided for @walkthroughCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Walkthrough complete!'**
  String get walkthroughCompleteTitle;

  /// No description provided for @walkthroughCompleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Your first assignment is ready. You now know everything you need to stay organized.'**
  String get walkthroughCompleteDescription;

  /// No description provided for @firstTaskIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first assignment'**
  String get firstTaskIntroTitle;

  /// No description provided for @firstTaskIntroDescription.
  ///
  /// In en, this message translates to:
  /// **'HomeWork App will organize it for you.'**
  String get firstTaskIntroDescription;

  /// No description provided for @firstTaskDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add details if you need them'**
  String get firstTaskDetailsTitle;

  /// No description provided for @firstTaskDetailsDescription.
  ///
  /// In en, this message translates to:
  /// **'You can add instructions, notes, or any other information. This step is optional.'**
  String get firstTaskDetailsDescription;

  /// No description provided for @firstTaskScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose when it is due'**
  String get firstTaskScheduleTitle;

  /// No description provided for @firstTaskScheduleDescription.
  ///
  /// In en, this message translates to:
  /// **'Set a due date and time. HomeWork App will automatically place the assignment in the right section.'**
  String get firstTaskScheduleDescription;

  /// No description provided for @firstTaskReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Get a heads-up before it is due'**
  String get firstTaskReminderTitle;

  /// No description provided for @firstTaskReminderDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders are optional. Turn them on to choose when HomeWork App should notify you. You can add up to two and use a custom lead time.'**
  String get firstTaskReminderDescription;

  /// No description provided for @firstTaskImportanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Highlight what matters most'**
  String get firstTaskImportanceTitle;

  /// No description provided for @firstTaskImportanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Important assignments appear first within their section. Turning this on is optional.'**
  String get firstTaskImportanceDescription;

  /// No description provided for @firstTaskSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save your first assignment'**
  String get firstTaskSaveTitle;

  /// No description provided for @firstTaskSaveDescription.
  ///
  /// In en, this message translates to:
  /// **'Everything is ready. Tap Save to see it organized in your list.'**
  String get firstTaskSaveDescription;

  /// No description provided for @firstTaskCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You created your first assignment.'**
  String get firstTaskCompletedTitle;

  /// No description provided for @firstTaskCompletedDescription.
  ///
  /// In en, this message translates to:
  /// **'Now relax: HomeWork App will organize your homework for you.'**
  String get firstTaskCompletedDescription;

  /// No description provided for @starterSubjectMath.
  ///
  /// In en, this message translates to:
  /// **'Mathematics'**
  String get starterSubjectMath;

  /// No description provided for @starterSubjectSpanish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get starterSubjectSpanish;

  /// No description provided for @starterSubjectGeography.
  ///
  /// In en, this message translates to:
  /// **'Geography'**
  String get starterSubjectGeography;

  /// No description provided for @starterSubjectHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get starterSubjectHistory;

  /// No description provided for @starterSubjectBiology.
  ///
  /// In en, this message translates to:
  /// **'Biology'**
  String get starterSubjectBiology;

  /// No description provided for @demoTaskToday.
  ///
  /// In en, this message translates to:
  /// **'Solve algebra exercises'**
  String get demoTaskToday;

  /// No description provided for @demoTaskTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Read the next chapter'**
  String get demoTaskTomorrow;

  /// No description provided for @demoTaskWeek.
  ///
  /// In en, this message translates to:
  /// **'Prepare a geography presentation'**
  String get demoTaskWeek;

  /// No description provided for @demoTaskHistory.
  ///
  /// In en, this message translates to:
  /// **'Submit a history summary'**
  String get demoTaskHistory;

  /// No description provided for @demoTaskBiology.
  ///
  /// In en, this message translates to:
  /// **'Study cells'**
  String get demoTaskBiology;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @privacyOptions.
  ///
  /// In en, this message translates to:
  /// **'Privacy options'**
  String get privacyOptions;

  /// No description provided for @privacyOptionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Review or change your advertising consent'**
  String get privacyOptionsDescription;

  /// No description provided for @privacyOptionsError.
  ///
  /// In en, this message translates to:
  /// **'Privacy options could not be opened. Please try again.'**
  String get privacyOptionsError;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @pickImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get pickImage;

  /// No description provided for @attachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get attachFile;

  /// No description provided for @couldNotSaveImage.
  ///
  /// In en, this message translates to:
  /// **'Could not save image: {error}'**
  String couldNotSaveImage(String error);

  /// No description provided for @couldNotSaveFile.
  ///
  /// In en, this message translates to:
  /// **'Could not save file: {error}'**
  String couldNotSaveFile(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

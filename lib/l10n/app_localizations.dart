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

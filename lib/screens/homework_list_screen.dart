import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:homework_app/utils/date_formatter.dart';
import 'package:homework_app/l10n/app_localizations.dart';
import 'package:homework_app/models/homework.dart';
import 'package:homework_app/services/homework_service.dart';
import 'package:homework_app/services/notification_service.dart';
import 'package:homework_app/icons_helper.dart';
import 'package:homework_app/screens/trash_screen.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'add_homework_screen.dart';
import 'settings_screen.dart';
import 'package:homework_app/widgets/native_ad_card.dart';
import 'package:provider/provider.dart';
import 'package:homework_app/services/purchases_service.dart';
import 'package:homework_app/services/ads_service.dart';
import 'package:homework_app/services/attachment_storage_service.dart';
import 'package:homework_app/services/analytics_service.dart';
import 'package:homework_app/services/onboarding_service.dart';
import 'package:homework_app/widgets/walkthrough_overlay.dart';
import 'package:homework_app/utils/homework_grouping.dart';
import 'package:homework_app/widgets/onboarding_message_card.dart';

class HomeworkListScreen extends StatefulWidget {
  final String? subjectFilter;
  final bool showImportant;
  final bool startWalkthrough;
  final bool startFirstTaskFlow;

  const HomeworkListScreen({
    super.key,
    this.subjectFilter,
    this.showImportant = false,
    this.startWalkthrough = false,
    this.startFirstTaskFlow = false,
  });

  @override
  State<HomeworkListScreen> createState() => _HomeworkListScreenState();
}

class _HomeworkListScreenState extends State<HomeworkListScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _tabsKey = GlobalKey();
  final GlobalKey _newTaskKey = GlobalKey();
  final GlobalKey _drawerHeaderKey = GlobalKey();
  List<Homework> _homeworkList = [];
  bool _isLoading = true;
  Timer? _timer;
  List<String> _subjects = [];
  Map<String, int> _subjectIcons = {};
  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  late bool _firstTaskFlowActive;
  bool _didPrepareFirstTaskFlow = false;

  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-7427500220267639/4890805530' // Interstitial
      : 'ca-app-pub-7427500220267639/4890805530'; // Interstitial

  final String _bannerAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-7427500220267639/5542410791' // Banner
      : 'ca-app-pub-7427500220267639/5542410791'; // Banner

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _firstTaskFlowActive = widget.startFirstTaskFlow;
    if (!_firstTaskFlowActive) {
      _loadData();
    }
    _schedulePendingNotifications();

    // Defer ad loading to the post-frame callback to avoid blocking the
    // Android main thread Looper during initState, which was causing ANRs
    // (nativePollOnce, binder transaction, J.N.JJ).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (!_firstTaskFlowActive) {
          _loadBannerAd();
        }
        if (widget.startWalkthrough) {
          _runWalkthrough();
        }
      }
    });

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Date-based sections are calculated during build with DateTime.now().
      // Rebuild immediately because foreground timers may have been suspended.
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_firstTaskFlowActive && !_didPrepareFirstTaskFlow) {
      _didPrepareFirstTaskFlow = true;
      unawaited(_prepareFirstTaskFlow());
    }
  }

  Future<void> _prepareFirstTaskFlow() async {
    final l10n = AppLocalizations.of(context)!;
    final starterSubjects = [
      l10n.starterSubjectMath,
      l10n.starterSubjectSpanish,
      l10n.starterSubjectGeography,
      l10n.starterSubjectHistory,
      l10n.starterSubjectBiology,
    ];
    final starterIcons = <String, int>{
      l10n.starterSubjectMath: Icons.calculate.codePoint,
      l10n.starterSubjectSpanish: Icons.menu_book_rounded.codePoint,
      l10n.starterSubjectGeography: Icons.language.codePoint,
      l10n.starterSubjectHistory: Icons.school.codePoint,
      l10n.starterSubjectBiology: Icons.science.codePoint,
    };
    final existingSubjects = await HomeworkService.loadSubjects();
    final existingIcons = await HomeworkService.loadSubjectIcons();
    final mergedSubjects = [...existingSubjects];
    for (final subject in starterSubjects) {
      if (!mergedSubjects.contains(subject)) mergedSubjects.add(subject);
    }
    await HomeworkService.saveSubjects(mergedSubjects);
    await HomeworkService.saveSubjectIcons({...starterIcons, ...existingIcons});
    await AnalyticsService.logOnboardingStarted(isReplay: false);
    await _loadData();
    if (!mounted) return;
    final hasExistingTask = _homeworkList.any((task) => !task.isDeleted);
    if (hasExistingTask) {
      await OnboardingService.markCompleted();
      if (!mounted) return;
      setState(() => _firstTaskFlowActive = false);
      unawaited(_loadBannerAd());
    }
  }

  Future<void> _refreshAfterNestedList() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(onboardingCompletedKey) ?? false;
    if (!mounted) return;
    if (_firstTaskFlowActive && completed) {
      setState(() => _firstTaskFlowActive = false);
      unawaited(_loadBannerAd());
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadSubjects();
    final loaded = await HomeworkService.loadHomework();
    if (!mounted) return;
    setState(() {
      _homeworkList = loaded;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadBannerAd() async {
    try {
      await AdsService.ready;
      await AdsService.enqueueAdLoad(() async {
        if (!mounted) return;
        final completion = Completer<void>();

        _bannerAd = BannerAd(
          adUnitId: _bannerAdUnitId,
          size: AdSize.banner,
          request: const AdRequest(),
          listener: BannerAdListener(
            onAdLoaded: (ad) {
              if (!identical(_bannerAd, ad)) {
                ad.dispose();
                if (!completion.isCompleted) completion.complete();
                return;
              }
              if (mounted) {
                setState(() => _isBannerAdLoaded = true);
              }
              if (!completion.isCompleted) completion.complete();
            },
            onAdFailedToLoad: (ad, error) {
              ad.dispose();
              if (identical(_bannerAd, ad)) {
                _bannerAd = null;
              }
              debugPrint('BannerAd failed to load: $error');
              if (!completion.isCompleted) completion.complete();
            },
          ),
        )..load();

        await completion.future;
      });
    } catch (error) {
      debugPrint('BannerAd initialization or load failed: $error');
      _bannerAd?.dispose();
      _bannerAd = null;
    }
  }

  Future<bool> _showWalkthroughTarget({
    required GlobalKey key,
    required String title,
    required String description,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showWalkthroughStep(
      context: context,
      targetKey: key,
      title: title,
      description: description,
      nextLabel: l10n.next,
      skipLabel: l10n.skipWalkthrough,
      semanticsLabel: l10n.walkthroughDialogLabel,
    );
    return action != WalkthroughAction.skip;
  }

  Future<void> _runWalkthrough() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    if (!await _showWalkthroughTarget(
      key: _tabsKey,
      title: l10n.walkthroughTabsTitle,
      description: l10n.walkthroughTabsDescription,
    )) {
      return;
    }
    if (!mounted ||
        !await _showWalkthroughTarget(
          key: _newTaskKey,
          title: l10n.walkthroughNewTaskTitle,
          description: l10n.walkthroughNewTaskDescription,
        )) {
      return;
    }

    _scaffoldKey.currentState?.openDrawer();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    final continueToTask = await _showWalkthroughTarget(
      key: _drawerHeaderKey,
      title: l10n.walkthroughMenuTitle,
      description: l10n.walkthroughMenuDescription,
    );
    if (!mounted) return;
    await Navigator.of(context).maybePop();
    if (!continueToTask || !mounted) return;

    final homework = await Navigator.of(context).push<Homework>(
      MaterialPageRoute(
        builder: (_) => const AddHomeworkScreen(startWalkthrough: true),
      ),
    );
    if (!mounted || homework == null) return;

    await _addHomework(homework);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.celebration_rounded),
        title: Text(l10n.walkthroughCompleteTitle),
        content: Text(l10n.walkthroughCompleteDescription),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }

  Future<void> _loadInterstitialAd() async {
    try {
      await AdsService.ready;
      await AdsService.enqueueAdLoad(() async {
        if (!mounted) return;
        final completion = Completer<void>();

        InterstitialAd.load(
          adUnitId: _adUnitId,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (InterstitialAd ad) {
              if (!mounted) {
                ad.dispose();
                if (!completion.isCompleted) completion.complete();
                return;
              }
              debugPrint('Ad was loaded.');
              _interstitialAd = ad;
              if (!completion.isCompleted) completion.complete();
            },
            onAdFailedToLoad: (LoadAdError error) {
              debugPrint('Ad failed to load with error: $error');
              _interstitialAd = null;
              if (!completion.isCompleted) completion.complete();
            },
          ),
        );

        await completion.future;
      });
    } catch (error) {
      debugPrint('InterstitialAd initialization or load failed: $error');
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      debugPrint('Warning: attempt to show interstitial before loaded.');
      _loadInterstitialAd();
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) =>
          debugPrint('Ad showed full screen content.'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Ad was dismissed.');
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Ad failed to show full screen content with error: $error');
        ad.dispose();
        _loadInterstitialAd();
      },
    );
    _interstitialAd!.setImmersiveMode(true);
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  Future<void> _loadSubjects() async {
    final subjects = await HomeworkService.loadSubjects();
    final icons = await HomeworkService.loadSubjectIcons();
    if (!mounted) return;
    setState(() {
      _subjects = subjects;
      _subjectIcons = icons;
    });
  }

  List<Homework> _demoHomework(AppLocalizations l10n) {
    final now = DateTime.now();
    final todayCandidate = now.add(const Duration(minutes: 30));
    final todayDue = todayCandidate.day == now.day
        ? todayCandidate
        : DateTime(now.year, now.month, now.day, 23, 59, 59);
    final tomorrowDue = DateTime(now.year, now.month, now.day + 1, 17);
    final weekDue = DateTime(now.year, now.month, now.day + 3, 18);
    final laterDue = DateTime(now.year, now.month, now.day + 9, 18);
    return [
      Homework(
        id: 'onboarding-demo-today',
        title: l10n.demoTaskToday,
        subject: l10n.starterSubjectMath,
        dueDate: todayDue,
        enableNotification: false,
      ),
      Homework(
        id: 'onboarding-demo-tomorrow',
        title: l10n.demoTaskTomorrow,
        subject: l10n.starterSubjectSpanish,
        dueDate: tomorrowDue,
        enableNotification: false,
      ),
      Homework(
        id: 'onboarding-demo-week',
        title: l10n.demoTaskWeek,
        subject: l10n.starterSubjectGeography,
        dueDate: weekDue,
        enableNotification: false,
        isImportant: true,
      ),
      Homework(
        id: 'onboarding-demo-history',
        title: l10n.demoTaskHistory,
        subject: l10n.starterSubjectHistory,
        dueDate: laterDue,
        enableNotification: false,
      ),
      Homework(
        id: 'onboarding-demo-biology',
        title: l10n.demoTaskBiology,
        subject: l10n.starterSubjectBiology,
        dueDate: tomorrowDue.add(const Duration(hours: 2)),
        enableNotification: false,
      ),
    ];
  }

  Future<void> _openAddHomework({bool replayGuide = false}) async {
    final isFirstTaskSetup = _firstTaskFlowActive && _homeworkList.isEmpty;
    if (isFirstTaskSetup) {
      await AnalyticsService.logFirstTaskSetupStarted();
    }
    if (!mounted) return;
    final homework = await Navigator.of(context).push<Homework>(
      MaterialPageRoute(
        builder: (_) => AddHomeworkScreen(
          startWalkthrough: isFirstTaskSetup || replayGuide,
        ),
      ),
    );
    if (!mounted) return;
    if (homework == null) {
      if (isFirstTaskSetup) {
        unawaited(AnalyticsService.logFirstTaskSetupAbandoned());
      }
      return;
    }
    await _addHomework(homework);
    if (!mounted || !isFirstTaskSetup) return;
    await OnboardingService.markCompleted();
    await AnalyticsService.logOnboardingCompleted(isReplay: false);
    if (!mounted) return;
    setState(() => _firstTaskFlowActive = false);
    unawaited(_loadBannerAd());
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (dialogContext) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: OnboardingMessageCard(
          icon: Icons.celebration_rounded,
          title: l10n.firstTaskCompletedTitle,
          description: l10n.firstTaskCompletedDescription,
          actions: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.done),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addHomework(Homework homework) async {
    // Leer el servicio ANTES de cualquier await para evitar usar BuildContext
    // a través de gaps asíncronos.
    final purchasesService = Provider.of<PurchasesService>(
      context,
      listen: false,
    );

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final isFirstTask =
        _homeworkList.isEmpty && (prefs.getInt('homeworkAddedCount') ?? 0) == 0;
    setState(() {
      _homeworkList.add(homework);
    });
    await HomeworkService.saveHomework(_homeworkList);
    await AnalyticsService.logTaskCreated(homework, isFirstTask: isFirstTask);
    await NotificationService.scheduleNotification(homework);
    _loadSubjects();

    // Guard against widget being unmounted during async gap (e.g. app going
    // to background), which previously caused a fatal 'Reply already
    // submitted' crash in BasicMessageChannel via in_app_review.
    if (!mounted) return;
    int count = await _checkAndRequestReview();

    // Mostrar anuncio cada 7 tareas, solo si no es premium
    if (mounted && !purchasesService.isPremium && count % 7 == 0) {
      _showInterstitialAd();
    } else if (mounted &&
        !purchasesService.isPremium &&
        _interstitialAd == null) {
      _loadInterstitialAd();
    }
  }

  Future<int> _checkAndRequestReview() async {
    final prefs = await SharedPreferences.getInstance();
    // Increment the number of times a homework has been added.
    int homeworkAddedCount = (prefs.getInt('homeworkAddedCount') ?? 0) + 1;
    await prefs.setInt('homeworkAddedCount', homeworkAddedCount);

    // If exactly 10 tasks have been added, trigger the review prompt.
    if (homeworkAddedCount == 10) {
      // Guard: widget may have been unmounted during the awaits above
      // (e.g. user minimised the app). Calling requestReview() on a
      // destroyed BasicMessageChannel causes a fatal 'Reply already
      // submitted' IllegalStateException crash.
      if (!mounted) return homeworkAddedCount;
      try {
        final InAppReview inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          if (!mounted) return homeworkAddedCount;
          await inAppReview.requestReview();
        }
      } catch (e) {
        debugPrint('[InAppReview] Error al solicitar review: $e');
      }
    }

    return homeworkAddedCount;
  }

  void _updateHomework(int index, Homework updatedHomework) async {
    if (index < 0 || index >= _homeworkList.length) return;
    final retainedIds = updatedHomework.attachments.map((a) => a.id).toSet();
    final removedAttachments = _homeworkList[index].attachments
        .where((attachment) => !retainedIds.contains(attachment.id))
        .toList();
    setState(() {
      _homeworkList[index] = updatedHomework;
    });
    await HomeworkService.saveHomework(_homeworkList);
    await AttachmentStorageService.deleteManagedFiles(removedAttachments);
    await NotificationService.scheduleNotification(updatedHomework);
    _loadSubjects();
  }

  void _deleteHomework(int index) async {
    if (index < 0 || index >= _homeworkList.length) return;
    final homeworkId = _homeworkList[index].id;
    setState(() {
      _homeworkList[index].isDeleted = true;
      _homeworkList[index].deletedAt = DateTime.now();
    });
    await HomeworkService.saveHomework(_homeworkList);
    await NotificationService.cancelNotification(homeworkId);
  }

  void _toggleCompleted(Homework homework) async {
    final index = _homeworkList.indexWhere((h) => h.id == homework.id);
    if (index != -1) {
      final isBeingCompleted = !_homeworkList[index].isCompleted;
      final hasPreviousCompletedTasks = _homeworkList.any(
        (task) => task.id != homework.id && task.isCompleted,
      );
      setState(() {
        _homeworkList[index].isCompleted = !_homeworkList[index].isCompleted;
      });

      final toggledHomework = _homeworkList[index];
      if (isBeingCompleted) {
        unawaited(
          AnalyticsService.logTaskCompleted(
            toggledHomework,
            hasPreviousCompletedTasks: hasPreviousCompletedTasks,
          ),
        );
      }

      await HomeworkService.saveHomework(_homeworkList);
      final currentIndex = _homeworkList.indexWhere(
        (task) => task.id == homework.id,
      );
      if (currentIndex == -1) return;
      final currentHomework = _homeworkList[currentIndex];
      if (currentHomework.isCompleted) {
        await NotificationService.cancelNotification(homework.id);
      } else {
        await NotificationService.scheduleNotification(currentHomework);
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
          MaterialPageRoute(
            builder: (ctx) =>
                HomeworkListScreen(startFirstTaskFlow: _firstTaskFlowActive),
          ),
          (route) => route.isFirst,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchasesService = context.watch<PurchasesService>();
    final isPremium = purchasesService.isPremium;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(
            widget.showImportant
                ? AppLocalizations.of(context)!.important
                : (widget.subjectFilter ??
                      AppLocalizations.of(context)!.appTitle),
          ),
          bottom: TabBar(
            key: _tabsKey,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.pending),
              Tab(text: AppLocalizations.of(context)!.completed),
            ],
          ),
        ),
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      DrawerHeader(
                        key: _drawerHeaderKey,
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
                        title: Text(
                          AppLocalizations.of(context)!.allAssignments,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.subjectFilter != null ||
                              widget.showImportant) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => HomeworkListScreen(
                                  startFirstTaskFlow: _firstTaskFlowActive,
                                ),
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
                              builder: (context) => HomeworkListScreen(
                                showImportant: true,
                                startFirstTaskFlow: _firstTaskFlowActive,
                              ),
                            ),
                          );
                          if (mounted) {
                            await _refreshAfterNestedList();
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
                                  ? getIconFromCodePoint(
                                      _subjectIcons[subject]!,
                                    )
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
                                  builder: (context) => HomeworkListScreen(
                                    subjectFilter: subject,
                                    startFirstTaskFlow: _firstTaskFlowActive,
                                  ),
                                ),
                              );
                              if (mounted) {
                                await _refreshAfterNestedList();
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                if (!isPremium) ...[
                  if (purchasesService.isPurchasePending)
                    ListTile(
                      leading: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.processingPurchase,
                      ),
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.block, color: Colors.red),
                      title: Text(AppLocalizations.of(context)!.removeAds),
                      subtitle: Text(
                        !purchasesService.isAvailable
                            ? AppLocalizations.of(context)!.storeNotAvailable
                            : purchasesService.products.isEmpty
                            ? AppLocalizations.of(context)!.productNotFound
                            : AppLocalizations.of(
                                context,
                              )!.removeAdsPermanently,
                      ),
                      onTap:
                          (purchasesService.isAvailable &&
                              purchasesService.products.isNotEmpty)
                          ? () {
                              Navigator.pop(context);
                              purchasesService.buyRemoveAds();
                            }
                          : null,
                    ),
                ],
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.blue),
                  title: Text(AppLocalizations.of(context)!.settings),
                  onTap: () async {
                    Navigator.pop(context);
                    final replayWalkthrough = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                    if (mounted && replayWalkthrough == true) {
                      await _openAddHomework(replayGuide: true);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: _newTaskKey,
          onPressed: _isLoading ? null : _openAddHomework,
          icon: const Icon(Icons.add),
          label: Text(
            AppLocalizations.of(context)!.newButton,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        bottomNavigationBar:
            (!_firstTaskFlowActive &&
                !isPremium &&
                _isBannerAdLoaded &&
                _bannerAd != null)
            ? SafeArea(
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              )
            : null,
        body: Builder(
          builder: (context) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final allHomework = _homeworkList
                .where((h) => !h.isDeleted)
                .toList();
            final showFirstTaskIntro =
                _firstTaskFlowActive && allHomework.isEmpty;
            final displayedHomework = showFirstTaskIntro
                ? _demoHomework(AppLocalizations.of(context)!)
                : allHomework;

            late final List<Homework> filteredHomework;
            if (widget.showImportant) {
              filteredHomework = displayedHomework
                  .where((h) => h.isImportant)
                  .toList();
            } else if (widget.subjectFilter != null) {
              filteredHomework = displayedHomework
                  .where((h) => h.subject == widget.subjectFilter)
                  .toList();
            } else {
              filteredHomework = displayedHomework;
            }

            final pending = filteredHomework
                .where((h) => !h.isCompleted)
                .toList();
            final completed = filteredHomework
                .where((h) => h.isCompleted)
                .toList();

            int importanceCompare(Homework a, Homework b) {
              if (a.isImportant && !b.isImportant) return -1;
              if (!a.isImportant && b.isImportant) return 1;
              if (a.hasDueDate && !b.hasDueDate) return -1;
              if (!a.hasDueDate && b.hasDueDate) return 1;
              return a.dueDate.compareTo(b.dueDate);
            }

            pending.sort(importanceCompare);
            completed.sort(importanceCompare);

            final list = Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: TabBarView(
                children: [
                  _buildHomeworkList(
                    context,
                    pending,
                    displayedHomework,
                    true,
                    showFirstTaskIntro ? true : isPremium,
                  ),
                  _buildHomeworkList(
                    context,
                    completed,
                    displayedHomework,
                    false,
                    showFirstTaskIntro ? true : isPremium,
                  ),
                ],
              ),
            );
            if (!showFirstTaskIntro) return list;
            final l10n = AppLocalizations.of(context)!;
            return Stack(
              children: [
                Positioned.fill(
                  child: AbsorbPointer(
                    child: Opacity(opacity: 0.62, child: list),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: OnboardingMessageCard(
                      icon: Icons.auto_awesome_rounded,
                      title: l10n.firstTaskIntroTitle,
                      description: l10n.firstTaskIntroDescription,
                      pointDown: true,
                    ),
                  ),
                ),
              ],
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
    bool isPremium,
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
      final grouped = groupHomeworkByDate(filteredList);
      return ListView.builder(
        itemCount: grouped.keys.length,
        itemBuilder: (context, sectionIndex) {
          final sectionTitle = grouped.keys.elementAt(sectionIndex);
          final sectionTasks = grouped.values.elementAt(sectionIndex);
          final tasksBeforeSection = grouped.values
              .take(sectionIndex)
              .fold<int>(0, (total, tasks) => total + tasks.length);
          final sectionItems = <Homework?>[];

          for (
            var taskIndex = 0;
            taskIndex < sectionTasks.length;
            taskIndex++
          ) {
            sectionItems.add(sectionTasks[taskIndex]);

            final globalTaskPosition = tasksBeforeSection + taskIndex + 1;
            if (!isPremium && globalTaskPosition % 4 == 0) {
              sectionItems.add(null);
            }
          }

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
              ...List.generate(sectionItems.length, (index) {
                final hw = sectionItems[index];
                if (hw == null) {
                  return const NativeAdCard();
                }
                final formattedDate = SmartDateFormatter.formatForCard(
                  hw.dueDate,
                  sectionTitle,
                );
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
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
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
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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

      final adsCount = filteredList.length ~/ 4;
      final totalItems = filteredList.length + adsCount + 1;

      return ListView.builder(
        itemCount: totalItems,
        itemBuilder: (context, index) {
          if (index == totalItems - 1) {
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

          if (index > 0 && (index + 1) % 5 == 0) {
            return const NativeAdCard(marginVertical: 8.0);
          }

          final taskIndex = index - (index ~/ 5);
          final hw = filteredList[taskIndex];
          final formattedDate = SmartDateFormatter.formatForCompletedCard(
            hw.dueDate,
          );
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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

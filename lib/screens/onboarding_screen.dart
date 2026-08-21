import 'dart:async';

import 'package:flutter/material.dart';
import 'package:homework_app/l10n/app_localizations.dart';
import 'package:homework_app/screens/homework_list_screen.dart';
import 'package:homework_app/services/analytics_service.dart';
import 'package:homework_app/services/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:homework_app/services/onboarding_service.dart'
    show onboardingCompletedKey;

class OnboardingScreen extends StatefulWidget {
  final bool isReplay;

  const OnboardingScreen({super.key, this.isReplay = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    unawaited(AnalyticsService.logOnboardingStarted(isReplay: widget.isReplay));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool startWalkthrough}) async {
    if (startWalkthrough) {
      await AnalyticsService.logOnboardingCompleted(isReplay: widget.isReplay);
    } else {
      await AnalyticsService.logOnboardingSkipped(isReplay: widget.isReplay);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingCompletedKey, true);
    if (!mounted) return;

    if (widget.isReplay) {
      Navigator.of(context).pop(startWalkthrough);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              HomeworkListScreen(startWalkthrough: startWalkthrough),
        ),
      );
    }
  }

  void _next() {
    if (_page == 3) {
      _finish(startWalkthrough: true);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = [
      _OnboardingPage(
        icon: Icons.school_rounded,
        title: l10n.onboardingWelcomeTitle,
        description: l10n.onboardingWelcomeDescription,
      ),
      _OnboardingPage(
        icon: Icons.auto_stories_rounded,
        title: l10n.onboardingSubjectsTitle,
        description: l10n.onboardingSubjectsDescription,
      ),
      _OnboardingPage(
        icon: Icons.notifications_active_rounded,
        title: l10n.onboardingRemindersTitle,
        description: l10n.onboardingRemindersDescription,
      ),
      _OnboardingPage(
        icon: Icons.task_alt_rounded,
        title: l10n.onboardingProgressTitle,
        description: l10n.onboardingProgressDescription,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            key: const ValueKey('onboarding_skip'),
            onPressed: () => _finish(startWalkthrough: false),
            child: Text(l10n.skip),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                key: const ValueKey('onboarding_pages'),
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: pages,
              ),
            ),
            Semantics(
              label: l10n.onboardingProgress(_page + 1, pages.length),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: index == _page ? 28 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == _page
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton.icon(
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      ),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(l10n.back),
                    )
                  else
                    const Spacer(),
                  const Spacer(),
                  FilledButton.icon(
                    key: const ValueKey('onboarding_next'),
                    onPressed: _next,
                    icon: Icon(
                      _page == pages.length - 1
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward,
                    ),
                    label: Text(
                      _page == pages.length - 1 ? l10n.getStarted : l10n.next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 72, color: colors.onPrimaryContainer),
              ),
              const SizedBox(height: 40),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

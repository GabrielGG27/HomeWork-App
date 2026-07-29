import 'package:flutter/material.dart';

enum WalkthroughAction { next, skip }

Future<WalkthroughAction?> showWalkthroughStep({
  required BuildContext context,
  required GlobalKey targetKey,
  required String title,
  required String description,
  required String nextLabel,
  required String skipLabel,
  required String semanticsLabel,
}) async {
  final targetContext = targetKey.currentContext;
  if (targetContext == null) return WalkthroughAction.next;
  final renderBox = targetContext.findRenderObject() as RenderBox?;
  if (renderBox == null || !renderBox.hasSize) return WalkthroughAction.next;

  final targetRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
  return showGeneralDialog<WalkthroughAction>(
    context: context,
    barrierDismissible: false,
    barrierLabel: semanticsLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, _, __) => _WalkthroughOverlay(
      targetRect: targetRect,
      title: title,
      description: description,
      nextLabel: nextLabel,
      skipLabel: skipLabel,
      semanticsLabel: semanticsLabel,
    ),
  );
}

class _WalkthroughOverlay extends StatelessWidget {
  final Rect targetRect;
  final String title;
  final String description;
  final String nextLabel;
  final String skipLabel;
  final String semanticsLabel;

  const _WalkthroughOverlay({
    required this.targetRect,
    required this.title,
    required this.description,
    required this.nextLabel,
    required this.skipLabel,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    const cardHeight = 210.0;
    final placeBelow =
        targetRect.bottom + cardHeight + 24 < size.height - safeBottom;
    final top = placeBelow
        ? targetRect.bottom + 16
        : (targetRect.top - cardHeight - 16).clamp(safeTop + 8, size.height);

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SpotlightPainter(targetRect.inflate(8)),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: top,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(description),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, WalkthroughAction.skip),
                            child: Text(skipLabel),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(context, WalkthroughAction.next),
                            child: Text(nextLabel),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;

  _SpotlightPainter(this.targetRect);

  @override
  void paint(Canvas canvas, Size size) {
    final background = Path()..addRect(Offset.zero & size);
    final spotlight = Path()
      ..addRRect(
        RRect.fromRectAndRadius(targetRect, const Radius.circular(16)),
      );
    final overlay = Path.combine(
      PathOperation.difference,
      background,
      spotlight,
    );
    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.72),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(targetRect, const Radius.circular(16)),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.targetRect != targetRect;
}

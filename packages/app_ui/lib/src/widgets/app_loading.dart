import 'package:flutter/material.dart';

import '../../app_ui.dart';

/// Centered circular progress indicator with consistent sizing.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.size = 32, this.label});

  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      liveRegion: true,
      excludeSemantics: label != null,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(strokeWidth: 3),
            ),
            if (label != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                label!,
                style: context.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ).animateFadeIn(duration: AppDurations.fast),
    );
  }
}

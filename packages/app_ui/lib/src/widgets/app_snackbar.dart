import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app_ui.dart';

enum AppSnackbarVariant { info, success, warning, error }

/// Centralized messenger presentation for transient status feedback.
abstract final class AppSnackbar {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    AppSnackbarVariant variant = AppSnackbarVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final (background, foreground, icon) = _appearance(context, variant);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    return messenger.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: background,
        content: Row(
          children: [
            FaIcon(icon, color: foreground, size: AppIconSize.md),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: AppTypography.body(context.textTheme)?.copyWith(
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: foreground,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static (Color, Color, FaIconData) _appearance(
    BuildContext context,
    AppSnackbarVariant variant,
  ) {
    final semantic = context.semanticColors;
    final scheme = context.colorScheme;
    return switch (variant) {
      AppSnackbarVariant.info => (
        semantic.info,
        semantic.onInfo,
        FontAwesomeIcons.circleInfo,
      ),
      AppSnackbarVariant.success => (
        semantic.success,
        semantic.onSuccess,
        FontAwesomeIcons.circleCheck,
      ),
      AppSnackbarVariant.warning => (
        semantic.warning,
        semantic.onWarning,
        FontAwesomeIcons.triangleExclamation,
      ),
      AppSnackbarVariant.error => (
        scheme.error,
        scheme.onError,
        FontAwesomeIcons.circleExclamation,
      ),
    };
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app_ui.dart';

/// A polished confirmation dialog: an accent icon badge, a centered title and
/// body, an optional [content] slot, and a Cancel/Confirm button pair.
///
/// For the common yes/no case use [AppConfirmDialog.show], which resolves to
/// `true` when confirmed. For dialogs whose confirm button depends on internal
/// state (e.g. a typed confirmation field), build [AppConfirmDialog] directly,
/// wiring [onConfirm]/[onCancel] and toggling [confirmEnabled].
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    this.icon = FontAwesomeIcons.triangleExclamation,
    this.isDestructive = true,
    this.confirmEnabled = true,
    this.content,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final FaIconData icon;
  final bool isDestructive;
  final bool confirmEnabled;
  final Widget? content;

  /// Shows the dialog and resolves to `true` when the user confirms, `false`
  /// when they cancel or dismiss it.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    FaIconData icon = FontAwesomeIcons.triangleExclamation,
    bool isDestructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrowScreen = screenWidth < 380;
    final accent = isDestructive ? colorScheme.error : colorScheme.primary;
    final accentContainer = isDestructive
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final onAccent = isDestructive
        ? colorScheme.onError
        : colorScheme.onPrimary;

    final horizontalInset = isNarrowScreen ? AppSpacing.lg : AppSpacing.xxxl;
    final contentPadding = isNarrowScreen
        ? const EdgeInsets.all(AppSpacing.xxl)
        : const EdgeInsets.fromLTRB(
            AppSpacing.xxxxl,
            AppSpacing.xxxxl,
            AppSpacing.xxxxl,
            AppSpacing.xxxl,
          );

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: AppSpacing.lg,
      ),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: contentPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accentContainer.withValues(alpha: 0.58),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: FaIcon(icon, color: accent, size: AppIconSize.xl),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              if (content != null) ...[
                const SizedBox(height: AppSpacing.xxl),
                content!,
              ],
              const SizedBox(height: AppSpacing.xxxl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final textScale = MediaQuery.textScalerOf(context).scale(1);
                  final stackActions =
                      constraints.maxWidth < 260 || textScale >= 1.5;

                  final cancelBtn = TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      foregroundColor: colorScheme.onSurfaceVariant,
                      textStyle: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    child: Text(cancelLabel, textAlign: TextAlign.center),
                  );

                  final confirmBtn = FilledButton(
                    onPressed: confirmEnabled ? onConfirm : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      backgroundColor: accent,
                      foregroundColor: onAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      textStyle: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    child: Text(confirmLabel, textAlign: TextAlign.center),
                  );

                  if (stackActions) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        confirmBtn,
                        const SizedBox(height: AppSpacing.sm),
                        cancelBtn,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: cancelBtn),
                      const SizedBox(width: AppSpacing.xxl),
                      Expanded(child: confirmBtn),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

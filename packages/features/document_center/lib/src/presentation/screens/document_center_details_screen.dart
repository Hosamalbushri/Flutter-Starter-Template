import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:localization/localization.dart';

/// Nested details page used to verify stack-preserving feature navigation.
class DocumentCenterDetailsScreen extends StatelessWidget {
  const DocumentCenterDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.appTitle,
      body: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: AppCard(
          child: Text(
            l10n.appTitle,
            style: context.textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

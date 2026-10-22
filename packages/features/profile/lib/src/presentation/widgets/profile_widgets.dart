import 'package:app_ui/app_ui.dart';
// fst:auth:start
// Deliberate cross-feature capability import: profile surfaces auth's
// delete-account flow (see the capability exception in CLAUDE.md).
import 'package:feature_auth/feature_auth.dart';
// fst:auth:end
import 'package:flutter/material.dart';
// fst:auth:start
// Only `profile_header.dart` (an auth-only part) uses Clipboard.
import 'package:flutter/services.dart';
// fst:auth:end
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
// fst:auth:start
import 'package:shared_ui/shared_ui.dart';
// fst:auth:end
import 'package:theme/theme.dart';

import '../bloc/profile_bloc.dart';
import '../bloc/profile_state.dart';
// fst:auth:start
part 'profile_header.dart';
part 'profile_account.dart';
// fst:auth:end
part 'profile_appearance.dart';
part 'profile_about.dart';

class ProfileBody extends StatefulWidget {
  const ProfileBody({super.key});

  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
  int? _expandedSection = 0;

  /// Extra bottom padding so content clears the floating bottom bar.
  static const double _bottomInset = 96;

  // fst:auth:start
  void _onDeleteAccountState(BuildContext context, DeleteAccountState state) {
    switch (state) {
      case DeleteAccountSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.profileDeleteAccountSuccess)),
        );
        // Clearing the session flips the app to signed-out, so the router
        // redirects to the login screen.
        SessionScope.of(context).clearSession();
      case DeleteAccountFailure():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.profileDeleteAccountError)),
        );
      case DeleteAccountInitial() || DeleteAccountSubmitting():
        break;
    }
  }
  // fst:auth:end

  void _toggleSection(int index) {
    setState(() {
      _expandedSection = _expandedSection == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body = AppScaffold(
      title: context.l10n.profileAppBarTitle,
      subtitle: context.l10n.profileSettingsSubtitle,
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          _bottomInset,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  // fst:auth:start
                  const _ProfileHeader().animateSlideDown(),
                  const SizedBox(height: AppSpacing.lg),
                  _ProfileAccordionSection(
                    index: 0,
                    title: context.l10n.profileSectionAccount,
                    subtitle: context.l10n.profileAccountSectionSubtitle,
                    icon: FontAwesomeIcons.shieldHalved,
                    expanded: _expandedSection == 0,
                    onTap: () => _toggleSection(0),
                    child: const _AccountCard(),
                  ).animateSlideUp(delay: 120.ms),
                  const SizedBox(height: AppSpacing.md),
                  // fst:auth:end
                  _ProfileAccordionSection(
                    index: 1,
                    title: context.l10n.profileSectionAppearance,
                    subtitle: context.l10n.profileAppearanceSectionSubtitle,
                    icon: FontAwesomeIcons.wandMagicSparkles,
                    expanded: _expandedSection == 1,
                    onTap: () => _toggleSection(1),
                    child: const _AppearanceCard(),
                  ).animateSlideUp(delay: 200.ms),
                  const SizedBox(height: AppSpacing.md),
                  _ProfileAccordionSection(
                    index: 2,
                    title: context.l10n.profileSectionAbout,
                    subtitle: context.l10n.profileAboutSectionSubtitle,
                    icon: FontAwesomeIcons.circleInfo,
                    expanded: _expandedSection == 2,
                    onTap: () => _toggleSection(2),
                    child: const _AboutCard(),
                  ).animateSlideUp(delay: 280.ms),
                  // fst:auth:start
                  const SizedBox(height: AppSpacing.xxl),
                  const _SignOutButton().animateFadeIn(delay: 360.ms),
                  // fst:auth:end
                ],
              ),
            ),
          ),
        ],
      ),
    );
    // fst:auth:start
    body = BlocListener<DeleteAccountCubit, DeleteAccountState>(
      listener: _onDeleteAccountState,
      child: body,
    );
    // fst:auth:end
    return body;
  }
}

class _ProfileAccordionSection extends StatelessWidget {
  const _ProfileAccordionSection({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  final int index;
  final String title;
  final String subtitle;
  final FaIconData icon;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : AppDurations.medium;
    final scheme = context.colorScheme;
    return Semantics(
      container: true,
      expanded: expanded,
      child: AnimatedContainer(
        key: ValueKey('profileAccordion-$index'),
        duration: duration,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: scheme.outlineVariant.withValues(
              alpha: expanded ? 0.82 : 0.52,
            ),
            width: AppBorderWidth.hairline,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('profileAccordionTrigger-$index'),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: duration,
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: FaIcon(
                            icon,
                            size: AppIconSize.sm,
                            color: expanded
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.semanticColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: duration,
                          curve: Curves.easeOutCubic,
                          child: FaIcon(
                            FontAwesomeIcons.chevronDown,
                            size: 14,
                            color: context.semanticColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: duration,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: expanded
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: Divider(
                              height: 1,
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          child,
                        ],
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// fst:auth:start
/// Hairline separator between rows within an expanded section.
class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
      color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}
// fst:auth:end

class ProfileSettingsTile extends StatelessWidget {
  const ProfileSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  final FaIconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final foreground = isDestructive
        ? context.colorScheme.error
        : context.colorScheme.onSurface;
    final accent = isDestructive
        ? context.colorScheme.error
        : context.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: FaIcon(icon, size: AppIconSize.sm, color: accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.semanticColors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

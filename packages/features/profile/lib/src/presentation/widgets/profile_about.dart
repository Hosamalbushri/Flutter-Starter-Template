part of 'profile_widgets.dart';

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: _AppInfoTile(),
    );
  }
}

class _AppInfoTile extends StatelessWidget {
  const _AppInfoTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final info = state.packageInfo;
        return _ProfileSettingsTile(
          icon: FontAwesomeIcons.mobileScreenButton,
          title: info?.appName ?? '—',
          subtitle: info == null
              ? context.l10n.commonLoading
              : context.l10n.profileAppVersionBuild(
                  info.version,
                  info.buildNumber,
                ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              context.l10n.profileAppStatus,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.semanticColors.mutedForeground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}

// fst:auth:start
class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final isLoading = session.isSigningOut;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: AppButton(
            label: context.l10n.commonSignOut,
            icon: FontAwesomeIcons.arrowRightFromBracket,
            variant: AppButtonVariant.outlined,
            expand: true,
            isLoading: isLoading,
            onPressed: isLoading ? null : () => _confirmSignOut(context),
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.commonSignOut,
      message: l10n.profileSignOutConfirmMessage,
      confirmLabel: l10n.commonSignOut,
      cancelLabel: l10n.commonCancel,
      icon: FontAwesomeIcons.arrowRightFromBracket,
      isDestructive: false,
    );
    if (confirmed && context.mounted) {
      SessionScope.of(context).signOut();
    }
  }
}

// fst:auth:end

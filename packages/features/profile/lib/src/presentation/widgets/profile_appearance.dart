part of 'profile_widgets.dart';

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final locale = state.locale?.languageCode == 'ar'
            ? 'العربية'
            : state.locale?.languageCode == 'en'
            ? 'English'
            : context.l10n.profileThemeSystemDefault;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('openSystemSettings'),
            onTap: () => context.push('/profile/system-settings'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.systemSettingsOpen,
                          style: context.textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${_themeLabel(context, state.mode)} · $locale · '
                          '${_fontLabel(context, state.fontFamily)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.semanticColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FaIcon(
                    Directionality.of(context) == TextDirection.rtl
                        ? FontAwesomeIcons.chevronLeft
                        : FontAwesomeIcons.chevronRight,
                    size: 14,
                    color: context.semanticColors.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _themeLabel(BuildContext context, ThemeMode mode) => switch (mode) {
    ThemeMode.system => context.l10n.profileThemeSystemDefault,
    ThemeMode.light => context.l10n.profileThemeLight,
    ThemeMode.dark => context.l10n.profileThemeDark,
  };

  String _fontLabel(BuildContext context, String font) =>
      font == 'system' ? context.l10n.systemSettingsFontSystem : font;
}

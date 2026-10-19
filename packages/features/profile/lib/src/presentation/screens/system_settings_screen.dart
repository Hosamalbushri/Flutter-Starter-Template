import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:localization/localization.dart';
import 'package:theme/theme.dart';

import '../bloc/font_catalog_cubit.dart';
import '../widgets/font_picker_sheet.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.systemSettingsTitle,
      subtitle: context.l10n.systemSettingsSubtitle,
      padding: EdgeInsets.zero,
      body: AppPageLayout.settings(
        controller: _scrollController,
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsSection(
                icon: FontAwesomeIcons.sliders,
                title: context.l10n.systemSettingsAppearance,
                subtitle: context.l10n.systemSettingsAppearanceHint,
                children: [
                  _SettingLabel(context.l10n.profileAppearanceThemeLabel),
                  _ThemeModeControl(value: state.mode),
                  const SizedBox(height: AppSpacing.lg),
                  _SettingLabel(context.l10n.profileAppearanceColorLabel),
                  _ColorControl(value: state.scheme),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SettingsSection(
                icon: FontAwesomeIcons.font,
                title: context.l10n.systemSettingsTypography,
                subtitle: context.l10n.systemSettingsTypographyHint,
                children: [
                  _SettingLabel(context.l10n.systemSettingsFont),
                  _FontControl(value: state.fontFamily),
                  const SizedBox(height: AppSpacing.lg),
                  _SettingLabel(context.l10n.systemSettingsTextSize),
                  _TextScaleControl(value: state.textScale),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SettingsSection(
                icon: FontAwesomeIcons.language,
                title: context.l10n.profileAppearanceLanguageLabel,
                subtitle: context.l10n.systemSettingsLanguageHint,
                children: [_LanguageControl(value: state.locale)],
              ),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                key: const ValueKey('resetSystemSettings'),
                onPressed: () => context.read<ThemeBloc>().add(
                  const ThemeSettingsReset(),
                ),
                icon: const FaIcon(
                  FontAwesomeIcons.arrowRotateLeft,
                  size: AppIconSize.sm,
                ),
                label: Text(context.l10n.systemSettingsReset),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final FaIconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.75),
            width: AppBorderWidth.hairline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: context.colorScheme.surfaceContainerLow,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: FaIcon(
                      icon,
                      size: AppIconSize.sm,
                      color: context.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.semanticColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingLabel extends StatelessWidget {
  const _SettingLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: context.textTheme.labelLarge?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ThemeModeControl extends StatelessWidget {
  const _ThemeModeControl({required this.value});

  final ThemeMode value;

  @override
  Widget build(BuildContext context) {
    return _OptionGrid<ThemeMode>(
      value: value,
      options: [
        _Option(
          ThemeMode.system,
          context.l10n.profileThemeSystemDefault,
          FontAwesomeIcons.circleHalfStroke,
        ),
        _Option(
          ThemeMode.light,
          context.l10n.profileThemeLight,
          FontAwesomeIcons.sun,
        ),
        _Option(
          ThemeMode.dark,
          context.l10n.profileThemeDark,
          FontAwesomeIcons.moon,
        ),
      ],
      onChanged: (value) =>
          context.read<ThemeBloc>().add(ThemeModeChanged(value)),
    );
  }
}

class _TextScaleControl extends StatelessWidget {
  const _TextScaleControl({required this.value});

  final AppTextScale value;

  @override
  Widget build(BuildContext context) {
    return _OptionGrid<AppTextScale>(
      value: value,
      columns: 2,
      options: [
        _Option(
          AppTextScale.system,
          context.l10n.profileThemeSystemDefault,
          FontAwesomeIcons.mobileScreen,
        ),
        _Option(
          AppTextScale.compact,
          context.l10n.systemSettingsTextCompact,
          FontAwesomeIcons.minus,
        ),
        _Option(
          AppTextScale.standard,
          context.l10n.systemSettingsTextStandard,
          FontAwesomeIcons.font,
        ),
        _Option(
          AppTextScale.large,
          context.l10n.systemSettingsTextLarge,
          FontAwesomeIcons.plus,
        ),
      ],
      onChanged: (value) =>
          context.read<ThemeBloc>().add(ThemeTextScaleChanged(value)),
    );
  }
}

class _Option<T> {
  const _Option(this.value, this.label, this.icon);
  final T value;
  final String label;
  final FaIconData icon;
}

class _OptionGrid<T> extends StatelessWidget {
  const _OptionGrid({
    required this.value,
    required this.options,
    required this.onChanged,
    this.columns = 3,
  });

  final T value;
  final List<_Option<T>> options;
  final ValueChanged<T> onChanged;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - (AppSpacing.sm * (columns - 1))) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in options)
              SizedBox(
                width: width,
                child: _OptionButton(
                  key: ValueKey('systemSetting-${option.value}'),
                  label: option.label,
                  icon: option.icon,
                  selected: value == option.value,
                  onTap: () => onChanged(option.value),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final FaIconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? context.colorScheme.primaryContainer
          : context.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: AppDurations.xfast,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected
                  ? context.colorScheme.primary
                  : context.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: AppIconSize.sm,
                color: selected
                    ? context.colorScheme.primary
                    : context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? context.colorScheme.onPrimaryContainer
                      : context.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FontControl extends StatelessWidget {
  const _FontControl({required this.value});

  final String value;

  void _openPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => BlocProvider(
        create: (_) => FontCatalogCubit(loadGoogleFontsPage)..loadInitial(),
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.84,
          child: FontPickerSheet(selected: value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        key: const ValueKey('openFontLibrary'),
        onTap: () => _openPicker(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: FaIcon(
                  FontAwesomeIcons.textHeight,
                  size: AppIconSize.sm,
                  color: context.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value == 'system'
                          ? context.l10n.systemSettingsFontSystem
                          : value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.systemSettingsBrowseFonts,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.semanticColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FaIcon(
                FontAwesomeIcons.chevronDown,
                size: 13,
                color: context.semanticColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageControl extends StatelessWidget {
  const _LanguageControl({required this.value});

  final Locale? value;

  @override
  Widget build(BuildContext context) {
    final options = <(Locale?, String, String)>[
      (
        null,
        context.l10n.profileThemeSystemDefault,
        context.l10n.systemSettingsLanguageSystemHint,
      ),
      (const Locale('ar'), 'العربية', 'العربية'),
      (const Locale('en'), 'English', 'English'),
    ];
    return Column(
      children: [
        for (final (index, option) in options.indexed) ...[
          if (index > 0) const Divider(height: 1),
          _SelectionTile(
            key: ValueKey('language-${option.$1?.languageCode ?? 'system'}'),
            title: option.$2,
            subtitle: option.$3,
            selected: value?.languageCode == option.$1?.languageCode,
            onTap: () => context.read<ThemeBloc>().add(
              ThemeLocaleChanged(option.$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.semanticColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AnimatedContainer(
              duration: AppDurations.xfast,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? context.colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? context.colorScheme.primary
                      : context.colorScheme.outline,
                ),
              ),
              child: selected
                  ? FaIcon(
                      FontAwesomeIcons.check,
                      size: 11,
                      color: context.colorScheme.onPrimary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorControl extends StatelessWidget {
  const _ColorControl({required this.value});

  final FlexScheme value;

  static const schemes = <FlexScheme>[
    FlexScheme.bahamaBlue,
    FlexScheme.indigo,
    FlexScheme.green,
    FlexScheme.sakura,
    FlexScheme.mango,
    FlexScheme.material,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final scheme in schemes)
          Semantics(
            button: true,
            selected: value == scheme,
            label: scheme.name,
            child: InkWell(
              key: ValueKey('color-${scheme.name}'),
              customBorder: const CircleBorder(),
              onTap: () => context.read<ThemeBloc>().add(
                ThemeSchemeChanged(scheme),
              ),
              child: Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: value == scheme
                        ? context.colorScheme.onSurface
                        : context.colorScheme.outlineVariant,
                    width: value == scheme ? 2 : 1,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _color(scheme),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _color(FlexScheme scheme) => switch (scheme) {
    FlexScheme.bahamaBlue => const Color(0xFF006C84),
    FlexScheme.indigo => const Color(0xFF3F51B5),
    FlexScheme.green => const Color(0xFF2E7D32),
    FlexScheme.sakura => const Color(0xFFC2185B),
    FlexScheme.mango => const Color(0xFFEF6C00),
    _ => const Color(0xFF6750A4),
  };
}

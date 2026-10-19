import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:localization/localization.dart';
import 'package:theme/theme.dart';

import '../bloc/font_catalog_cubit.dart';

class FontPickerSheet extends StatefulWidget {
  const FontPickerSheet({super.key, required this.selected});

  final String selected;

  @override
  State<FontPickerSheet> createState() => _FontPickerSheetState();
}

class _FontPickerSheetState extends State<FontPickerSheet> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 240) {
      context.read<FontCatalogCubit>().loadMore();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 280),
      () => context.read<FontCatalogCubit>().search(value),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _select(String family) {
    context.read<ThemeBloc>().add(ThemeFontFamilyChanged(family));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.systemSettingsFontLibrary,
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.systemSettingsFontLibraryHint,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.semanticColors.mutedForeground,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const ValueKey('fontSearchField'),
                controller: _searchController,
                autofocus: false,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: context.l10n.systemSettingsFontSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: BlocBuilder<FontCatalogCubit, FontCatalogState>(
            builder: (context, state) {
              if (state.isInitialLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.error != null && state.items.isEmpty) {
                return _FontLoadError(
                  onRetry: context.read<FontCatalogCubit>().retry,
                );
              }
              if (state.items.isEmpty) {
                return Center(
                  child: Text(context.l10n.systemSettingsFontNoResults),
                );
              }
              return ListView.separated(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: state.items.length + 2,
                separatorBuilder: (_, index) => index == 0
                    ? const Divider(height: 1)
                    : Divider(
                        height: 1,
                        indent: 56,
                        color: context.colorScheme.outlineVariant.withValues(
                          alpha: 0.45,
                        ),
                      ),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _FontResultTile(
                      family: 'system',
                      label: context.l10n.systemSettingsFontSystem,
                      selected: widget.selected == 'system',
                      onTap: () => _select('system'),
                    );
                  }
                  if (index == state.items.length + 1) {
                    return _FontListFooter(state: state);
                  }
                  final family = state.items[index - 1];
                  return _FontResultTile(
                    family: family,
                    label: family,
                    selected: widget.selected == family,
                    onTap: () => _select(family),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FontListFooter extends StatelessWidget {
  const _FontListFooter({required this.state});

  final FontCatalogState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (state.error != null) {
      return TextButton.icon(
        onPressed: context.read<FontCatalogCubit>().loadMore,
        icon: const Icon(Icons.refresh),
        label: Text(context.l10n.systemSettingsRetry),
      );
    }
    return const SizedBox(height: AppSpacing.lg);
  }
}

class _FontLoadError extends StatelessWidget {
  const _FontLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.triangleExclamation,
            color: context.colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(context.l10n.systemSettingsFontLoadError),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onRetry,
            child: Text(context.l10n.systemSettingsRetry),
          ),
        ],
      ),
    );
  }
}

class _FontResultTile extends StatelessWidget {
  const _FontResultTile({
    required this.family,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String family;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('fontResult-$family'),
      selected: selected,
      onTap: onTap,
      title: Text(
        label,
        style: context.textTheme.titleSmall,
      ),
      trailing: selected
          ? FaIcon(
              FontAwesomeIcons.check,
              size: AppIconSize.sm,
              color: context.colorScheme.primary,
            )
          : null,
    );
  }
}

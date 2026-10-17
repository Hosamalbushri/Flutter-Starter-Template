import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app_ui.dart';

/// Theme-driven single-value selector with the same geometry as [AppTextField].
class AppSelector<T> extends StatelessWidget {
  const AppSelector({
    super.key,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.value,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.enabled = true,
  });

  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final FaIconData? prefixIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      style: AppTypography.body(context.textTheme),
      icon: const FaIcon(
        FontAwesomeIcons.chevronDown,
        size: AppIconSize.sm,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon == null
            ? null
            : Center(
                widthFactor: 1,
                heightFactor: 1,
                child: FaIcon(prefixIcon, size: AppIconSize.md),
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem<T>(
            value: item,
            child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: enabled && onChanged != null
          ? (selected) {
              HapticFeedback.selectionClick();
              onChanged!(selected);
            }
          : null,
    );
  }
}

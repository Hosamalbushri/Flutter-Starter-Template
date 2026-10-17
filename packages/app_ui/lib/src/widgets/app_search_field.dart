import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app_ui.dart';

/// Search input that shares [AppTextField] styling and exposes a localized
/// clear action without owning any application copy.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.clearTooltip,
    this.autofocus = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? clearTooltip;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late TextEditingController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _setController(widget.controller);
  }

  @override
  void didUpdateWidget(AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_handleTextChanged);
      if (_ownsController) _controller.dispose();
      _setController(widget.controller);
    }
  }

  void _setController(TextEditingController? external) {
    _ownsController = external == null;
    _controller = external ?? TextEditingController();
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    if (mounted) setState(() {});
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: widget.label,
      hint: widget.hint,
      prefixIcon: FontAwesomeIcons.magnifyingGlass,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffix: _controller.text.isEmpty
          ? null
          : IconButton(
              tooltip:
                  widget.clearTooltip ??
                  MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: widget.enabled ? _clear : null,
              icon: const FaIcon(
                FontAwesomeIcons.xmark,
                size: AppIconSize.md,
              ),
            ),
    );
  }
}

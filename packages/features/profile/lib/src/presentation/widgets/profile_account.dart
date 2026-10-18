part of 'profile_widgets.dart';

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChangePasswordTile(),
          _SettingsDivider(),
          _DeleteAccountTile(),
        ],
      ),
    );
  }
}

class _ChangePasswordTile extends StatelessWidget {
  const _ChangePasswordTile();

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return _ProfileSettingsTile(
      icon: FontAwesomeIcons.key,
      title: context.l10n.profileChangePassword,
      subtitle: context.l10n.profileChangePasswordSubtitle,
      trailing: FaIcon(
        isRtl ? FontAwesomeIcons.chevronLeft : FontAwesomeIcons.chevronRight,
        size: 14,
        color: context.semanticColors.mutedForeground,
      ),
      onTap: () {
        context.push<void>('/profile/change-password');
      },
    );
  }
}

class _DeleteAccountTile extends StatelessWidget {
  const _DeleteAccountTile();

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return BlocBuilder<DeleteAccountCubit, DeleteAccountState>(
      builder: (context, state) {
        final isSubmitting = state is DeleteAccountSubmitting;
        return _ProfileSettingsTile(
          icon: FontAwesomeIcons.trash,
          title: context.l10n.profileDeleteAccount,
          subtitle: context.l10n.profileDeleteAccountSubtitle,
          isDestructive: true,
          trailing: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : FaIcon(
                  isRtl
                      ? FontAwesomeIcons.chevronLeft
                      : FontAwesomeIcons.chevronRight,
                  size: 14,
                  color: error.withValues(alpha: 0.65),
                ),
          onTap: isSubmitting ? null : () => _confirmAndDelete(context),
        );
      },
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final username = SessionScope.of(context).currentUser?.username;
    if (username == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteAccountDialog(username: username),
    );
    if (confirmed == true && context.mounted) {
      await context.read<DeleteAccountCubit>().submit();
    }
  }
}

/// Confirmation dialog that requires the user to type their username before
/// the destructive delete button becomes enabled.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.username});

  final String username;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canDelete = _controller.text.trim() == widget.username;
    return AppConfirmDialog(
      title: l10n.profileDeleteAccountDialogTitle,
      message: l10n.profileDeleteAccountDialogMessage,
      confirmLabel: l10n.commonDelete,
      cancelLabel: l10n.commonCancel,
      confirmEnabled: canDelete,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
      content: AppTextField(
        controller: _controller,
        label: l10n.profileDeleteAccountConfirmLabel(widget.username),
        autofocus: true,
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}

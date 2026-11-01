import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/folders_providers.dart';
import '../domain/trip_folder.dart';

/// Wybór folderu pinezki (v10). `null` oznacza domyślny „Pinezki” –
/// istniejący albo tworzony przy zapisie.
class FolderPicker extends ConsumerWidget {
  const FolderPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.offerDefault = true,
  });

  final String? value;

  /// Pokazuje „Pinezki”, nawet gdy jeszcze nie istnieje (nowa pinezka).
  final bool offerDefault;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider).value ?? const <TripFolder>[];
    final defaultFolder = folders
        .where((f) => f.name == TripFolder.defaultName)
        .firstOrNull;

    bool selected(TripFolder f) =>
        f.id == value || (value == null && f.id == defaultFolder?.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.folderLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (offerDefault && defaultFolder == null)
              _FolderChip(
                key: const ValueKey('folder-default'),
                label: TripFolder.defaultName,
                icon: FolderIcon.camper,
                color: FolderColor.emerald,
                selected: value == null,
                onSelected: () => onChanged(null),
              ),
            for (final folder in folders)
              _FolderChip(
                key: ValueKey('folder-${folder.id}'),
                label: folder.name,
                icon: folder.icon,
                color: folder.color,
                selected: selected(folder),
                onSelected: () => onChanged(folder.id),
              ),
            ActionChip(
              key: const ValueKey('folder-new'),
              avatar: const Icon(Icons.add),
              label: Text(l10n.folderNew),
              onPressed: () => _quickCreate(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _quickCreate(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _QuickCreateDialog(),
    );
    if (name == null) return;
    try {
      final id = await ref.read(foldersControllerProvider).create(name: name);
      onChanged(id);
    } catch (e) {
      debugPrint('Utworzenie folderu nie powiodło się: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).folderSaveError)),
        );
      }
    }
  }
}

class _FolderChip extends StatelessWidget {
  const _FolderChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final FolderIcon icon;
  final FolderColor color;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: Icon(icon.icon, color: color.color, size: 18),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
    );
  }
}

/// Szybkie utworzenie folderu z samą nazwą; ikonę i kolor zmienia się potem w edycji.
class _QuickCreateDialog extends StatefulWidget {
  const _QuickCreateDialog();

  @override
  State<_QuickCreateDialog> createState() => _QuickCreateDialogState();
}

class _QuickCreateDialogState extends State<_QuickCreateDialog> {
  final _name = TextEditingController();
  bool _empty = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _empty = true);
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.folderQuickCreateTitle),
      content: TextField(
        controller: _name,
        autofocus: true,
        maxLength: TripFolder.maxNameLength,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: l10n.folderNameLabel,
          errorText: _empty ? l10n.folderNameRequired : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.pinCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.folderCreate)),
      ],
    );
  }
}

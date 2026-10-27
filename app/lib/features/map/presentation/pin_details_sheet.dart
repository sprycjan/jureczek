import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/place_pin.dart';
import 'pin_form_fields.dart';

/// Dolny arkusz po tapnięciu w pinezkę: podgląd, edycja nazwy, adresu i notatki, usuwanie.
class PinDetailsSheet extends StatefulWidget {
  const PinDetailsSheet({
    super.key,
    required this.pin,
    required this.onDelete,
    required this.onSave,
    this.notice,
  });

  final PlacePin pin;
  final VoidCallback onDelete;
  final SavePinDetails onSave;

  /// Komunikat nad nazwą, np. „Ta pinezka już jest” po udostępnieniu duplikatu.
  final String? notice;

  @override
  State<PinDetailsSheet> createState() => _PinDetailsSheetState();
}

class _PinDetailsSheetState extends State<PinDetailsSheet> {
  late String? _name = widget.pin.name;
  late String? _note = widget.pin.note;
  late String? _address = widget.pin.address;
  bool _editing = false;
  bool _saving = false;
  bool _saveFailed = false;

  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _startEditing() {
    _nameController.text = _name ?? '';
    _noteController.text = _note ?? '';
    _addressController.text = _address ?? '';
    setState(() {
      _editing = true;
      _saveFailed = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.onSave((
      name: _nameController.text,
      address: _addressController.text,
      note: _noteController.text,
    ));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saveFailed = !ok;
      if (ok) {
        _name = _nonEmpty(_nameController.text);
        _note = _nonEmpty(_noteController.text);
        _address = _nonEmpty(_addressController.text);
        _editing = false;
      }
    });
  }

  Future<void> _openSource(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) debugPrint('Nie udało się otworzyć linku źródłowego');
  }

  static String? _nonEmpty(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: _editing ? _buildEditor(context) : _buildDetails(context),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pin = widget.pin;
    final date = DateFormat.yMMMd('pl').format(pin.createdAt);
    final sourceUrl = pin.sourceUrl;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.notice != null) ...[
          Text(
            widget.notice!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(l10n.pinSheetTitle, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(_name ?? l10n.pinUnnamed, style: theme.textTheme.titleLarge),
        if (_address != null) ...[
          const SizedBox(height: 4),
          Text(_address!, style: theme.textTheme.bodyMedium),
        ],
        if (_note != null) ...[
          const SizedBox(height: 8),
          Text(_note!, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: 12),
        Text(
          '${pin.lat.toStringAsFixed(4)}, ${pin.lng.toStringAsFixed(4)}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(l10n.pinAddedOn(date), style: theme.textTheme.bodyMedium),
        if (sourceUrl != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => _openSource(sourceUrl),
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.pinOpenInGoogleMaps),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _startEditing,
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.pinEdit),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.pinDelete),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditor(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.pinSheetTitle, style: theme.textTheme.labelLarge),
        const SizedBox(height: 12),
        PinFormFields(
          name: _nameController,
          address: _addressController,
          note: _noteController,
          autofocus: true,
        ),
        if (_saveFailed) ...[
          const SizedBox(height: 8),
          Text(
            l10n.pinsSaveError,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving
                    ? null
                    : () => setState(() => _editing = false),
                child: Text(l10n.pinCancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(l10n.pinSave),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

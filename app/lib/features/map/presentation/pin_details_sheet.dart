import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../folders/presentation/folder_picker.dart';
import '../domain/pin_kind.dart';
import '../domain/pin_color.dart';
import '../domain/place_pin.dart';
import 'pin_type_picker.dart';
import 'pin_color_picker.dart';
import 'pin_image.dart';
import 'pin_form_fields.dart';

/// Dolny arkusz po tapnięciu w pinezkę: podgląd, edycja typu, koloru, nazwy, adresu i notatki, usuwanie.
class PinDetailsSheet extends StatefulWidget {
  const PinDetailsSheet({
    super.key,
    required this.pin,
    required this.onDelete,
    required this.onSave,
    this.notice,
    this.canMoveFolder = false,
  });

  final PlacePin pin;
  final VoidCallback onDelete;
  final SavePinDetails onSave;

  /// Komunikat nad nazwą, np. „Ta pinezka już jest” po udostępnieniu duplikatu.
  final String? notice;

  /// W edycji można przenieść pinezkę do innego folderu (v10).
  final bool canMoveFolder;

  @override
  State<PinDetailsSheet> createState() => _PinDetailsSheetState();
}

class _PinDetailsSheetState extends State<PinDetailsSheet> {
  late String? _name = widget.pin.name;
  late String? _note = widget.pin.note;
  late String? _address = widget.pin.address;
  late PinKind _kind = widget.pin.kind;
  late PinKind _editedKind = _kind;
  late PinColor? _color = widget.pin.color;
  late PinColor? _editedColor = _color;
  late String _folderId = widget.pin.folderId;
  late String _editedFolderId = _folderId;
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
    _editedKind = _kind;
    _editedColor = _color;
    _editedFolderId = _folderId;
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
      kind: _editedKind,
      color: _editedColor,
      folderId: widget.canMoveFolder ? _editedFolderId : null,
    ));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saveFailed = !ok;
      if (ok) {
        _name = _nonEmpty(_nameController.text);
        _note = _nonEmpty(_noteController.text);
        _address = _nonEmpty(_addressController.text);
        _kind = _editedKind;
        _color = _editedColor;
        _folderId = _editedFolderId;
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
        Row(
          children: [
            PinImage(_kind, color: _color, height: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _kind.label(l10n),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
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
        PinTypePicker(
          value: _editedKind,
          color: _editedColor,
          onChanged: (kind) => setState(() => _editedKind = kind),
        ),
        const SizedBox(height: 12),
        PinColorPicker(
          value: _editedColor,
          onChanged: (color) => setState(() => _editedColor = color),
        ),
        const SizedBox(height: 16),
        if (widget.canMoveFolder) ...[
          FolderPicker(
            value: _editedFolderId,
            offerDefault: false,
            onChanged: (id) {
              if (id != null) setState(() => _editedFolderId = id);
            },
          ),
          const SizedBox(height: 16),
        ],
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

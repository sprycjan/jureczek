import 'package:flutter/material.dart';

import '../../folders/presentation/folder_picker.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/pin_kind.dart';
import '../domain/pin_color.dart';
import '../domain/place_suggestion.dart';
import 'pin_type_picker.dart';
import 'pin_color_picker.dart';
import 'pin_form_fields.dart';

/// Arkusz „Nowa pinezka”: typ i kolor pinezki oraz dane z long-tapu, wyniku lub udostępnienia
/// do poprawienia przed zapisem.
class NewPinSheet extends StatefulWidget {
  const NewPinSheet({
    super.key,
    required this.place,
    required this.onSave,
    this.chooseFolder = false,
    this.addressLookup,
  });

  final PlaceResult place;
  final SavePinDetails onSave;

  /// Adres POI pobierany w tle (v19); trafia do pustego pola, a „Zapisz” na niego
  /// czeka, żeby zapisał się z pinezką. Nie może kończyć się błędem.
  final Future<String?>? addressLookup;

  /// Wybór folderu – poza trybem folderu na mapie (v10).
  final bool chooseFolder;

  @override
  State<NewPinSheet> createState() => _NewPinSheetState();
}

class _NewPinSheetState extends State<NewPinSheet> {
  late final _name = TextEditingController(text: widget.place.name);
  late final _address = TextEditingController(text: widget.place.address);
  final _note = TextEditingController();

  /// Podpowiedź z `maki` POI lub wyniku wyszukiwania (v16), inaczej zielona.
  late var _kind = PinKind(widget.place.suggestedType);
  PinColor? _color;
  String? _folderId;
  bool _saving = false;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    widget.addressLookup?.then((address) {
      if (mounted && address != null && _address.text.trim().isEmpty) {
        _address.text = address;
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.addressLookup;
    if (!mounted) return;
    final ok = await widget.onSave((
      name: _name.text,
      address: _address.text,
      note: _note.text,
      kind: _kind,
      color: _color,
      folderId: _folderId,
    ));
    if (!mounted || ok) return;
    setState(() {
      _saving = false;
      _saveFailed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.pinNewTitle, style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              PinTypePicker(
                value: _kind,
                color: _color,
                onChanged: (kind) => setState(() => _kind = kind),
              ),
              const SizedBox(height: 12),
              PinColorPicker(
                value: _color,
                onChanged: (color) => setState(() => _color = color),
              ),
              const SizedBox(height: 16),
              if (widget.chooseFolder) ...[
                FolderPicker(
                  value: _folderId,
                  onChanged: (id) => setState(() => _folderId = id),
                ),
                const SizedBox(height: 16),
              ],
              PinFormFields(name: _name, address: _address, note: _note),
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
                          : () => Navigator.of(context).pop(),
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
          ),
        ),
      ),
    );
  }
}

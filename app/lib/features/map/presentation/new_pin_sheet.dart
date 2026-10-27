import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/place_suggestion.dart';
import 'pin_form_fields.dart';

/// Arkusz „Nowa pinezka”: dane z wyniku lub udostępnienia do poprawienia przed zapisem.
class NewPinSheet extends StatefulWidget {
  const NewPinSheet({super.key, required this.place, required this.onSave});

  final PlaceResult place;
  final SavePinDetails onSave;

  @override
  State<NewPinSheet> createState() => _NewPinSheetState();
}

class _NewPinSheetState extends State<NewPinSheet> {
  late final _name = TextEditingController(text: widget.place.name);
  late final _address = TextEditingController(text: widget.place.address);
  final _note = TextEditingController();
  bool _saving = false;
  bool _saveFailed = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.onSave((
      name: _name.text,
      address: _address.text,
      note: _note.text,
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

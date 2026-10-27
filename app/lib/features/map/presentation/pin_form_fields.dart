import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/place_pin.dart';

/// Teksty z formularza pinezki, przed obcięciem białych znaków.
typedef PinDetailsInput = ({String name, String address, String note});

/// Zapisuje dane pinezki; zwraca `false`, gdy się nie udało.
typedef SavePinDetails = Future<bool> Function(PinDetailsInput details);

/// Pola nazwy, adresu i notatki – wspólne dla edycji i dodawania pinezki.
class PinFormFields extends StatelessWidget {
  const PinFormFields({
    super.key,
    required this.name,
    required this.address,
    required this.note,
    this.autofocus = false,
  });

  final TextEditingController name;
  final TextEditingController address;
  final TextEditingController note;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: name,
          autofocus: autofocus,
          maxLength: PlacePin.maxNameLength,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.pinNameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: address,
          maxLength: PlacePin.maxAddressLength,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.pinAddressLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: note,
          maxLength: PlacePin.maxNoteLength,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.pinNoteLabel,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

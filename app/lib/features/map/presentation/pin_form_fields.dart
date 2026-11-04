import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/pin_kind.dart';
import '../domain/pin_color.dart';
import '../domain/place_pin.dart';
import 'pin_image.dart';

/// Teksty z formularza pinezki, przed obcięciem białych znaków.
typedef PinDetailsInput = ({
  String name,
  String address,
  String note,
  PinKind kind,

  /// Własny kolor (v14); `null` – kolor typu.
  PinColor? color,

  /// Wybrany folder; `null` to domyślny „Pinezki” albo „bez zmiany”, gdy
  /// arkusz nie pokazuje wyboru folderu.
  String? folderId,

  /// Gwiazdka z formularza nowej pinezki (v22). W istniejącej pinezce zapisuje
  /// ją od razu przycisk w podglądzie, więc zapis edycji pomija to pole.
  bool starred,
});

/// Zapisuje dane pinezki; zwraca `false`, gdy się nie udało.
typedef SavePinDetails = Future<bool> Function(PinDetailsInput details);

/// Przełącznik gwiazdki (v22) – w podglądzie pinezki i formularzu nowej.
class PinStarButton extends StatelessWidget {
  const PinStarButton({
    super.key,
    required this.starred,
    required this.onPressed,
  });

  final bool starred;

  /// `null` wyłącza przycisk, np. w trakcie zapisu.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      key: const ValueKey('pin-starred-button'),
      visualDensity: VisualDensity.compact,
      tooltip: starred ? l10n.pinUnmarkStarred : l10n.pinMarkStarred,
      onPressed: onPressed,
      icon: Icon(
        starred ? Icons.star : Icons.star_border,
        size: 20,
        color: starred
            ? pinStarColor
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Pola nazwy, adresu i notatki – wspólne dla edycji i dodawania pinezki.
class PinFormFields extends StatelessWidget {
  const PinFormFields({
    super.key,
    required this.name,
    required this.address,
    required this.note,
  });

  final TextEditingController name;
  final TextEditingController address;
  final TextEditingController note;

  /// Licznik znaków pojawia się dopiero od tej części limitu (v17).
  static const _counterFrom = 0.8;

  static Widget? _counter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) {
    if (maxLength == null || currentLength < maxLength * _counterFrom) {
      return null;
    }
    return Text('$currentLength/$maxLength');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: name,
          maxLength: PlacePin.maxNameLength,
          buildCounter: _counter,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: _decoration(l10n.pinNameLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: address,
          maxLength: PlacePin.maxAddressLength,
          buildCounter: _counter,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: _decoration(l10n.pinAddressLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: note,
          maxLength: PlacePin.maxNoteLength,
          buildCounter: _counter,
          minLines: 1,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: _decoration(l10n.pinNoteLabel),
        ),
      ],
    );
  }

  static InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    isDense: true,
    border: const OutlineInputBorder(),
  );
}

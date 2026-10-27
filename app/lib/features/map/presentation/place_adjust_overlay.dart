import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Celownik na środku mapy; czubek pinezki wskazuje środek kamery.
class PlaceAdjustCrosshair extends StatelessWidget {
  const PlaceAdjustCrosshair({super.key});

  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
    // Nie przechwytuje gestów – mapa pod spodem dalej się przesuwa.
    return IgnorePointer(
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, -_size / 2),
          child: Icon(
            Icons.location_on,
            size: _size,
            color: Theme.of(context).colorScheme.primary,
            shadows: const [Shadow(blurRadius: 4, color: Colors.black38)],
          ),
        ),
      ),
    );
  }
}

/// Karta trybu „Popraw położenie”: podpowiedź, „Anuluj” i „Gotowe”.
class PlaceAdjustCard extends StatelessWidget {
  const PlaceAdjustCard({
    super.key,
    required this.onDone,
    required this.onCancel,
  });

  final VoidCallback onDone;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.placeAdjustHint,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: Text(l10n.pinCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onDone,
                    child: Text(l10n.placeAdjustDone),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

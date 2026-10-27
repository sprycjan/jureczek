import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/place_suggestion.dart';

/// Karta na dole mapy z wybranym wynikiem wyszukiwania albo udostępnionym miejscem.
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required PlaceResult this.result,
    required VoidCallback this.onAddPin,
    required VoidCallback this.onAdjust,
    this.onSearch,
    required this.onClose,
  });

  /// Udostępnione miejsce jest jeszcze ustalane.
  const SearchResultCard.loading({super.key, required this.onClose})
    : result = null,
      onAddPin = null,
      onAdjust = null,
      onSearch = null;

  final PlaceResult? result;
  final VoidCallback? onAddPin;

  /// Przesunięcie miejsca pod celownikiem przed dodaniem pinezki.
  final VoidCallback? onAdjust;

  /// Szukanie miejsca po nazwie, gdy położenie jest tylko przybliżone.
  final VoidCallback? onSearch;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final result = this.result;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    result == null
                        ? l10n.shareLoading
                        : result.name ?? l10n.pinUnnamed,
                    style: textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: l10n.searchResultClose,
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            if (result == null)
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 8, 12, 0),
                child: LinearProgressIndicator(),
              )
            else ...[
              if (result.address != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(result.address!, style: textTheme.bodyMedium),
                ),
              if (result.approximate)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                  child: Text(
                    l10n.shareApproximate,
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: Text(l10n.searchAddPin),
                    onPressed: onAddPin,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.open_with),
                    label: Text(l10n.placeAdjust),
                    onPressed: onAdjust,
                  ),
                  if (onSearch != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.search),
                      label: Text(l10n.shareSearchByName),
                      onPressed: onSearch,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

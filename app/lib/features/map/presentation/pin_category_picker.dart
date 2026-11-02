import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/pin_category.dart';
import '../domain/pin_color.dart';
import 'pin_image.dart';

extension PinCategoryLabel on PinCategory {
  String label(AppLocalizations l10n) => switch (this) {
    PinCategory.standard => l10n.pinCategoryStandard,
    PinCategory.gastronomy => l10n.pinCategoryGastronomy,
    PinCategory.places => l10n.pinCategoryPlaces,
    PinCategory.nature => l10n.pinCategoryNature,
    PinCategory.activities => l10n.pinCategoryActivities,
    PinCategory.travel => l10n.pinCategoryTravel,
    PinCategory.entertainment => l10n.pinCategoryEntertainment,
    PinCategory.practical => l10n.pinCategoryPractical,
  };
}

/// Wybór typu pinezki: rząd 8 pinezek, wybrana podświetlona; nazwa wybranej pod spodem.
class PinCategoryPicker extends StatelessWidget {
  const PinCategoryPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.color,
  });

  final PinCategory value;
  final ValueChanged<PinCategory> onChanged;

  /// Wybrany własny kolor – pinezki w rzędzie pokazują się w nim (v14).
  final PinColor? color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              l10n.pinCategoryLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value.label(l10n),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              for (final category in PinCategory.values)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: category == value,
                    label: category.label(l10n),
                    child: Tooltip(
                      message: category.label(l10n),
                      child: InkWell(
                        key: ValueKey('pin-category-${category.key}'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onChanged(category),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 52,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: category == value
                                ? colors.surfaceContainerHighest
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: category == value
                                  ? colors.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: PinImage(category, color: color),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

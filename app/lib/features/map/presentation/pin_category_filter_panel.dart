import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../places/domain/place_category.dart';
import '../../places/domain/place_type.dart';
import '../../places/presentation/place_labels.dart';
import '../domain/pin_category_filter.dart';
import '../domain/pin_kind.dart';
import '../domain/place_pin.dart';
import 'pin_image.dart';

/// Lista kategorii rozwijana z przycisku filtra (v18). Każdy wybór działa od
/// razu, więc lista zostaje otwarta. Przewija się na niskim ekranie.
class PinCategoryFilterPanel extends StatelessWidget {
  const PinCategoryFilterPanel({
    super.key,
    required this.pins,
    required this.filter,
    required this.onChanged,
  });

  /// Pinezki widoku bez filtra kategorii – z nich są liczby przy pozycjach.
  final List<PlacePin> pins;
  final PinCategoryFilter filter;
  final ValueChanged<PinCategoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final counts = <PlaceCategory?, int>{};
    for (final pin in pins) {
      final category = pin.kind.type?.category;
      counts[category] = (counts[category] ?? 0) + 1;
    }

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FilterRow(
                key: const ValueKey('pin-filter-all'),
                leading: const SizedBox.square(
                  dimension: 32,
                  child: Icon(Icons.layers_outlined),
                ),
                label: l10n.mapFilterAll,
                count: pins.length,
                selected: !filter.isActive,
                onTap: () => onChanged(PinCategoryFilter.all),
              ),
              _FilterRow(
                key: const ValueKey('pin-filter-standard'),
                leading: const PinImage(PinKind.standard),
                label: l10n.pinCategoryStandard,
                count: counts[null] ?? 0,
                selected: filter.shows(null),
                onTap: () => onChanged(filter.toggle(null)),
              ),
              for (final category in PlaceCategory.values)
                _FilterRow(
                  key: ValueKey('pin-filter-${category.key}'),
                  leading: PinImage(PinKind(category.otherType)),
                  label: category.label(l10n),
                  count: counts[category] ?? 0,
                  selected: filter.shows(category),
                  onTap: () => onChanged(filter.toggle(category)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    super.key,
    required this.leading,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final Widget leading;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textColor = selected ? colors.onSurface : colors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Semantics(
        selected: selected,
        button: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: Row(
            spacing: 12,
            children: [
              // Przygaszona ikona: pinezki tej kategorii są ukryte.
              Opacity(opacity: selected ? 1 : 0.4, child: leading),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(color: textColor),
                ),
              ),
              Text(
                '$count',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Icon(selected ? Icons.check : null, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

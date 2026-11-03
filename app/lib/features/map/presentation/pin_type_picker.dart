import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../places/domain/place_category.dart';
import '../../places/domain/place_type.dart';
import '../../places/presentation/place_labels.dart';
import '../domain/pin_color.dart';
import '../domain/pin_kind.dart';
import 'pin_image.dart';

extension PinKindLabel on PinKind {
  /// „Pinezka” albo „Kawiarnia · Gastronomia”.
  String label(AppLocalizations l10n) =>
      type?.fullLabel(l10n) ?? l10n.pinCategoryStandard;
}

/// Wybór typu pinezki w dwóch krokach (v16): rząd 8 pozycji – zielona
/// „Pinezka” i 7 kategorii (ich pinezki „inne”) – a pod nim siatka typów
/// otwartej kategorii. Tap w kategorię tylko otwiera siatkę; wybór zmienia
/// dopiero tap w typ (albo w zieloną „Pinezkę”).
class PinTypePicker extends StatefulWidget {
  const PinTypePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.color,
  });

  final PinKind value;
  final ValueChanged<PinKind> onChanged;

  /// Wybrany własny kolor – pinezki pokazują się w nim (v14).
  final PinColor? color;

  @override
  State<PinTypePicker> createState() => _PinTypePickerState();
}

class _PinTypePickerState extends State<PinTypePicker> {
  /// Przy edycji od razu otwarta kategoria zapisanego typu.
  late PlaceCategory? _open = widget.value.type?.category;

  @override
  void didUpdateWidget(PinTypePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Wartość z zewnątrz (np. „Anuluj” w edycji, podpowiedź z POI) – siatka za nią.
    final category = widget.value.type?.category;
    if (widget.value != oldWidget.value && category != null) {
      _open = category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final value = widget.value;
    final open = _open;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Choice(
                      key: const ValueKey('pin-category-standard'),
                      label: l10n.pinCategoryStandard,
                      selected: value.isStandard,
                      highlighted: value.isStandard,
                      onTap: () {
                        setState(() => _open = null);
                        widget.onChanged(PinKind.standard);
                      },
                      child: PinImage(PinKind.standard, color: widget.color),
                    ),
                  ),
                  for (final category in PlaceCategory.values)
                    Expanded(
                      child: _Choice(
                        key: ValueKey('pin-category-${category.key}'),
                        label: category.label(l10n),
                        selected: value.type?.category == category,
                        highlighted: open == category,
                        onTap: () => setState(
                          () => _open = open == category ? null : category,
                        ),
                        child: PinImage(
                          PinKind(category.otherType),
                          color: widget.color,
                        ),
                      ),
                    ),
                ],
              ),
              if (open != null) ...[
                const Divider(height: 12),
                _TypeGrid(
                  category: open,
                  value: value,
                  color: widget.color,
                  onChanged: widget.onChanged,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Siatka typów kategorii: pinezka i nazwa, wybrany podświetlony.
class _TypeGrid extends StatelessWidget {
  const _TypeGrid({
    required this.category,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final PlaceCategory category;
  final PinKind value;
  final PinColor? color;
  final ValueChanged<PinKind> onChanged;

  static const _columns = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final types = PlaceType.of(category);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth / _columns;
        return Wrap(
          children: [
            for (final type in types)
              SizedBox(
                width: width,
                child: _Choice(
                  key: ValueKey('pin-type-${type.key}'),
                  label: type.label(l10n),
                  selected: value.type == type,
                  highlighted: value.type == type,
                  onTap: () => onChanged(PinKind(type)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PinImage(PinKind(type), color: color, height: 30),
                        const SizedBox(height: 2),
                        Text(
                          type.label(l10n),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Pole wyboru: [selected] – obwódka (bieżąca wartość), [highlighted] – tło.
class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.label,
    required this.selected,
    required this.highlighted,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final bool highlighted;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 52),
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: highlighted
                  ? colors.surfaceContainerHighest
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? colors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/widgets/select_field.dart';
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

/// Wybór typu pinezki (v17): dwa select boxy obok siebie, „Kategoria” i „Typ”.
///
/// Nowa kategoria od razu ustawia swój typ „Inne” i otwiera listę typów, więc
/// wartość jest zawsze poprawna. Zielona „Pinezka” jest pierwszą pozycją
/// kategorii i nie ma typów – pole „Typ” jest wtedy wyszarzone.
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
  static const _gap = 8.0;

  final _typeMenu = MenuController();

  void _selectCategory(PlaceCategory category) {
    // Ta sama kategoria nie kasuje wybranego typu.
    if (widget.value.type?.category != category) {
      widget.onChanged(PinKind(category.otherType));
    }
    // Po przebudowie, gdy lista ma już typy nowej kategorii.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _typeMenu.open();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = widget.value;
    final type = value.type;
    final category = type?.category;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fieldWidth = (width - _gap) / 2;
        return Row(
          children: [
            SizedBox(
              width: fieldWidth,
              child: SelectField(
                key: const ValueKey('pin-category-field'),
                label: l10n.pinCategoryField,
                value: category?.label(l10n) ?? l10n.pinCategoryStandard,
                leading: _pin(
                  category == null
                      ? PinKind.standard
                      : PinKind(category.otherType),
                ),
                menuWidth: width,
                options: [
                  SelectOption(
                    key: const ValueKey('pin-category-standard'),
                    label: l10n.pinCategoryStandard,
                    leading: _pin(PinKind.standard),
                    selected: value.isStandard,
                    onSelected: () => widget.onChanged(PinKind.standard),
                  ),
                  for (final option in PlaceCategory.values)
                    SelectOption(
                      key: ValueKey('pin-category-${option.key}'),
                      label: option.label(l10n),
                      leading: _pin(PinKind(option.otherType)),
                      selected: option == category,
                      onSelected: () => _selectCategory(option),
                    ),
                ],
              ),
            ),
            const SizedBox(width: _gap),
            SizedBox(
              width: fieldWidth,
              child: SelectField(
                key: const ValueKey('pin-type-field'),
                label: l10n.pinTypeField,
                value: type?.label(l10n) ?? l10n.pinTypeNone,
                leading: type == null ? null : _pin(PinKind(type)),
                enabled: type != null,
                // „Inne” jest na końcu, a po zmianie kategorii lista ma
                // pokazać typy od początku.
                revealSelected: type?.isOther != true,
                controller: _typeMenu,
                menuWidth: width,
                menuOffsetX: -(fieldWidth + _gap),
                options: [
                  if (category != null)
                    for (final option in PlaceType.of(category))
                      SelectOption(
                        key: ValueKey('pin-type-${option.key}'),
                        label: option.label(l10n),
                        leading: _pin(PinKind(option)),
                        selected: option == type,
                        onSelected: () => widget.onChanged(PinKind(option)),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pin(PinKind kind) => PinImage(kind, color: widget.color);
}

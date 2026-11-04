import 'package:flutter/material.dart';

/// Pozycja listy [SelectField].
class SelectOption {
  const SelectOption({
    required this.label,
    required this.leading,
    required this.onSelected,
    this.selected = false,
    this.key,
  });

  final String label;
  final Widget leading;
  final VoidCallback onSelected;

  /// Bieżąca wartość: podświetlona na liście.
  final bool selected;
  final Key? key;
}

/// Select box w ramce, z etykietą jak w polach tekstowych (v17).
///
/// Tap rozwija przewijaną listę pod polem. [controller] pozwala otworzyć ją
/// z kodu. Pole węższe od listy podaje [menuWidth] i [menuOffsetX], żeby lista
/// mogła zająć całą szerokość formularza.
class SelectField extends StatefulWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    this.leading,
    this.enabled = true,
    this.revealSelected = true,
    this.controller,
    this.menuWidth,
    this.menuOffsetX = 0,
  });

  static const _rowHeight = 48.0;

  /// 8 wierszy i marginesy listy: wszystkie kategorie bez przewijania, dłuższe
  /// listy się przewijają.
  static const menuMaxHeight = 8 * _rowHeight + 16;

  final String label;
  final String value;
  final Widget? leading;
  final List<SelectOption> options;
  final bool enabled;

  /// Po otwarciu przewija listę do bieżącej wartości.
  final bool revealSelected;
  final MenuController? controller;
  final double? menuWidth;
  final double menuOffsetX;

  @override
  State<SelectField> createState() => _SelectFieldState();
}

class _SelectFieldState extends State<SelectField> {
  final _ownController = MenuController();
  final _selectedKey = GlobalKey();

  MenuController get _controller => widget.controller ?? _ownController;

  void _showSelected() {
    if (!widget.revealSelected) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selected = _selectedKey.currentContext;
      if (selected == null || !selected.mounted) return;
      // Tylko lista: `Scrollable.ensureVisible` przewinęłoby też arkusz pod
      // nią, a przewinięcie przodka zamyka `MenuAnchor`.
      Scrollable.of(
        selected,
      ).position.ensureVisible(selected.findRenderObject()!, alignment: 0.5);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth = widget.menuWidth ?? constraints.maxWidth;
        return MenuAnchor(
          controller: _controller,
          consumeOutsideTap: true,
          onOpen: _showSelected,
          alignmentOffset: Offset(widget.menuOffsetX, 4),
          style: MenuStyle(
            minimumSize: WidgetStatePropertyAll(Size(menuWidth, 0)),
            maximumSize: WidgetStatePropertyAll(
              Size(menuWidth, SelectField.menuMaxHeight),
            ),
          ),
          menuChildren: [
            for (final option in widget.options)
              KeyedSubtree(
                key: option.selected ? _selectedKey : null,
                child: SizedBox(
                  // Lista bierze szerokość z wierszy, nie z `minimumSize`.
                  width: menuWidth,
                  child: MenuItemButton(
                    key: option.key,
                    style: MenuItemButton.styleFrom(
                      minimumSize: Size(0, SelectField._rowHeight),
                      backgroundColor: option.selected
                          ? colors.surfaceContainerHighest
                          : null,
                    ),
                    leadingIcon: option.leading,
                    onPressed: option.onSelected,
                    child: SizedBox(
                      // Bez tego długa nazwa wychodzi poza wiersz. Odjęte są
                      // marginesy `MenuItemButton` i pinezka.
                      width: menuWidth - 84,
                      child: Text(
                        option.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
          ],
          builder: (context, controller, _) => Semantics(
            button: true,
            enabled: widget.enabled,
            label: widget.label,
            value: widget.value,
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: widget.enabled
                  ? () => controller.isOpen
                        ? controller.close()
                        : controller.open()
                  : null,
              child: InputDecorator(
                isEmpty: false,
                decoration: InputDecoration(
                  labelText: widget.label,
                  isDense: true,
                  enabled: widget.enabled,
                  contentPadding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                ),
                child: Row(
                  children: [
                    if (widget.leading case final leading?) ...[
                      leading,
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        widget.value,
                        // Dwie linie mieszczą się w wysokości pinezki, więc
                        // w połowie szerokości nazwa nie musi być ucięta.
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: widget.enabled
                              ? colors.onSurface
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: widget.enabled
                          ? colors.onSurfaceVariant
                          : colors.outlineVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

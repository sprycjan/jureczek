import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/pin_color.dart';

extension PinColorLabel on PinColor {
  String label(AppLocalizations l10n) => switch (this) {
    PinColor.red => l10n.pinColorRed,
    PinColor.raspberry => l10n.pinColorRaspberry,
    PinColor.rose => l10n.pinColorRose,
    PinColor.coral => l10n.pinColorCoral,
    PinColor.orange => l10n.pinColorOrange,
    PinColor.amber => l10n.pinColorAmber,
    PinColor.gold => l10n.pinColorGold,
    PinColor.olive => l10n.pinColorOlive,
    PinColor.lime => l10n.pinColorLime,
    PinColor.green => l10n.pinColorGreen,
    PinColor.mint => l10n.pinColorMint,
    PinColor.teal => l10n.pinColorTeal,
    PinColor.cyan => l10n.pinColorCyan,
    PinColor.sky => l10n.pinColorSky,
    PinColor.blue => l10n.pinColorBlue,
    PinColor.navy => l10n.pinColorNavy,
    PinColor.violet => l10n.pinColorViolet,
    PinColor.purple => l10n.pinColorPurple,
    PinColor.orchid => l10n.pinColorOrchid,
    PinColor.brown => l10n.pinColorBrown,
    PinColor.sand => l10n.pinColorSand,
    PinColor.slate => l10n.pinColorSlate,
    PinColor.graphite => l10n.pinColorGraphite,
    PinColor.black => l10n.pinColorBlack,
  };
}

/// Wybór koloru pinezki (v17): jedna przewijana linia kółek ze strzałkami po
/// bokach. Bez wyboru pinezka ma kolor typu; „Domyślny” wraca do niego.
class PinColorPicker extends StatefulWidget {
  const PinColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final PinColor? value;
  final ValueChanged<PinColor?> onChanged;

  @override
  State<PinColorPicker> createState() => _PinColorPickerState();
}

class _PinColorPickerState extends State<PinColorPicker> {
  static const _swatchSize = 40.0;
  static const _scrollDuration = Duration(milliseconds: 250);

  final _scroll = ScrollController();
  bool _canScrollBack = false;
  bool _canScrollForward = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_syncArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      // Przy edycji zapisany kolor nie może być schowany poza paskiem.
      final target = _offsetShowing(widget.value);
      if (target != null) _scroll.jumpTo(target);
      _syncArrows();
    });
  }

  @override
  void didUpdateWidget(PinColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value || !_scroll.hasClients) return;
    final target = _offsetShowing(widget.value);
    if (target != null) {
      _scroll.animateTo(
        target,
        duration: _scrollDuration,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _syncArrows() {
    final position = _scroll.position;
    final back = position.pixels > position.minScrollExtent;
    final forward = position.pixels < position.maxScrollExtent;
    if (back != _canScrollBack || forward != _canScrollForward) {
      setState(() {
        _canScrollBack = back;
        _canScrollForward = forward;
      });
    }
  }

  /// Przesunięcie centrujące kolor; `null`, gdy jest już cały widoczny.
  double? _offsetShowing(PinColor? color) {
    if (color == null) return null;
    final position = _scroll.position;
    final start = color.index * _swatchSize;
    final visible =
        start >= position.pixels &&
        start + _swatchSize <= position.pixels + position.viewportDimension;
    if (visible) return null;
    return (start - (position.viewportDimension - _swatchSize) / 2).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  void _scrollBy(double direction) {
    final position = _scroll.position;
    _scroll.animateTo(
      (position.pixels + direction * position.viewportDimension).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
      duration: _scrollDuration,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final value = widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 32,
          child: Row(
            children: [
              Text(
                l10n.pinColorLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value?.label(l10n) ?? l10n.pinColorDefault,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                  ),
                ),
              ),
              if (value != null)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => widget.onChanged(null),
                  child: Text(l10n.pinColorReset),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _ScrollArrow(
                key: const ValueKey('pin-color-scroll-back'),
                icon: Icons.chevron_left,
                tooltip: l10n.pinColorScrollBack,
                onPressed: _canScrollBack ? () => _scrollBy(-1) : null,
              ),
              Expanded(
                child: NotificationListener<ScrollMetricsNotification>(
                  // Zmiana szerokości paska zmienia też to, co da się przewinąć.
                  onNotification: (_) {
                    _syncArrows();
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final color in PinColor.values)
                          SizedBox.square(
                            dimension: _swatchSize,
                            child: _Swatch(
                              color: color,
                              selected: color == value,
                              label: color.label(l10n),
                              onTap: () => widget.onChanged(color),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              _ScrollArrow(
                key: const ValueKey('pin-color-scroll-forward'),
                icon: Icons.chevron_right,
                tooltip: l10n.pinColorScrollForward,
                onPressed: _canScrollForward ? () => _scrollBy(1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Strzałka przewijania; na końcu paska wyszarzona, ale zostaje na miejscu.
class _ScrollArrow extends StatelessWidget {
  const _ScrollArrow({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final PinColor color;
  final bool selected;
  final String label;
  final VoidCallback onTap;

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
          key: ValueKey('pin-color-${color.key}'),
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? colors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.color,
                  shape: BoxShape.circle,
                  // Ciemne kolory (grafit, czarny) nie znikają na ciemnym tle.
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

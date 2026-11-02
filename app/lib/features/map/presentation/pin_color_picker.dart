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

/// Wybór koloru pinezki (v14): siatka 6×4 kółek. Bez wyboru pinezka ma kolor
/// typu; „Przywróć domyślny” wraca do niego.
class PinColorPicker extends StatelessWidget {
  const PinColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final PinColor? value;
  final ValueChanged<PinColor?> onChanged;

  static const _columns = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final value = this.value;
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
                  onPressed: () => onChanged(null),
                  child: Text(l10n.pinColorReset),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (var row = 0; row < PinColor.values.length ~/ _columns; row++)
                Row(
                  children: [
                    for (final color
                        in PinColor.values.skip(row * _columns).take(_columns))
                      Expanded(
                        child: _Swatch(
                          color: color,
                          selected: color == value,
                          label: color.label(l10n),
                          onTap: () => onChanged(color),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
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
            padding: const EdgeInsets.all(4),
            child: AspectRatio(
              aspectRatio: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(3),
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
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

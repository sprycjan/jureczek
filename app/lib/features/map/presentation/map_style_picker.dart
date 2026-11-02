import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'map_style.dart';

/// Lista stylów mapy rozwijana z przycisku „warstwy” (v13).
class MapStylePicker extends StatelessWidget {
  const MapStylePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final MapStyleOption selected;
  final ValueChanged<MapStyleOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surface,
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final style in MapStyleOption.values)
              _StyleRow(
                key: ValueKey('map-style-${style.name}'),
                style: style,
                selected: style == selected,
                onTap: () => onSelected(style),
              ),
          ],
        ),
      ),
    );
  }
}

class _StyleRow extends StatelessWidget {
  const _StyleRow({
    super.key,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final MapStyleOption style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = selected ? colors.primary : colors.onSurface;
    return InkWell(
      onTap: onTap,
      child: Semantics(
        selected: selected,
        button: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
          child: Row(
            spacing: 12,
            children: [
              Icon(style.icon, color: color),
              Text(
                style.label(AppLocalizations.of(context)),
                style: theme.textTheme.titleSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension MapStyleOptionLabels on MapStyleOption {
  IconData get icon => switch (this) {
    MapStyleOption.vanventure => Icons.dark_mode_outlined,
    MapStyleOption.outdoors => Icons.terrain_outlined,
    MapStyleOption.faded3d => Icons.view_in_ar_outlined,
  };

  String label(AppLocalizations l10n) => switch (this) {
    MapStyleOption.vanventure => l10n.mapStyleVanventure,
    MapStyleOption.outdoors => l10n.mapStyleOutdoors,
    MapStyleOption.faded3d => l10n.mapStyleFaded3d,
  };
}

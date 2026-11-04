import 'package:flutter/material.dart';

/// Pionowa kolumna narzędzi przy prawej krawędzi mapy.
class MapTools extends StatelessWidget {
  const MapTools({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: children,
    );
  }
}

/// Okrągły przycisk-narzędzie unoszący się nad mapą.
class MapToolButton extends StatelessWidget {
  const MapToolButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// Ikona w kolorze akcentu – narzędzie zmienia to, co widać na mapie (v18).
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      shape: const CircleBorder(),
      elevation: 3,
      color: colors.surface,
      child: IconButton(
        tooltip: tooltip,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Icon(
            icon,
            key: ValueKey(icon),
            color: active ? colors.primary : null,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

/// Przyciski przybliżania i oddalania mapy w jednej pionowej „pigułce”.
class MapZoomButtons extends StatelessWidget {
  const MapZoomButtons({
    super.key,
    required this.zoomInTooltip,
    required this.zoomOutTooltip,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final String zoomInTooltip;
  final String zoomOutTooltip;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      shape: const StadiumBorder(),
      elevation: 3,
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: zoomInTooltip,
            icon: const Icon(Icons.add),
            onPressed: onZoomIn,
          ),
          SizedBox(
            width: 24,
            child: Divider(height: 1, color: colors.outlineVariant),
          ),
          IconButton(
            tooltip: zoomOutTooltip,
            icon: const Icon(Icons.remove),
            onPressed: onZoomOut,
          ),
        ],
      ),
    );
  }
}

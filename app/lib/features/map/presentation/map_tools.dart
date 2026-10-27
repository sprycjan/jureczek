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
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

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
          child: Icon(icon, key: ValueKey(icon)),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

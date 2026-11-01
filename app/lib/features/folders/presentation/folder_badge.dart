import 'package:flutter/material.dart';

import '../domain/trip_folder.dart';

/// Kafelek z ikoną folderu w jego kolorze akcentu.
class FolderBadge extends StatelessWidget {
  const FolderBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
  });

  final FolderIcon icon;
  final FolderColor color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.color,
        borderRadius: BorderRadius.circular(size / 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon.icon, size: size / 2, color: color.onColor),
    );
  }
}

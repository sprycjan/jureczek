import 'package:flutter/material.dart';

/// Ikona folderu (ekran „Nowy folder”). [key] trafia do bazy.
enum FolderIcon {
  camper('camper', Icons.rv_hookup),
  mountains('mountains', Icons.terrain),
  beach('beach', Icons.beach_access),
  camping('camping', Icons.festival),
  hiking('hiking', Icons.hiking),
  cafe('cafe', Icons.local_cafe),
  compass('compass', Icons.explore),
  forest('forest', Icons.forest),
  city('city', Icons.location_city),
  castle('castle', Icons.castle),
  food('food', Icons.restaurant),
  wine('wine', Icons.wine_bar),
  bike('bike', Icons.directions_bike),
  kayak('kayak', Icons.kayaking),
  ski('ski', Icons.downhill_skiing);

  const FolderIcon(this.key, this.icon);

  final String key;
  final IconData icon;

  static FolderIcon fromKey(String? key) =>
      values.where((v) => v.key == key).firstOrNull ?? FolderIcon.camper;
}

/// Kolor akcentu folderu. [key] trafia do bazy.
enum FolderColor {
  emerald('emerald', Color(0xFF85D7A9), Color(0xFF003821)),
  amber('amber', Color(0xFFFFB876), Color(0xFF4B2800)),
  glacier('glacier', Color(0xFF9ECEDF), Color(0xFF003542)),
  heather('heather', Color(0xFFCE93D8), Color(0xFF2A003D)),
  raspberry('raspberry', Color(0xFFF48FB1), Color(0xFF380017)),
  sapphire('sapphire', Color(0xFF90CAF9), Color(0xFF001E3D)),
  meadow('meadow', Color(0xFF81C784), Color(0xFF052E0B)),
  lagoon('lagoon', Color(0xFF4DD0E1), Color(0xFF00282C)),
  slate('slate', Color(0xFFB0BEC5), Color(0xFF1A2328));

  const FolderColor(this.key, this.color, this.onColor);

  final String key;
  final Color color;

  /// Kolor ikony na tle [color].
  final Color onColor;

  static FolderColor fromKey(String? key) =>
      values.where((v) => v.key == key).firstOrNull ?? FolderColor.emerald;
}

/// Folder pinezek: jedna podróż albo wspólny mianownik („Portugalia”, „Ciekawe miejsca”).
@immutable
class TripFolder {
  const TripFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.icon = FolderIcon.camper,
    this.color = FolderColor.emerald,
    this.pinCount = 0,
    this.archivedAt,
  });

  final String id;
  final String name;

  /// `null` oznacza brak (nigdy pusty tekst).
  final String? description;
  final FolderIcon icon;
  final FolderColor color;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Liczba pinezek w folderze (tylko do odczytu, z zapytania listy).
  final int pinCount;

  /// Chwila archiwizacji (v23); `null` to folder bieżący.
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  static const maxNameLength = 45;
  static const maxDescriptionLength = 120;

  /// Nazwa folderu tworzonego automatycznie, gdy pinezka nie ma wybranego innego.
  static const defaultName = 'Pinezki';
}

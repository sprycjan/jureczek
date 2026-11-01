import 'package:drift/drift.dart';

/// Foldery pinezek (v10, schemat 5): podróż albo wspólny mianownik miejsc.
@DataClassName('FolderRow')
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();

  /// Klucze [FolderIcon] i [FolderColor].
  TextColumn get icon => text()();
  TextColumn get color => text()();

  DateTimeColumn get createdAt => dateTime()();

  /// Ostatnia zmiana folderu lub jego pinezek – kolejność na ekranie startowym.
  /// Milisekundy epoki, bo `dateTime()` w drifcie ma dokładność do sekundy
  /// i szybkie zmiany dawałyby remis.
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

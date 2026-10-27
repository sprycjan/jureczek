import 'package:drift/drift.dart';

/// Tabela pinezek. Wiersz to `PinRow`, żeby nie mylić go z `PlacePin`.
@DataClassName('PinRow')
class Pins extends Table {
  TextColumn get id => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  DateTimeColumn get createdAt => dateTime()();

  /// Dodane w schemacie 2 (v3); puste dla starszych pinezek.
  TextColumn get name => text().nullable()();
  TextColumn get note => text().nullable()();

  /// Dodane w schemacie 3 (v5): adres i link, z którego udostępniono miejsce.
  TextColumn get address => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

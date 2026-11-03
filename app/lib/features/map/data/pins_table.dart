import 'package:drift/drift.dart';

/// Tabela pinezek. Wiersz to `PinRow`, żeby nie mylić go z `PlacePin`.
@DataClassName('PinRow')
class Pins extends Table {
  TextColumn get id => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  DateTimeColumn get createdAt => dateTime()();

  /// Nazwa i notatka (od v3).
  TextColumn get name => text().nullable()();
  TextColumn get note => text().nullable()();

  /// Adres i link, z którego udostępniono miejsce (od v5).
  TextColumn get address => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();

  /// Dodane w schemacie 4 (v9). Od schematu 7 (v16) klucz `PinKind`:
  /// `standard` albo klucz `PlaceType` (np. `cafe`, `gastronomy_other`).
  TextColumn get category => text().withDefault(const Constant('standard'))();

  /// Dodane w schemacie 5 (v10): folder, do którego należy pinezka (obowiązkowy).
  TextColumn get folderId => text()();

  /// Dodane w schemacie 6 (v14): klucz [PinColor]; `null` – kolor kategorii.
  TextColumn get color => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

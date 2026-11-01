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

  /// Dodane w schemacie 4 (v9): klucz [PinCategory].
  TextColumn get category => text().withDefault(const Constant('standard'))();

  @override
  Set<Column> get primaryKey => {id};
}

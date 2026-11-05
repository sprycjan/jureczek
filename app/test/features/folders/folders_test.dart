import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/core/database/app_database.dart';
import 'package:jureczek/features/folders/application/folders_providers.dart';
import 'package:jureczek/features/folders/domain/trip_folder.dart';
import 'package:jureczek/features/map/application/pins_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    final db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    container.listen(foldersProvider, (_, _) {});
    addTearDown(db.close);
  });
  tearDown(() => container.dispose());

  FoldersController folders() => container.read(foldersControllerProvider);
  PinsController pins() => container.read(pinsControllerProvider);

  Future<List<TripFolder>> list() async {
    await pumpEventQueue();
    return container.read(foldersProvider).requireValue;
  }

  /// Zmiany `updatedAt` w tej samej milisekundzie dałyby remis w kolejności.
  Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 5));

  test('create zapisuje pola; nazwa obcięta, pusty opis to null', () async {
    final id = await folders().create(
      name: ' Portugalia ',
      description: '  ',
      icon: FolderIcon.beach,
      color: FolderColor.glacier,
    );

    final folder = (await list()).single;
    expect(folder.id, id);
    expect(folder.name, 'Portugalia');
    expect(folder.description, isNull);
    expect(folder.icon, FolderIcon.beach);
    expect(folder.color, FolderColor.glacier);
    expect(folder.pinCount, 0);
  });

  test('create z pustą nazwą rzuca błąd', () async {
    expect(() => folders().create(name: '  '), throwsArgumentError);
  });

  test('lista od ostatnio zmienionego; edycja podnosi folder', () async {
    await folders().create(name: 'A');
    await tick();
    await folders().create(name: 'B');
    expect((await list()).map((f) => f.name), ['B', 'A']);

    await tick();
    final a = (await list()).last;
    await folders().update(
      a,
      name: 'A2',
      description: 'opis',
      icon: FolderIcon.hiking,
      color: FolderColor.amber,
    );

    final updated = await list();
    expect(updated.map((f) => f.name), ['A2', 'B']);
    expect(updated.first.description, 'opis');
    expect(updated.first.createdAt, a.createdAt);
  });

  test(
    'dodanie i przeniesienie pinezki podnosi foldery i liczy pinezki',
    () async {
      final a = await folders().create(name: 'A');
      await tick();
      final b = await folders().create(name: 'B');
      await tick();

      final pin = await pins().add(folderId: a, lat: 50, lng: 19);
      var current = await list();
      expect(current.map((f) => f.name), ['A', 'B']);
      expect(current.first.pinCount, 1);

      await tick();
      await pins().updateDetails(pin, folderId: b);
      current = await list();
      expect(current.first.name, 'B');
      expect({for (final f in current) f.name: f.pinCount}, {'A': 0, 'B': 1});
    },
  );

  test('ensureDefault tworzy „Pinezki” raz i potem go zwraca', () async {
    final first = await folders().ensureDefault();
    final second = await folders().ensureDefault();

    expect(second, first);
    final all = await list();
    expect(all.single.name, TripFolder.defaultName);
  });

  group('archiwum (v23)', () {
    Future<TripFolder> folder(String id) async =>
        (await list()).firstWhere((f) => f.id == id);

    Future<List<String>> activeNames() async {
      await list();
      return [
        for (final f in container.read(activeFoldersProvider).requireValue)
          f.name,
      ];
    }

    test('archiwizacja ustawia datę i nie zmienia miejsca na liście', () async {
      final a = await folders().create(name: 'A');
      await tick();
      await folders().create(name: 'B');
      final before = await folder(a);

      await folders().archive(before);

      final after = await folder(a);
      expect(after.isArchived, isTrue);
      expect(after.updatedAt, before.updatedAt);
      expect(await activeNames(), ['B']);
    });

    test(
      'przywrócenie idzie na górę, „Cofnij” wraca na dawne miejsce',
      () async {
        final a = await folders().create(name: 'A');
        await tick();
        await folders().create(name: 'B');
        final original = await folder(a);
        await folders().archive(original);
        await tick();

        final archived = await folder(a);
        await folders().restore(archived);
        expect((await folder(a)).isArchived, isFalse);
        expect(await activeNames(), ['A', 'B']);

        await folders().undoArchiveChange(archived);
        expect((await folder(a)).archivedAt, archived.archivedAt);
        expect((await folder(a)).updatedAt, original.updatedAt);

        await folders().undoArchiveChange(original);
        expect(await activeNames(), ['B', 'A']);
      },
    );

    test('edycja nie zdejmuje archiwum', () async {
      final a = await folders().create(name: 'A');
      await folders().archive(await folder(a));

      await folders().update(
        await folder(a),
        name: 'A2',
        icon: FolderIcon.ski,
        color: FolderColor.slate,
      );

      expect((await folder(a)).isArchived, isTrue);
    });

    test('ensureDefault pomija „Pinezki” z archiwum i tworzy nowy', () async {
      final old = await folders().ensureDefault();
      await folders().archive(await folder(old));

      final fresh = await folders().ensureDefault();

      expect(fresh, isNot(old));
      expect(await folders().ensureDefault(), fresh);
      expect(await activeNames(), [TripFolder.defaultName]);
    });
  });

  test('klucze ikon i kolorów: unikalne, nieznany → domyślny', () {
    expect(FolderIcon.values.map((v) => v.key).toSet(), hasLength(15));
    expect(FolderColor.values.map((v) => v.key).toSet(), hasLength(9));
    expect(FolderIcon.fromKey('ski'), FolderIcon.ski);
    expect(FolderColor.fromKey('slate'), FolderColor.slate);
    expect(FolderIcon.fromKey('nope'), FolderIcon.camper);
    expect(FolderColor.fromKey(null), FolderColor.emerald);
  });
}

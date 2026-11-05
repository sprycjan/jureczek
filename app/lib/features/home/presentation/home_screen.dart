import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../folders/application/folders_providers.dart';
import '../../folders/domain/trip_folder.dart';
import '../../folders/presentation/folder_badge.dart';
import '../../folders/presentation/folder_form_screen.dart';
import '../../map/presentation/map_screen.dart';
import '../../share/application/shared_place_controller.dart';
import '../domain/landscape.dart';

/// Ekran startowy (v10): pejzaż wg pory dnia, foldery pinezek, wejście na mapę.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.accessToken});

  final String accessToken;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Landscape _landscape = Landscape.at(DateTime.now());
  Timer? _clock;

  /// Zakładka archiwum (v23). Aplikacja zawsze startuje na bieżących podróżach.
  bool _showArchive = false;

  /// Zmiany archiwum w drodze do bazy: id folderu → stan docelowy. Karta musi
  /// zniknąć z listy od razu po geście, bo `Dismissible` nie może zostać w drzewie,
  /// a strumień z bazy dociera później. Wpis znika, gdy baza potwierdzi stan.
  final _pendingMoves = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = Landscape.at(DateTime.now());
      if (now != _landscape) setState(() => _landscape = now);
    });
    // Udostępnienie z innej aplikacji: zawsze mapa wszystkich pinezek (v10),
    // ona sama pokazuje wynik i formularz z wyborem folderu.
    ref.listenManual(sharedPlaceControllerProvider, (previous, next) {
      final started =
          next is SharedPlaceLoading ||
          (previous == null && next is! SharedPlaceIdle);
      if (!started) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        _openMap(null);
      });
    }, fireImmediately: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final landscape in Landscape.values) {
      precacheImage(AssetImage(landscape.asset), context);
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _openMap(String? folderId, {bool readOnly = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // Własny ScaffoldMessenger: snackbary mapy („Dodano pinezkę”, „Cofnij”)
        // znikają razem z nią, a nie zostają na ekranie startowym.
        builder: (_) => ScaffoldMessenger(
          child: MapScreen(
            accessToken: widget.accessToken,
            folderId: folderId,
            readOnly: readOnly,
          ),
        ),
      ),
    );
  }

  /// Archiwizuje albo przywraca folder (gest i menu) i proponuje „Cofnij”.
  Future<void> _moveFolder(TripFolder folder, {required bool archive}) async {
    final controller = ref.read(foldersControllerProvider);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final saved = await _writeMove(
      folder.id,
      archive,
      () => archive ? controller.archive(folder) : controller.restore(folder),
    );
    if (!saved) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(archive ? l10n.folderArchived : l10n.folderRestored),
          duration: const Duration(seconds: 4),
          persist: false,
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => _writeMove(
              folder.id,
              !archive,
              () => controller.undoArchiveChange(folder),
            ),
          ),
        ),
      );
  }

  /// Przekłada kartę od razu; po nieudanym zapisie wraca ona na miejsce.
  Future<bool> _writeMove(
    String id,
    bool archive,
    Future<void> Function() write,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _pendingMoves[id] = archive);
    try {
      await write();
      return true;
    } catch (e) {
      debugPrint('Zmiana archiwum folderu nie powiodła się: $e');
      // Karta musi choć klatkę zniknąć z drzewa, żeby wróciła z nowym stanem –
      // przesunięty `Dismissible` nie może w nim pozostać.
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) setState(() => _pendingMoves.remove(id));
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.folderSaveError)));
      return false;
    }
  }

  void _confirmMoves(List<TripFolder> folders) {
    final confirmed = [
      for (final folder in folders)
        if (_pendingMoves[folder.id] == folder.isArchived) folder.id,
    ];
    if (confirmed.isEmpty) return;
    setState(
      () => _pendingMoves.removeWhere((id, _) => confirmed.contains(id)),
    );
  }

  /// Foldery zakładki: bieżące od ostatnio zmienionego, archiwum od ostatnio
  /// zarchiwizowanego, z kartami w drodze do bazy już na docelowej liście.
  List<TripFolder> _tabFolders(List<TripFolder> all) {
    final folders = [
      for (final folder in all)
        if ((_pendingMoves[folder.id] ?? folder.isArchived) == _showArchive)
          folder,
    ];
    if (_showArchive) {
      int archivedAt(TripFolder f) =>
          f.archivedAt?.millisecondsSinceEpoch ?? (1 << 62);
      folders.sort((a, b) => archivedAt(b).compareTo(archivedAt(a)));
    }
    return folders;
  }

  Future<void> _openForm({TripFolder? folder}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute<FolderFormResult>(
        fullscreenDialog: true,
        builder: (_) => FolderFormScreen(folder: folder),
      ),
    );
    if (result != null && result.openMap && mounted) _openMap(result.folderId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    ref.listen(foldersProvider, (_, next) {
      if (next.value case final all?) _confirmMoves(all);
    });
    final folders = ref.watch(foldersProvider);
    final all = folders.value;
    final list = all == null ? null : _tabFolders(all);

    return PopScope(
      // Wstecz z archiwum wraca do bieżących podróży, a stamtąd zamyka aplikację.
      canPop: !_showArchive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _showArchive = false);
      },
      child: Scaffold(
        bottomNavigationBar: NavigationBar(
          selectedIndex: _showArchive ? 1 : 0,
          onDestinationSelected: (index) =>
              setState(() => _showArchive = index == 1),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore),
              label: l10n.homeTabTrips,
            ),
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2),
              label: l10n.homeTabArchive,
            ),
          ],
        ),
        body: CustomScrollView(
          // Każda zakładka pamięta własne przewinięcie.
          key: PageStorageKey(_showArchive ? 'home-archive' : 'home-trips'),
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                landscape: _landscape,
                grayscale: _showArchive,
                greeting: Text(
                  l10n.homeGreeting,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              sliver: SliverList.list(
                children: [
                  if (!_showArchive) ...[
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _openMap(null),
                            icon: const Icon(Icons.map_outlined),
                            label: Text(l10n.homeAllPins),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          tooltip: l10n.folderNew,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _openForm,
                          icon: const Icon(Icons.create_new_folder_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    children: [
                      Icon(
                        _showArchive
                            ? Icons.inventory_2_outlined
                            : Icons.bookmark_border,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showArchive
                            ? l10n.archiveTitle
                            : l10n.homeFoldersTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (folders.hasError && list == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.pinsLoadError,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              )
            else if (list == null)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (list.isEmpty && _showArchive)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.archiveEmpty,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else if (list.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyFolders(
                  // Foldery są, tylko wszystkie w archiwum.
                  hasArchived: all!.isNotEmpty,
                  onCreate: _openForm,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final folder = list[i];
                    return _FolderCard(
                      key: ValueKey(folder.id),
                      folder: folder,
                      archived: _showArchive,
                      onOpen: () => _openMap(folder.id, readOnly: _showArchive),
                      onEdit: () => _openForm(folder: folder),
                      onMove: () => _moveFolder(folder, archive: !_showArchive),
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}

/// Odcień szarości (luminancja Rec. 709) dla pejzażu w archiwum.
const _grayscale = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// Pejzaż z płynnym przejściem między porami dnia, długo wtapiający się w tło
/// (jak makieta Stitcha); powitanie leży na jego dolnej części.
class _Header extends StatelessWidget {
  const _Header({
    required this.landscape,
    required this.greeting,
    this.grayscale = false,
  });

  final Landscape landscape;
  final Widget greeting;

  /// Wyszarzony pejzaż odróżnia archiwum od bieżących podróży (v23).
  final bool grayscale;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final image = AnimatedSwitcher(
      duration: const Duration(milliseconds: 1200),
      // Domyślny układ nie rozciąga dzieci – obrazek miał swój naturalny
      // rozmiar na środku nagłówka i twardą dolną krawędź (v11).
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: Image.asset(
        landscape.asset,
        key: ValueKey(landscape),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        excludeFromSemantics: true,
      ),
    );
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (grayscale)
            ColorFiltered(colorFilter: _grayscale, child: image)
          else
            image,
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.35, 0.6, 0.8, 0.92, 1],
                colors: [
                  for (final alpha in const [0.0, 0.08, 0.35, 0.7, 0.92, 1.0])
                    surface.withValues(alpha: alpha),
                ],
              ),
            ),
          ),
          Positioned(left: 16, right: 16, bottom: 0, child: greeting),
        ],
      ),
    );
  }
}

class _EmptyFolders extends StatelessWidget {
  const _EmptyFolders({required this.onCreate, this.hasArchived = false});

  final VoidCallback onCreate;

  /// Wszystkie foldery są w archiwum, więc to nie pierwszy folder (v23).
  final bool hasArchived;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_location_alt,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              hasArchived ? l10n.homeNoCurrentTitle : l10n.homeEmptyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeEmptyMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: Text(hasArchived ? l10n.folderNew : l10n.homeEmptyAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    super.key,
    required this.folder,
    required this.archived,
    required this.onOpen,
    required this.onEdit,
    required this.onMove,
  });

  final TripFolder folder;

  /// Karta w archiwum: w menu tylko „Przywróć”, bez edycji (v23).
  final bool archived;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  /// Archiwizuje albo przywraca – przesunięcie w dowolną stronę lub menu.
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final moveIcon = archived
        ? Icons.unarchive_outlined
        : Icons.archive_outlined;
    final moveLabel = archived ? l10n.folderRestore : l10n.folderArchive;
    return Dismissible(
      key: ValueKey('dismiss-${folder.id}'),
      onDismissed: (_) => onMove(),
      background: _SwipeBackground(
        icon: moveIcon,
        label: moveLabel,
        alignment: MainAxisAlignment.start,
      ),
      secondaryBackground: _SwipeBackground(
        icon: moveIcon,
        label: moveLabel,
        alignment: MainAxisAlignment.end,
      ),
      child: _buildCard(context, l10n, theme, moveIcon, moveLabel),
    );
  }

  Widget _buildCard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    IconData moveIcon,
    String moveLabel,
  ) {
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FolderBadge(icon: folder.icon, color: folder.color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (folder.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        folder.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      l10n.folderPinCount(folder.pinCount),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: folder.color.color,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<void>(
                tooltip: l10n.folderMenu,
                icon: const Icon(Icons.more_vert),
                itemBuilder: (_) => [
                  if (!archived)
                    PopupMenuItem<void>(
                      onTap: onEdit,
                      child: ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(l10n.folderEdit),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  PopupMenuItem<void>(
                    onTap: onMove,
                    child: ListTile(
                      leading: Icon(moveIcon),
                      title: Text(moveLabel),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tło pod przesuwaną kartą: co się stanie po puszczeniu.
class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final IconData icon;
  final String label;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: alignment,
        spacing: 8,
        children: [
          Icon(icon, color: colors.onPrimaryContainer),
          Text(label, style: TextStyle(color: colors.onPrimaryContainer)),
        ],
      ),
    );
  }
}

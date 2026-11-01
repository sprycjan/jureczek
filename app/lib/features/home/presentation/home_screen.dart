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

  void _openMap(String? folderId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MapScreen(accessToken: widget.accessToken, folderId: folderId),
      ),
    );
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
    final folders = ref.watch(foldersProvider);
    final list = folders.value;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(landscape: _landscape)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverList.list(
              children: [
                Text(l10n.homeGreeting, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  l10n.homeSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
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
                Row(
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.homeFoldersTitle,
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
          else if (list.isEmpty)
            SliverToBoxAdapter(child: _EmptyFolders(onCreate: _openForm))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _FolderCard(
                  folder: list[i],
                  onOpen: () => _openMap(list[i].id),
                  onEdit: () => _openForm(folder: list[i]),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
          ),
        ],
      ),
    );
  }
}

/// Pejzaż z płynnym przejściem między porami dnia, wtapiający się w tło.
class _Header extends StatelessWidget {
  const _Header({required this.landscape});

  final Landscape landscape;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return SizedBox(
      height: 288,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1200),
            child: Image.asset(
              landscape.asset,
              key: ValueKey(landscape),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              excludeFromSemantics: true,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.55, 1],
                colors: [
                  surface.withValues(alpha: 0),
                  surface.withValues(alpha: 0.15),
                  surface,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFolders extends StatelessWidget {
  const _EmptyFolders({required this.onCreate});

  final VoidCallback onCreate;

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
              l10n.homeEmptyTitle,
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
              label: Text(l10n.homeEmptyAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.onOpen,
    required this.onEdit,
  });

  final TripFolder folder;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
                  PopupMenuItem<void>(
                    onTap: onEdit,
                    child: ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(l10n.folderEdit),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/folders_providers.dart';
import '../domain/trip_folder.dart';
import 'folder_badge.dart';
import 'folder_labels.dart';

/// Wynik ekranu folderu: id zapisanego folderu i czy od razu otworzyć go na mapie.
typedef FolderFormResult = ({String folderId, bool openMap});

/// Tworzenie i edycja folderu (v10, makieta `resorces/nowa_lista.png`).
class FolderFormScreen extends ConsumerStatefulWidget {
  const FolderFormScreen({super.key, this.folder});

  /// `null` – nowy folder.
  final TripFolder? folder;

  @override
  ConsumerState<FolderFormScreen> createState() => _FolderFormScreenState();
}

class _FolderFormScreenState extends ConsumerState<FolderFormScreen> {
  late final _name = TextEditingController(text: widget.folder?.name);
  late final _description = TextEditingController(
    text: widget.folder?.description,
  );
  late var _icon = widget.folder?.icon ?? FolderIcon.camper;
  late var _color = widget.folder?.color ?? FolderColor.emerald;
  bool _nameMissing = false;
  bool _saving = false;
  bool _saveFailed = false;

  bool get _creating => widget.folder == null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save({bool openMap = false}) async {
    if (_name.text.trim().isEmpty) {
      setState(() => _nameMissing = true);
      return;
    }
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    final controller = ref.read(foldersControllerProvider);
    try {
      final folder = widget.folder;
      final String id;
      if (folder == null) {
        id = await controller.create(
          name: _name.text,
          description: _description.text,
          icon: _icon,
          color: _color,
        );
      } else {
        await controller.update(
          folder,
          name: _name.text,
          description: _description.text,
          icon: _icon,
          color: _color,
        );
        id = folder.id;
      }
      if (mounted) {
        Navigator.of(
          context,
        ).pop<FolderFormResult>((folderId: id, openMap: openMap));
      }
    } catch (e) {
      debugPrint('Zapis folderu nie powiódł się: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _saveFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Widget label(IconData icon, Color color, String text, {Widget? trailing}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        leading: IconButton(
          tooltip: l10n.folderClose,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _creating ? l10n.folderNew : l10n.folderEditTitle,
          style: theme.textTheme.titleMedium,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Preview(
            name: _name,
            description: _description,
            icon: _icon,
            color: _color,
          ),
          const SizedBox(height: 24),
          label(Icons.edit_note, colors.primary, '${l10n.folderNameLabel} *'),
          TextField(
            controller: _name,
            maxLength: TripFolder.maxNameLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _nameMissing = false),
            decoration: InputDecoration(
              hintText: l10n.folderNameHint,
              errorText: _nameMissing ? l10n.folderNameRequired : null,
            ),
          ),
          const SizedBox(height: 8),
          label(Icons.notes, colors.tertiary, l10n.folderDescriptionLabel),
          TextField(
            controller: _description,
            maxLength: TripFolder.maxDescriptionLength,
            minLines: 2,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: l10n.folderDescriptionHint),
          ),
          const SizedBox(height: 8),
          label(
            Icons.category,
            colors.primary,
            l10n.folderIconLabel,
            trailing: Text(
              l10n.folderIconHint,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              height: 50,
              child: ListView(
                key: const ValueKey('folder-icons'),
                scrollDirection: Axis.horizontal,
                children: [
                  for (final icon in FolderIcon.values)
                    Padding(
                      padding: const EdgeInsets.all(3),
                      child: Tooltip(
                        message: icon.label(l10n),
                        child: Material(
                          color: icon == _icon
                              ? colors.surfaceContainerHigh
                              : colors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            key: ValueKey('folder-icon-${icon.key}'),
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _icon = icon),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(
                                icon.icon,
                                size: 20,
                                semanticLabel: icon.label(l10n),
                                color: icon == _icon
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          label(Icons.palette, colors.secondary, l10n.folderColorLabel),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                key: const ValueKey('folder-colors'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: FolderColor.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 20),
                itemBuilder: (context, i) {
                  final color = FolderColor.values[i];
                  final selected = color == _color;
                  return Center(
                    child: Semantics(
                      button: true,
                      selected: selected,
                      label: color.label(l10n),
                      child: GestureDetector(
                        key: ValueKey('folder-color-${color.key}'),
                        onTap: () => setState(() => _color = color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.color,
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(
                                    color: colors.surfaceContainerLow,
                                    width: 2,
                                  )
                                : null,
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: color.color.withValues(alpha: 0.5),
                                      spreadRadius: 3,
                                    ),
                                  ]
                                : null,
                          ),
                          child: selected
                              ? Icon(
                                  Icons.check,
                                  size: 16,
                                  color: color.onColor,
                                )
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_saveFailed) ...[
            const SizedBox(height: 16),
            Text(l10n.folderSaveError, style: TextStyle(color: colors.error)),
          ],
          if (_creating) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(64, 56)),
              onPressed: _saving ? null : () => _save(openMap: true),
              icon: const Icon(Icons.add_location_alt),
              label: Text(l10n.folderCreateAndAddPins),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: colors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.pinCancel),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('folder-save'),
                  onPressed: _saving ? null : _save,
                  icon: Icon(
                    _creating ? Icons.add_circle_outline : Icons.check,
                    size: 18,
                  ),
                  label: Text(_creating ? l10n.folderCreate : l10n.pinSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Podgląd folderu na żywo: kafelek ikony, nazwa i opis (jak karta na liście).
class _Preview extends StatelessWidget {
  const _Preview({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  final TextEditingController name;
  final TextEditingController description;
  final FolderIcon icon;
  final FolderColor color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = name.text.trim().isEmpty
        ? l10n.folderPreviewName
        : name.text.trim();
    final subtitle = description.text.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          FolderBadge(icon: icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

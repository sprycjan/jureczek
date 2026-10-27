import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../application/place_search_controller.dart';
import '../domain/place_suggestion.dart';

/// Pole wyszukiwania z listą podpowiedzi pod spodem.
/// Lista jest widoczna tylko, gdy pole ma fokus – tap w mapę chowa ją razem z klawiaturą.
class PlaceSearchField extends StatefulWidget {
  const PlaceSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.state,
    required this.onChanged,
    required this.onSelected,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final PlaceSearchState state;
  final ValueChanged<String> onChanged;
  final ValueChanged<PlaceSuggestion> onSelected;

  @override
  State<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<PlaceSearchField> {
  /// Margines nad polem, samo pole, odstęp do listy i margines nad klawiaturą.
  static const _spaceAboveList = 16 + 56 + 8 + 16;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(PlaceSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: widget.onChanged,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
              if (widget.state is PlaceSearchLoading)
                const LinearProgressIndicator(minHeight: 2),
            ],
          ),
        ),
        if (widget.focusNode.hasFocus) _results(context, l10n),
      ],
    );
  }

  Widget _results(BuildContext context, AppLocalizations l10n) {
    final Widget content;
    switch (widget.state) {
      case PlaceSearchIdle():
        return const SizedBox.shrink();
      case PlaceSearchLoading(previous: []):
        return const SizedBox.shrink();
      case PlaceSearchLoading(:final previous):
        content = _suggestionList(previous);
      case PlaceSearchSuggestions(:final suggestions):
        content = _suggestionList(suggestions);
      case PlaceSearchEmpty():
        content = _message(context, l10n.searchNoResults);
      case PlaceSearchError():
        content = _message(context, l10n.searchError);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }

  Widget _suggestionList(List<PlaceSuggestion> suggestions) {
    // Lista kończy się nad klawiaturą; gdy brakuje miejsca, przewija się.
    final media = MediaQuery.of(context);
    final maxHeight =
        media.size.height -
        media.viewInsets.bottom -
        media.padding.top -
        _spaceAboveList;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight.clamp(0, double.infinity),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          for (final suggestion in suggestions)
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(
                suggestion.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: suggestion.address == null
                  ? null
                  : Text(
                      suggestion.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              onTap: () => widget.onSelected(suggestion),
            ),
        ],
      ),
    );
  }

  Widget _message(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

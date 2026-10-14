import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localization.dart';

/// Search Bar Widget for Community Page
/// Allows filtering events by title, description, and masjid name
class EventSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final String hintText;

  const EventSearchBar({
    super.key,
    required this.onSearchChanged,
    this.hintText = 'Search events...',
  });

  @override
  State<EventSearchBar> createState() => _EventSearchBarState();
}

class _EventSearchBarState extends State<EventSearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      widget.onSearchChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: ColorPalette.secondary,
            size: 20,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  tooltip: appLocalization.t('clear'),
                  onPressed: () {
                    _controller.clear();
                  },
                  icon: Icon(
                    Icons.close,
                    color: ColorPalette.secondary,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {}); // Trigger rebuild to show/hide clear button
        },
      ),
    );
  }
}

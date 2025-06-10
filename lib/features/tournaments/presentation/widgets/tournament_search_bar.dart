import 'package:flutter/material.dart';
import '../../../../core/config/theme.dart';

class TournamentSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final String hintText;

  const TournamentSearchBar({
    Key? key,
    required this.controller,
    required this.onSearch,
    this.hintText = 'Search tournaments...',
  }) : super(key: key);

  @override
  State<TournamentSearchBar> createState() => _TournamentSearchBarState();
}

class _TournamentSearchBarState extends State<TournamentSearchBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: widget.controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  onPressed: () {
                    widget.controller.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onSubmitted: widget.onSearch,
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/genre_chip.dart';

class FilterChipItem {
  const FilterChipItem({
    required this.id,
    required this.label,
    this.selected = false,
  });

  final String id;
  final String label;
  final bool selected;
}

class FilterChipBar extends StatelessWidget {
  const FilterChipBar({
    super.key,
    required this.items,
    required this.onToggle,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  });

  final List<FilterChipItem> items;
  final ValueChanged<String> onToggle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Filter options',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              GenreChip(
                label: items[i].label,
                selected: items[i].selected,
                onTap: () => onToggle(items[i].id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// A reusable chip selection widget
class SelectableChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : isDark
                ? Colors.white24
                : Colors.black12,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// A group of selectable chips
class ChipGroup extends StatelessWidget {
  final List<String> items;
  final List<String> selectedItems;
  final void Function(String) onItemToggle;
  final bool multiSelect;

  const ChipGroup({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.onItemToggle,
    this.multiSelect = true,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return SelectableChip(
          label: item,
          isSelected: selectedItems.contains(item),
          onTap: () => onItemToggle(item),
        );
      }).toList(),
    );
  }
}

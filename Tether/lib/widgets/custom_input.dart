import 'package:flutter/material.dart';

class TetherTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final Widget? prefix;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;

  const TetherTextField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.onChanged,
    this.validator,
    this.prefix,
    this.suffix,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<TetherTextField> createState() => _TetherTextFieldState();
}

class _TetherTextFieldState extends State<TetherTextField> {
  late TextEditingController _controller;
  bool _isFocused = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _validate(String value) {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = _errorText != null
        ? (isDark ? Colors.white : Colors.black)
        : _isFocused
        ? (isDark ? Colors.white : Colors.black)
        : (isDark
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
        ],
        Focus(
          onFocusChange: (hasFocus) {
            setState(() => _isFocused = hasFocus);
            if (!hasFocus) {
              _validate(_controller.text);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (widget.prefix != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: widget.prefix,
                  ),
                ],
                Expanded(
                  child: TextField(
                    controller: _controller,
                    obscureText: widget.obscureText,
                    keyboardType: widget.keyboardType,
                    maxLines: widget.maxLines,
                    readOnly: widget.readOnly,
                    onTap: widget.onTap,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.4),
                          ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      widget.onChanged?.call(value);
                      if (_errorText != null) {
                        _validate(value);
                      }
                    },
                  ),
                ),
                if (widget.suffix != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: widget.suffix,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            _errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ],
    );
  }
}

class TetherDropdown<T> extends StatefulWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<TetherDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const TetherDropdown({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
  });

  @override
  State<TetherDropdown<T>> createState() => _TetherDropdownState<T>();
}

class TetherDropdownItem<T> {
  final T value;
  final String label;

  const TetherDropdownItem({required this.value, required this.label});
}

class _TetherDropdownState<T> extends State<TetherDropdown<T>> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = _isOpen
        ? (isDark ? Colors.white : Colors.black)
        : (isDark
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.2));

    final selectedItem = widget.items.cast<TetherDropdownItem<T>?>().firstWhere(
      (item) => item?.value == widget.value,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: () {
            setState(() => _isOpen = !_isOpen);
            _showDropdownMenu(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedItem?.label ?? widget.hint ?? '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: selectedItem != null
                          ? null
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.4)),
                    ),
                  ),
                ),
                Icon(
                  _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDropdownMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + renderBox.size.height + 4,
        offset.dx + renderBox.size.width,
        0,
      ),
      color: isDark ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      items: widget.items.map((item) {
        return PopupMenuItem<T>(
          value: item.value,
          child: Text(item.label, style: Theme.of(context).textTheme.bodyLarge),
        );
      }).toList(),
    ).then((value) {
      setState(() => _isOpen = false);
      if (value != null) {
        widget.onChanged?.call(value);
      }
    });
  }
}

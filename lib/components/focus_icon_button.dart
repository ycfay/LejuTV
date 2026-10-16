import 'package:flutter/material.dart';

/// Icon button with a green focus ring for TV/keyboard navigation.
class FocusIconButton extends StatefulWidget {
  const FocusIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = 25,
    this.focusColor = const Color.fromARGB(255, 249, 250, 250),
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double iconSize;
  final Color focusColor;

  @override
  State<FocusIconButton> createState() => _FocusIconButtonState();
}

class _FocusIconButtonState extends State<FocusIconButton> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        if (mounted) setState(() => _hasFocus = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _hasFocus ? const Color(0xFF00C878) : Colors.transparent,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: IconButton(
        focusNode: _focusNode,
        tooltip: widget.tooltip,
        onPressed: widget.onPressed,
        icon: Icon(
          widget.icon,
          size: widget.iconSize,
          color: widget.focusColor,
        ),
        color: Colors.white,
      ),
    );
  }
}

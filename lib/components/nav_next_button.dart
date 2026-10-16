import 'package:flutter/material.dart';

class NavTextButton extends StatefulWidget {
  const NavTextButton({
    super.key,
    required this.label,
    this.onTap,
    this.autofocus = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool autofocus;

  @override
  State<NavTextButton> createState() => _NavTextButtonState();
}

class _NavTextButtonState extends State<NavTextButton> {
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
    final color = _hasFocus ? Colors.white : const Color(0xFF797E80);
    return TextButton(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onPressed: widget.onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.only(bottom: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: color,
        overlayColor: Colors.transparent,
      ),
      child: Text(
        widget.label,
        style: TextStyle(
          color: color,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

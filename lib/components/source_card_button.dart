import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SourceCardButton extends StatefulWidget {
  const SourceCardButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<SourceCardButton> createState() => _SourceCardButtonState();
}

class _SourceCardButtonState extends State<SourceCardButton> {
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

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
      widget.onTap();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D1E),
            border: Border.all(
              color: _hasFocus
                  ? const Color(0xFF00C878)
                  : const Color(0xFF2A2E2F),
              width: _hasFocus ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.icon,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8B9092),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '→',
                style: TextStyle(color: Color(0xFF00C878), fontSize: 25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'wmp_theme.dart';

/// WMP 10's title bar: pale Luna blue, navy title text beside the player
/// icon, and flat navy window glyphs on the right — not the chunky Luna
/// buttons, which WMP drew in its own quieter style.
class TitleBar extends StatelessWidget {
  const TitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: _toggleMaximize,
      child: Container(
        height: 26,
        decoration: const BoxDecoration(
          gradient: Wmp.titleBarGradient,
          border: Border(bottom: BorderSide(color: Color(0xFFA5C0DE))),
        ),
        padding: const EdgeInsets.only(left: 7, right: 5),
        child: Row(
          children: [
            const _AppGlyph(),
            const SizedBox(width: 5),
            const Text(
              // The window wears the XP look, but it says whose player it is:
              // this is an homage, not Microsoft's product.
              'Luna Media Player',
              style: TextStyle(
                fontSize: 12,
                color: Wmp.titleText,
                fontFamilyFallback: Wmp.fontFallback,
              ),
            ),
            const Spacer(),
            _CaptionButton(
              glyph: Icons.remove,
              tooltip: 'Minimize',
              onTap: windowManager.minimize,
            ),
            _CaptionButton(
              glyph: Icons.crop_square,
              tooltip: 'Maximize',
              onTap: _toggleMaximize,
            ),
            _CaptionButton(
              glyph: Icons.close,
              tooltip: 'Close',
              onTap: windowManager.close,
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }
}

/// The little multicoloured player orb standing in for the WMP icon.
class _AppGlyph extends StatelessWidget {
  const _AppGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFB8E0FF), Color(0xFF2F84D0), Color(0xFF0F3B70)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: const Icon(Icons.play_arrow, size: 11, color: Colors.white),
    );
  }
}

/// Flat navy glyphs that gain a soft blue plate on hover — the quiet caption
/// buttons WMP 10 drew on its own chrome.
class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    required this.glyph,
    required this.tooltip,
    required this.onTap,
  });

  final IconData glyph;
  final String tooltip;
  final Future<void> Function() onTap;

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 24,
            height: 20,
            margin: const EdgeInsets.only(left: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: _hover ? const Color(0xFFAECBEA) : Colors.transparent,
              border: _hover
                  ? Border.all(color: Wmp.tabBorder, width: 1)
                  : null,
            ),
            child: Icon(widget.glyph, size: 13, color: Wmp.titleText),
          ),
        ),
      ),
    );
  }
}

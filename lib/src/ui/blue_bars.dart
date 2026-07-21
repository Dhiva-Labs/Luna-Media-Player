import 'package:flutter/material.dart';

import 'wmp_theme.dart';

/// The royal-blue sub-toolbar that runs under the feature taskbar, and the
/// matching status strip along the bottom of the content — the two blue bands
/// that frame WMP 10's white library.
class BlueToolbar extends StatelessWidget {
  const BlueToolbar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: const BoxDecoration(
        gradient: Wmp.toolbarGradient,
        border: Border(
          top: BorderSide(color: Wmp.tabBorder),
          bottom: BorderSide(color: Color(0xFF2E3F96)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: children),
    );
  }
}

class BlueStatusStrip extends StatelessWidget {
  const BlueStatusStrip({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      decoration: const BoxDecoration(
        gradient: Wmp.statusGradient,
        border: Border(top: BorderSide(color: Color(0xFF2E3F96))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: children),
    );
  }
}

const blueBarText = TextStyle(
  fontSize: 12,
  color: Colors.white,
  fontFamilyFallback: Wmp.fontFallback,
);

/// A flat white label on the blue bars — with a ▾ when it opens a menu.
class BlueBarButton extends StatefulWidget {
  const BlueBarButton({
    super.key,
    required this.label,
    this.icon,
    this.dropdown = false,
    this.onTap,
    this.menuItems,
  }) : assert(onTap == null || menuItems == null);

  final String label;
  final IconData? icon;
  final bool dropdown;
  final VoidCallback? onTap;
  final List<PopupMenuEntry<VoidCallback>>? menuItems;

  @override
  State<BlueBarButton> createState() => _BlueBarButtonState();
}

class _BlueBarButtonState extends State<BlueBarButton> {
  bool _hover = false;

  Future<void> _openMenu() async {
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final action = await showMenu<VoidCallback>(
      context: context,
      position: RelativeRect.fromLTRB(
        origin.dx,
        origin.dy + box.size.height,
        overlay.size.width - origin.dx - box.size.width,
        0,
      ),
      items: widget.menuItems!,
    );
    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.menuItems != null ? _openMenu : widget.onTap,
        child: Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: _hover ? const Color(0x33FFFFFF) : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(widget.label, style: blueBarText),
              if (widget.dropdown) ...[
                const SizedBox(width: 3),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

PopupMenuItem<VoidCallback> blueMenuItem(String label, VoidCallback action) {
  return PopupMenuItem<VoidCallback>(
    value: action,
    height: 26,
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12.5,
        fontFamilyFallback: Wmp.fontFallback,
      ),
    ),
  );
}

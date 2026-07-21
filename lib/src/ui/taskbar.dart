import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/ui_state.dart';
import 'wmp_theme.dart';

/// WMP 10's feature taskbar: a pale blue strip where the active tab stands up
/// as a white rounded tab that merges into the toolbar beneath it.
///
/// Rip, Burn, Sync and Guide are drawn because the player would not look
/// right without them, and do nothing because there is no CD burner in this
/// recreation.
class Taskbar extends ConsumerWidget {
  const Taskbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(appTabProvider);

    return Container(
      height: 30,
      decoration: const BoxDecoration(gradient: Wmp.taskbarGradient),
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final tab in AppTab.values)
            _TaskbarTab(
              label: tab.label,
              active: tab == active,
              onTap: () => ref.read(appTabProvider.notifier).state = tab,
            ),
          const _TaskbarTab(label: 'Rip'),
          const _TaskbarTab(label: 'Burn'),
          const _TaskbarTab(label: 'Sync'),
          const _TaskbarTab(label: 'Guide'),
          const Spacer(),
          // The glass orb in the top-right corner.
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 3),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment(-0.3, -0.4),
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFF6FB7F0),
                    Color(0xFF1E63B4),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x552B4A7A),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskbarTab extends StatefulWidget {
  const _TaskbarTab({required this.label, this.active = false, this.onTap});

  final String label;
  final bool active;

  /// Null for the decorative tabs.
  final VoidCallback? onTap;

  @override
  State<_TaskbarTab> createState() => _TaskbarTabState();
}

class _TaskbarTabState extends State<_TaskbarTab> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: widget.active ? 26 : 24,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: widget.active
          ? const BoxDecoration(
              color: Wmp.activeTab,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              border: Border(
                top: BorderSide(color: Wmp.tabBorder),
                left: BorderSide(color: Wmp.tabBorder),
                right: BorderSide(color: Wmp.tabBorder),
              ),
            )
          : BoxDecoration(
              color: _hover && widget.onTap != null
                  ? const Color(0x66FFFFFF)
                  : Colors.transparent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
      alignment: Alignment.center,
      child: Text(
        widget.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: widget.active ? FontWeight.bold : FontWeight.normal,
          color: widget.onTap == null
              ? const Color(0xFF5B72A8) // the tabs that go nowhere sit dimmer
              : Wmp.tabText,
          fontFamilyFallback: Wmp.fontFallback,
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(onTap: widget.onTap, child: child),
    );
  }
}

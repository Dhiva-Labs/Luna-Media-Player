import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../app_info.dart';
import '../models/visualizer_style.dart';
import '../services/library_scanner.dart';
import '../state/library_state.dart';
import '../state/player_state.dart';
import '../state/ui_state.dart';
import 'wmp_theme.dart';

/// The classic menu bar — File, View, Play, Tools, Help — as WMP 10 showed it
/// with "Show menu bar" on: black text on the pale blue chrome, white
/// XP-style popup menus.
class WmpMenuBar extends ConsumerWidget {
  const WmpMenuBar({super.key});

  static const _menuStyle = MenuStyle(
    backgroundColor: WidgetStatePropertyAll(Colors.white),
    surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
    side: WidgetStatePropertyAll(BorderSide(color: Color(0xFF97A5C8))),
    shape: WidgetStatePropertyAll(RoundedRectangleBorder()),
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 2)),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);
    final vizStyle = ref.watch(visualizerStyleProvider);

    return Container(
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFFD8E5F5),
        border: Border(bottom: BorderSide(color: Color(0xFFB3C9E2))),
      ),
      child: Row(
        children: [
          _menu(context, 'File', [
            _item('Open files…', () => _openFiles(ref)),
            _item('Add folder to library…', () => _addFolder(ref)),
            const _MenuDivider(),
            _item('Exit', windowManager.close),
          ]),
          _menu(context, 'View', [
            SubmenuButton(
              menuStyle: _menuStyle,
              style: _itemStyle,
              menuChildren: [
                for (final style in VisualizerStyle.values)
                  _radio(
                    style.label,
                    selected: style == vizStyle,
                    onTap: () =>
                        ref.read(visualizerStyleProvider.notifier).set(style),
                  ),
              ],
              child: const Text('Visualizations'),
            ),
          ]),
          _menu(context, 'Play', [
            _item(
              'Play / Pause        Space',
              () => ref.read(playbackProvider.notifier).togglePlayPause(),
            ),
            _item('Stop', () => ref.read(playbackProvider.notifier).stop()),
            _item(
              'Previous',
              () => ref.read(playbackProvider.notifier).previous(),
            ),
            _item('Next', () => ref.read(playbackProvider.notifier).next()),
            const _MenuDivider(),
            _radio(
              'Shuffle',
              selected: playback.shuffle,
              onTap: () => ref.read(playbackProvider.notifier).toggleShuffle(),
            ),
            SubmenuButton(
              menuStyle: _menuStyle,
              style: _itemStyle,
              menuChildren: [
                for (final mode in RepeatMode.values)
                  _radio(
                    mode.label,
                    selected: mode == playback.repeat,
                    onTap: () =>
                        ref.read(playbackProvider.notifier).setRepeat(mode),
                  ),
              ],
              child: const Text('Repeat'),
            ),
          ]),
          _menu(context, 'Tools', [
            _item(
              'Rescan library',
              () => ref.read(libraryProvider.notifier).rescan(),
            ),
          ]),
          _menu(context, 'Help', [_item('About', () => _about(context))]),
        ],
      ),
    );
  }

  static const _itemStyle = ButtonStyle(
    foregroundColor: WidgetStatePropertyAll(Colors.black),
    overlayColor: WidgetStatePropertyAll(Color(0xFF316AC5)),
    textStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 12, fontFamilyFallback: Wmp.fontFallback),
    ),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 14, vertical: 3),
    ),
    minimumSize: WidgetStatePropertyAll(Size(180, 24)),
    alignment: Alignment.centerLeft,
  );

  Widget _menu(BuildContext context, String label, List<Widget> children) {
    return MenuAnchor(
      style: _menuStyle,
      menuChildren: children,
      builder: (context, controller, _) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          hoverColor: const Color(0xFFBFD5EE),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontFamilyFallback: Wmp.fontFallback,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _item(String label, VoidCallback onTap) {
    return MenuItemButton(
      style: _itemStyle,
      onPressed: onTap,
      child: Text(label),
    );
  }

  Widget _radio(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return MenuItemButton(
      style: _itemStyle,
      leadingIcon: Icon(
        selected ? Icons.check : null,
        size: 13,
        color: Colors.black,
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }

  static Future<void> _openFiles(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        ...LibraryScanner.audioExtensions.map((e) => e.substring(1)),
        ...LibraryScanner.videoExtensions.map((e) => e.substring(1)),
      ],
    );
    final paths =
        result?.files.map((f) => f.path).whereType<String>().toList() ?? [];
    if (paths.isEmpty) return;

    // Tag reading is sync IO; a big multi-select shouldn't stutter the UI.
    final tracks = await Isolate.run(
      () => paths.map(LibraryScanner.trackFor).toList(),
    );
    ref.read(playbackProvider.notifier).playQueue(tracks);
    ref.read(appTabProvider.notifier).state = AppTab.nowPlaying;
  }

  static Future<void> _addFolder(WidgetRef ref) async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    await ref.read(libraryProvider.notifier).addFolder(path);
    ref.read(appTabProvider.notifier).state = AppTab.library;
  }

  static void _about(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Wmp.chromeBorder),
        ),
        title: const Text(
          'About ${AppInfo.name}',
          style: TextStyle(fontSize: 15, fontFamilyFallback: Wmp.fontFallback),
        ),
        content: const Text(
          '${AppInfo.name} ${AppInfo.version}\n'
          'by ${AppInfo.vendor}\n\n'
          'A media player for Ubuntu and other Linux desktops, styled after\n'
          'the XP-era players of 2004.\n\n'
          'Visualisations: Ambience, Alchemy, Plenty, Bars, Ocean Mist,\n'
          'Scope, Battery and Fire Storm.\n\n'
          '${AppInfo.homepage}\n\n'
          '${AppInfo.trademarkNotice}',
          style: TextStyle(
            fontSize: 12.5,
            fontFamilyFallback: Wmp.fontFallback,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 5, thickness: 1, color: Color(0xFFD5DCEA));
  }
}

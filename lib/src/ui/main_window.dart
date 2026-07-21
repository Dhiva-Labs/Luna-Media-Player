import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/player_state.dart';
import '../state/ui_state.dart';
import 'library_view.dart';
import 'now_playing_view.dart';
import 'taskbar.dart';
import 'title_bar.dart';
import 'transport_bar.dart';
import 'wmp_menu_bar.dart';
import 'wmp_theme.dart';

/// The whole player, stacked the way WMP stacked it: title bar, menu bar,
/// feature taskbar, the active view, then the transport across the bottom.
class MainWindow extends ConsumerStatefulWidget {
  const MainWindow({super.key});

  @override
  ConsumerState<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends ConsumerState<MainWindow> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  /// The transport shortcuts, handled for the whole window.
  ///
  /// Deliberately not `CallbackShortcuts`: those only fire while focus sits
  /// inside their subtree, and this window has a search box. Typing in it and
  /// then clicking away left the app with no focus at all, and Space — the one
  /// shortcut everybody tries — silently did nothing.
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    // A text field gets its own keys: Space must stay typeable.
    if (FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>() !=
        null) {
      return false;
    }

    final notifier = ref.read(playbackProvider.notifier);
    final ctrl = HardwareKeyboard.instance.isControlPressed;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.mediaPlayPause:
        notifier.togglePlayPause();
      case LogicalKeyboardKey.mediaTrackNext:
        notifier.next();
      case LogicalKeyboardKey.mediaTrackPrevious:
        notifier.previous();
      case LogicalKeyboardKey.mediaStop:
        notifier.stop();
      case LogicalKeyboardKey.arrowRight when ctrl:
        notifier.next();
      case LogicalKeyboardKey.arrowLeft when ctrl:
        notifier.previous();
      default:
        return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(appTabProvider);

    // Material, or every Text renders with the yellow missing-ancestor
    // underline; transparent so the frame colour shows through.
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: Wmp.content,
          border: Border.all(color: Wmp.chromeBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TitleBar(),
            const WmpMenuBar(),
            const Taskbar(),
            Expanded(
              child: switch (tab) {
                AppTab.nowPlaying => const NowPlayingView(),
                AppTab.library => const LibraryView(),
              },
            ),
            const TransportBar(),
          ],
        ),
      ),
    );
  }
}

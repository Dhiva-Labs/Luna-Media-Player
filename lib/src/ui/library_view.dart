import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/track.dart';
import '../state/library_state.dart';
import '../state/player_state.dart';
import '../state/ui_state.dart';
import 'blue_bars.dart';
import 'now_playing_view.dart' show NowPlayingListPane;
import 'wmp_theme.dart';

/// WMP 10's library: royal-blue toolbar with the search box, the tree pane on
/// the left, the white table with its blue text, the Now Playing List pane on
/// the right, and the blue status strip along the bottom.
class LibraryView extends ConsumerWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final visible = ref.watch(visibleTracksProvider);

    final totalTime = visible.fold<Duration>(
      Duration.zero,
      (sum, t) => sum + (t.duration ?? Duration.zero),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlueToolbar(
          children: [
            const _SearchBox(),
            const SizedBox(width: 14),
            BlueBarButton(
              label: 'Library Options',
              dropdown: true,
              menuItems: [
                blueMenuItem('Add folder to library…', () => _addFolder(ref)),
                if (library.folders.isNotEmpty)
                  ...library.folders.map(
                    (f) => blueMenuItem(
                      'Remove  $f',
                      () => ref.read(libraryProvider.notifier).removeFolder(f),
                    ),
                  ),
                blueMenuItem(
                  'Rescan library',
                  ref.read(libraryProvider.notifier).rescan,
                ),
              ],
            ),
            const Spacer(),
            BlueBarButton(
              label: 'Now Playing List',
              dropdown: true,
              onTap: () =>
                  ref.read(appTabProvider.notifier).state = AppTab.nowPlaying,
            ),
          ],
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _TreePane(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _HeaderRow(),
                    Expanded(
                      child: ColoredBox(
                        color: Wmp.content,
                        child: visible.isEmpty
                            ? _EmptyState(
                                scanning: library.scanning,
                                hasFolders: library.folders.isNotEmpty,
                              )
                            : ListView.builder(
                                itemCount: visible.length,
                                itemExtent: 22,
                                itemBuilder: (context, i) => _TrackRow(
                                  track: visible[i],
                                  onPlay: () {
                                    ref
                                        .read(playbackProvider.notifier)
                                        .playQueue(visible, startAt: i);
                                    ref.read(appTabProvider.notifier).state =
                                        AppTab.nowPlaying;
                                  },
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const NowPlayingListPane(),
            ],
          ),
        ),
        BlueStatusStrip(
          children: [
            BlueBarButton(
              label: 'Add to Library',
              icon: Icons.add_circle,
              dropdown: true,
              onTap: () => _addFolder(ref),
            ),
            const SizedBox(width: 16),
            Text(
              library.scanning ? 'Scanning…' : '${visible.length} Item(s)',
              style: blueBarText,
            ),
            const Spacer(),
            Text(
              'Total Time: ${formatDuration(totalTime)}',
              style: blueBarText,
            ),
          ],
        ),
      ],
    );
  }

  static Future<void> _addFolder(WidgetRef ref) async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    await ref.read(libraryProvider.notifier).addFolder(path);
  }
}

class _SearchBox extends ConsumerWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          height: 20,
          child: TextField(
            onChanged: (v) =>
                ref.read(librarySearchProvider.notifier).state = v,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontFamilyFallback: Wmp.fontFallback,
            ),
            cursorColor: Colors.black,
            // Clicking away hands focus back to the player, so Space is a
            // play/pause again rather than a character nobody sees.
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(1),
                borderSide: const BorderSide(color: Color(0xFF2E3F96)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(1),
                borderSide: const BorderSide(color: Color(0xFF2E3F96)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.search, size: 14, color: Colors.white),
        const SizedBox(width: 3),
        const Text('Search', style: blueBarText),
      ],
    );
  }
}

/// The tree pane: All Music, All Video, and the library folders below them.
class _TreePane extends ConsumerWidget {
  const _TreePane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(libraryFilterProvider);

    return Container(
      width: 150,
      decoration: const BoxDecoration(
        color: Wmp.content,
        border: Border(right: BorderSide(color: Color(0xFFB9CBE2))),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: 4),
        children: [
          _TreeItem(
            label: 'All Music',
            icon: Icons.music_note,
            iconColor: const Color(0xFF3B6ED0),
            selected: selected == LibraryFilter.allMusic,
            onTap: () => ref.read(libraryFilterProvider.notifier).state =
                LibraryFilter.allMusic,
          ),
          _TreeItem(
            label: 'All Video',
            icon: Icons.movie,
            iconColor: const Color(0xFF7A52B8),
            selected: selected == LibraryFilter.allVideo,
            onTap: () => ref.read(libraryFilterProvider.notifier).state =
                LibraryFilter.allVideo,
          ),
          _TreeItem(
            label: 'Now Playing',
            icon: Icons.play_arrow,
            iconColor: const Color(0xFF2FA32F),
            selected: false,
            onTap: () =>
                ref.read(appTabProvider.notifier).state = AppTab.nowPlaying,
          ),
        ],
      ),
    );
  }
}

class _TreeItem extends StatelessWidget {
  const _TreeItem({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 22,
        padding: const EdgeInsets.only(left: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              color: selected ? Wmp.rowSelected : Colors.transparent,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontFamilyFallback: Wmp.fontFallback,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _colTitle = 38;
const _colArtist = 26;
const _colAlbum = 24;
const _colLength = 12;

/// The white XP column headers with their hairline separators.
class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFD5D5D5))),
      ),
      child: const Row(
        children: [
          _HeaderCell('Title', flex: _colTitle),
          _HeaderCell('Artist', flex: _colArtist),
          _HeaderCell('Album', flex: _colAlbum),
          _HeaderCell('Length', flex: _colLength, alignRight: true),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex, this.alignRight = false});

  final String label;
  final int flex;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: Wmp.headerText,
            fontFamilyFallback: Wmp.fontFallback,
          ),
        ),
      ),
    );
  }
}

class _TrackRow extends StatefulWidget {
  const _TrackRow({required this.track, required this.onPlay});

  final Track track;
  final VoidCallback onPlay;

  @override
  State<_TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<_TrackRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    const cell = TextStyle(
      fontSize: 12,
      color: Wmp.itemText,
      fontFamilyFallback: Wmp.fontFallback,
    );

    Widget pad(Widget child, int flex, {bool alignRight = false}) => Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: child,
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onDoubleTap: widget.onPlay,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: _hover ? Wmp.rowHover : Colors.white,
          child: Row(
            children: [
              pad(
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cell,
                ),
                _colTitle,
              ),
              pad(
                Text(
                  track.artistLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cell,
                ),
                _colArtist,
              ),
              pad(
                Text(
                  track.albumLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cell,
                ),
                _colAlbum,
              ),
              pad(
                Text(formatDuration(track.duration), style: cell),
                _colLength,
                alignRight: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scanning, required this.hasFolders});

  final bool scanning;
  final bool hasFolders;

  @override
  Widget build(BuildContext context) {
    final message = scanning
        ? 'Scanning your folders…'
        : hasFolders
        ? 'No items found here.'
        : 'Your library is empty.\nUse Library Options → Add folder.';
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: Wmp.itemTextDim,
          height: 1.6,
          fontFamilyFallback: Wmp.fontFallback,
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';
import '../services/library_scanner.dart';
import 'player_state.dart';

class LibraryState {
  const LibraryState({
    this.folders = const [],
    this.tracks = const [],
    this.scanning = false,
  });

  final List<String> folders;
  final List<Track> tracks;
  final bool scanning;

  LibraryState copyWith({
    List<String>? folders,
    List<Track>? tracks,
    bool? scanning,
  }) {
    return LibraryState(
      folders: folders ?? this.folders,
      tracks: tracks ?? this.tracks,
      scanning: scanning ?? this.scanning,
    );
  }
}

class LibraryController extends StateNotifier<LibraryState> {
  LibraryController(this._prefs) : super(const LibraryState()) {
    final saved = _prefs.getStringList(_foldersKey);
    final folders = saved ?? _defaultFolders();
    state = state.copyWith(folders: folders);
    if (folders.isNotEmpty) rescan();
  }

  static const _foldersKey = 'libraryFolders';
  final SharedPreferences _prefs;
  int _scanGeneration = 0;

  static List<String> _defaultFolders() {
    final home = Platform.environment['HOME'];
    if (home == null) return const [];
    final music = Directory(p.join(home, 'Music'));
    return music.existsSync() ? [music.path] : const [];
  }

  Future<void> addFolder(String path) async {
    if (state.folders.contains(path)) return;
    state = state.copyWith(folders: [...state.folders, path]);
    await _prefs.setStringList(_foldersKey, state.folders);
    await rescan();
  }

  Future<void> removeFolder(String path) async {
    state = state.copyWith(
      folders: state.folders.where((f) => f != path).toList(),
    );
    await _prefs.setStringList(_foldersKey, state.folders);
    await rescan();
  }

  Future<void> rescan() async {
    final generation = ++_scanGeneration;
    state = state.copyWith(scanning: true);
    final tracks = await LibraryScanner.scan(state.folders);
    // A folder added mid-scan started a newer scan; let that one win.
    if (generation != _scanGeneration || !mounted) return;
    state = state.copyWith(tracks: tracks, scanning: false);
  }
}

final libraryProvider = StateNotifierProvider<LibraryController, LibraryState>(
  (ref) => LibraryController(ref.watch(prefsProvider)),
);

/// The library search box.
final librarySearchProvider = StateProvider<String>((_) => '');

/// The tree pane on the left of the library, as WMP 10 divided it.
enum LibraryFilter {
  allMusic('All Music'),
  allVideo('All Video');

  const LibraryFilter(this.label);
  final String label;
}

final libraryFilterProvider = StateProvider<LibraryFilter>(
  (_) => LibraryFilter.allMusic,
);

/// What the library table actually shows: the scan cut down by the tree
/// selection, then by the search box.
final visibleTracksProvider = Provider<List<Track>>((ref) {
  final filter = ref.watch(libraryFilterProvider);
  final tracks = ref
      .watch(libraryProvider)
      .tracks
      .where((t) => t.isVideo == (filter == LibraryFilter.allVideo))
      .toList();
  final query = ref.watch(librarySearchProvider).trim().toLowerCase();
  if (query.isEmpty) return tracks;
  return tracks.where((t) {
    return t.title.toLowerCase().contains(query) ||
        t.artistLabel.toLowerCase().contains(query) ||
        t.albumLabel.toLowerCase().contains(query);
  }).toList();
});

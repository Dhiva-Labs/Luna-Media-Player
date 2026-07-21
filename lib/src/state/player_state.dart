import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';
import '../models/visualizer_style.dart';

/// Injected in main() once SharedPreferences has loaded.
final prefsProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('overridden in main'),
);

final playerProvider = Provider<Player>((ref) {
  final player = Player();
  ref.onDispose(player.dispose);
  return player;
});

final videoControllerProvider = Provider<VideoController>(
  (ref) => VideoController(ref.watch(playerProvider)),
);

enum RepeatMode {
  off('Repeat off'),
  all('Repeat all'),
  one('Repeat one');

  const RepeatMode(this.label);
  final String label;

  RepeatMode get next => RepeatMode.values[(index + 1) % 3];
}

class PlaybackState {
  const PlaybackState({
    this.queue = const [],
    this.index = -1,
    this.shuffle = false,
    this.repeat = RepeatMode.off,
  });

  final List<Track> queue;
  final int index;
  final bool shuffle;
  final RepeatMode repeat;

  Track? get current =>
      index >= 0 && index < queue.length ? queue[index] : null;

  PlaybackState copyWith({
    List<Track>? queue,
    int? index,
    bool? shuffle,
    RepeatMode? repeat,
  }) {
    return PlaybackState(
      queue: queue ?? this.queue,
      index: index ?? this.index,
      shuffle: shuffle ?? this.shuffle,
      repeat: repeat ?? this.repeat,
    );
  }
}

/// The queue and its rules. Position, duration and play/pause state live on
/// the [Player]'s own streams; this only decides *what* plays next.
class PlaybackController extends StateNotifier<PlaybackState> {
  PlaybackController(this._player, this._prefs)
    : super(
        PlaybackState(
          shuffle: _prefs.getBool(_shuffleKey) ?? false,
          repeat:
              RepeatMode.values[(_prefs.getInt(_repeatKey) ?? 0).clamp(0, 2)],
        ),
      ) {
    _player.stream.completed.listen((done) {
      if (done) _autoAdvance();
    });
    _player.setVolume(_prefs.getDouble(_volumeKey) ?? 80);
  }

  static const _shuffleKey = 'shuffle';
  static const _repeatKey = 'repeat';
  static const _volumeKey = 'volume';

  final Player _player;
  final SharedPreferences _prefs;
  final _random = Random();
  double _volumeBeforeMute = 80;

  void playQueue(List<Track> tracks, {int startAt = 0}) {
    if (tracks.isEmpty) return;
    state = state.copyWith(queue: List.unmodifiable(tracks), index: startAt);
    _open();
  }

  void playAt(int index) {
    if (index < 0 || index >= state.queue.length) return;
    state = state.copyWith(index: index);
    _open();
  }

  void togglePlayPause() {
    if (state.current == null) {
      // Nothing loaded yet: play from the top of the queue if there is one.
      if (state.queue.isNotEmpty) playAt(0);
      return;
    }
    _player.playOrPause();
  }

  /// WMP's stop: playback halts and the position returns to the start, but
  /// the track stays loaded and lit in the playlist.
  void stop() {
    _player.pause();
    _player.seek(Duration.zero);
  }

  void next() => _advance(manual: true);

  void previous() {
    if (state.queue.isEmpty) return;
    // A few seconds in, "previous" means "start this one over" — the
    // behaviour every player of that era shared.
    if (_player.state.position > const Duration(seconds: 3)) {
      _player.seek(Duration.zero);
      return;
    }
    final count = state.queue.length;
    playAt((state.index - 1 + count) % count);
  }

  void _autoAdvance() {
    if (state.repeat == RepeatMode.one) {
      _open();
    } else {
      _advance(manual: false);
    }
  }

  void _advance({required bool manual}) {
    final count = state.queue.length;
    if (count == 0) return;

    int nextIndex;
    if (state.shuffle && count > 1) {
      do {
        nextIndex = _random.nextInt(count);
      } while (nextIndex == state.index);
    } else {
      nextIndex = state.index + 1;
      if (nextIndex >= count) {
        // The end of the queue. A manual Next wraps around; natural playback
        // only continues if Repeat All is on.
        if (!manual && state.repeat != RepeatMode.all) {
          state = state.copyWith(index: 0);
          _player.pause();
          return;
        }
        nextIndex = 0;
      }
    }
    playAt(nextIndex);
  }

  void toggleShuffle() {
    state = state.copyWith(shuffle: !state.shuffle);
    _prefs.setBool(_shuffleKey, state.shuffle);
  }

  void cycleRepeat() => setRepeat(state.repeat.next);

  void setRepeat(RepeatMode mode) {
    state = state.copyWith(repeat: mode);
    _prefs.setInt(_repeatKey, mode.index);
  }

  void setVolume(double volume) {
    _player.setVolume(volume.clamp(0, 100));
    _prefs.setDouble(_volumeKey, volume.clamp(0, 100));
  }

  void toggleMute() {
    final now = _player.state.volume;
    if (now > 0) {
      _volumeBeforeMute = now;
      _player.setVolume(0);
    } else {
      _player.setVolume(_volumeBeforeMute <= 0 ? 80 : _volumeBeforeMute);
    }
  }

  void seek(Duration position) => _player.seek(position);

  void _open() {
    final track = state.current;
    if (track == null) return;
    _player.open(Media(track.path), play: true);
  }
}

final playbackProvider =
    StateNotifierProvider<PlaybackController, PlaybackState>(
      (ref) => PlaybackController(
        ref.watch(playerProvider),
        ref.watch(prefsProvider),
      ),
    );

final isPlayingProvider = StreamProvider<bool>(
  (ref) => ref.watch(playerProvider).stream.playing,
);

final positionProvider = StreamProvider<Duration>(
  (ref) => ref.watch(playerProvider).stream.position,
);

final durationProvider = StreamProvider<Duration>(
  (ref) => ref.watch(playerProvider).stream.duration,
);

final volumeProvider = StreamProvider<double>(
  (ref) => ref.watch(playerProvider).stream.volume,
);

/// Cover art for the current track, read lazily so the library scan never
/// pays for images nobody is looking at.
final currentArtProvider = FutureProvider<Uint8List?>((ref) async {
  final track = ref.watch(playbackProvider.select((s) => s.current));
  if (track == null || track.isVideo) return null;
  final path = track.path;
  return Isolate.run(() {
    try {
      final meta = readMetadata(File(path), getImage: true);
      return meta.pictures.isEmpty ? null : meta.pictures.first.bytes;
    } catch (_) {
      return null;
    }
  });
});

/// The chosen visualisation, persisted like everything else the user touches.
class VisualizerStyleController extends StateNotifier<VisualizerStyle> {
  VisualizerStyleController(this._prefs)
    : super(
        VisualizerStyle.values[(_prefs.getInt(_key) ?? 0).clamp(
          0,
          VisualizerStyle.values.length - 1,
        )],
      );

  static const _key = 'visualizerStyle';
  final SharedPreferences _prefs;

  void set(VisualizerStyle style) {
    state = style;
    _prefs.setInt(_key, style.index);
  }

  void cycle() => set(state.next);
  void cycleBack() => set(state.previous);
}

final visualizerStyleProvider =
    StateNotifierProvider<VisualizerStyleController, VisualizerStyle>(
      (ref) => VisualizerStyleController(ref.watch(prefsProvider)),
    );

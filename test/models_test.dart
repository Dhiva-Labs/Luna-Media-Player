import 'package:flutter_test/flutter_test.dart';
import 'package:luna_media_player/src/app_info.dart';
import 'package:luna_media_player/src/models/track.dart';
import 'package:luna_media_player/src/models/visualizer_style.dart';
import 'package:luna_media_player/src/ui/wmp_theme.dart';

void main() {
  group('formatDuration', () {
    test('renders like a media player', () {
      expect(formatDuration(null), '--:--');
      expect(formatDuration(Duration.zero), '0:00');
      expect(formatDuration(const Duration(minutes: 3, seconds: 7)), '3:07');
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });

    test('pads minutes only once an hour is on the clock', () {
      expect(formatDuration(const Duration(minutes: 62)), '1:02:00');
      expect(formatDuration(const Duration(minutes: 9, seconds: 5)), '9:05');
    });
  });

  group('Track', () {
    test('identity is the path — the same file is the same track', () {
      const a = Track(path: '/music/x.mp3', title: 'X');
      const b = Track(path: '/music/x.mp3', title: 'Different title');
      const c = Track(path: '/music/y.mp3', title: 'X');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('labels stand in for missing tags', () {
      const bare = Track(path: '/music/x.mp3', title: 'X');
      expect(bare.artistLabel, 'Unknown artist');
      expect(bare.albumLabel, 'Unknown album');

      const tagged = Track(
        path: '/music/y.mp3',
        title: 'Y',
        artist: 'Someone',
        album: 'Something',
      );
      expect(tagged.artistLabel, 'Someone');
      expect(tagged.albumLabel, 'Something');
    });
  });

  group('VisualizerStyle', () {
    test('cycles forward and wraps', () {
      expect(VisualizerStyle.ambience.next, VisualizerStyle.alchemy);
      expect(VisualizerStyle.values.last.next, VisualizerStyle.values.first);
    });

    test('cycles backward and wraps', () {
      expect(VisualizerStyle.alchemy.previous, VisualizerStyle.ambience);
      expect(
        VisualizerStyle.values.first.previous,
        VisualizerStyle.values.last,
      );
    });

    test('the flowing styles are the ones that keep a trail', () {
      final flowing = VisualizerStyle.values.where((s) => s.flows).toSet();
      expect(flowing, {
        VisualizerStyle.ambience,
        VisualizerStyle.alchemy,
        VisualizerStyle.plenty,
      });
    });

    test('every style is labelled and described', () {
      for (final style in VisualizerStyle.values) {
        expect(style.label, isNotEmpty);
        expect(style.description, isNotEmpty);
      }
    });
  });

  group('AppInfo', () {
    test('the app is branded Luna Media Player, by DhivaLabs', () {
      expect(AppInfo.name, 'Luna Media Player');
      expect(AppInfo.vendor, 'DhivaLabs');
    });

    test('the version is a plain semantic version', () {
      expect(AppInfo.version, matches(RegExp(r'^\d+\.\d+\.\d+$')));
    });
  });
}

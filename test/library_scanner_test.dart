import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:luna_media_player/src/services/library_scanner.dart';
import 'package:path/path.dart' as p;

/// A minimal but real MPEG transport stream: 0x47 sync bytes at 0, 188, 376.
Uint8List _mpegTsBytes() {
  final bytes = Uint8List(188 * 3);
  for (var i = 0; i < 3; i++) {
    bytes[188 * i] = 0x47;
  }
  return bytes;
}

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('luna_scan_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  File write(String relative, [List<int>? bytes]) {
    final file = File(p.join(tmp.path, relative));
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes ?? const [0, 1, 2, 3]);
    return file;
  }

  group('isPlayable', () {
    test('accepts the audio formats the player advertises', () {
      for (final ext in ['.mp3', '.wav', '.flac', '.ogg', '.aac', '.m4a']) {
        expect(LibraryScanner.isPlayable('song$ext'), isTrue, reason: ext);
      }
    });

    test('accepts the video containers', () {
      for (final ext in ['.mp4', '.mkv', '.avi', '.webm', '.mov', '.wmv']) {
        expect(LibraryScanner.isPlayable('clip$ext'), isTrue, reason: ext);
      }
    });

    test('rejects everything else', () {
      for (final name in ['notes.txt', 'photo.jpg', 'archive.zip', 'README']) {
        expect(LibraryScanner.isPlayable(name), isFalse, reason: name);
      }
    });

    test('is case-insensitive, as filesystems in the wild are not', () {
      expect(LibraryScanner.isPlayable('SONG.MP3'), isTrue);
      expect(LibraryScanner.isPlayable('Clip.MkV'), isTrue);
    });
  });

  group('scanSync', () {
    test('finds media recursively and ignores non-media', () {
      write('a.mp3');
      write('nested/b.mkv');
      write('nested/deeper/c.flac');
      write('notes.txt');
      write('cover.jpg');

      final found = LibraryScanner.scanSync([tmp.path]);

      expect(found.map((t) => p.basename(t.path)).toSet(), {
        'a.mp3',
        'b.mkv',
        'c.flac',
      });
    });

    test('marks video files as video and audio files as not', () {
      write('song.mp3');
      write('movie.mp4');

      final byName = {
        for (final t in LibraryScanner.scanSync([tmp.path]))
          p.basename(t.path): t,
      };

      expect(byName['movie.mp4']!.isVideo, isTrue);
      expect(byName['song.mp3']!.isVideo, isFalse);
    });

    test('skips dotfiles and dot-directories', () {
      write('.hidden.mp3');
      write('.cache/tucked-away.mp3');
      write('visible.mp3');

      final found = LibraryScanner.scanSync([tmp.path]);

      expect(found.map((t) => p.basename(t.path)), ['visible.mp3']);
    });

    test('does not report the same file twice when folders overlap', () {
      write('song.mp3');

      final found = LibraryScanner.scanSync([tmp.path, tmp.path]);

      expect(found, hasLength(1));
    });

    test('survives a folder that does not exist', () {
      write('song.mp3');

      final found = LibraryScanner.scanSync([
        p.join(tmp.path, 'nowhere'),
        tmp.path,
      ]);

      expect(found, hasLength(1));
    });

    test('admits a .ts file only when it is really a transport stream', () {
      write('broadcast.ts', _mpegTsBytes());
      write('component.ts', 'export const x = 1;\n'.codeUnits);

      final found = LibraryScanner.scanSync([tmp.path]);

      expect(found.map((t) => p.basename(t.path)), ['broadcast.ts']);
    });

    test('sorts by artist, then album, then track number', () {
      // Untagged files fall back to "Unknown artist"/"Unknown album", so the
      // ordering that remains observable here is by title.
      write('zebra.mp3');
      write('alpha.mp3');
      write('mango.mp3');

      final found = LibraryScanner.scanSync([tmp.path]);

      expect(found.map((t) => t.title), ['alpha', 'mango', 'zebra']);
    });
  });

  group('trackFor', () {
    test('falls back to the filename when a file carries no tags', () {
      final file = write('Some Song.mp3');

      final track = LibraryScanner.trackFor(file.path);

      expect(track.title, 'Some Song');
      expect(track.artistLabel, 'Unknown artist');
      expect(track.albumLabel, 'Unknown album');
    });

    test('does not throw on a corrupt file — it stays playable', () {
      final file = write('corrupt.flac', List.filled(64, 0xFF));

      final track = LibraryScanner.trackFor(file.path);

      expect(track.title, 'corrupt');
      expect(track.path, file.path);
    });
  });
}

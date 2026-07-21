import 'dart:io';
import 'dart:isolate';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:path/path.dart' as p;

import '../models/track.dart';

/// Walks the library folders and reads tags.
///
/// The whole scan runs in an isolate: tag parsing is synchronous file IO and a
/// large library would freeze the UI for seconds otherwise.
class LibraryScanner {
  // Everything mpv demuxes. Audio first, then every container video came in
  // between 1995 and now — this is a Windows Media Player, after all.
  static const audioExtensions = {
    '.mp3',
    '.flac',
    '.ogg',
    '.oga',
    '.opus',
    '.m4a',
    '.aac',
    '.wav',
    '.wma',
    '.mka',
    '.aif',
    '.aiff',
    '.ape',
    '.wv',
    '.ac3',
    '.dts',
    '.amr',
    '.mpc',
  };

  static const videoExtensions = {
    '.mp4',
    '.mkv',
    '.avi',
    '.webm',
    '.mov',
    '.wmv',
    '.m4v',
    '.mpg',
    '.mpeg',
    '.ts',
    '.m2ts',
    '.mts',
    '.flv',
    '.f4v',
    '.3gp',
    '.3g2',
    '.ogv',
    '.vob',
    '.asf',
    '.divx',
    '.rm',
    '.rmvb',
    '.mxf',
  };

  static bool isPlayable(String path) {
    final ext = p.extension(path).toLowerCase();
    return audioExtensions.contains(ext) || videoExtensions.contains(ext);
  }

  /// `.ts` is the one extension two worlds share: MPEG transport streams and
  /// TypeScript. A real transport stream is 0x47 sync bytes every 188 bytes;
  /// anything else (a Downloads folder with one node project in it would add
  /// thousands of "videos" to the library) is rejected.
  static bool _looksLikeMpegTs(String path) {
    try {
      final raf = File(path).openSync();
      try {
        final bytes = raf.readSync(188 * 2 + 1);
        return bytes.length > 188 * 2 &&
            bytes[0] == 0x47 &&
            bytes[188] == 0x47 &&
            bytes[188 * 2] == 0x47;
      } finally {
        raf.closeSync();
      }
    } catch (_) {
      return false;
    }
  }

  static Future<List<Track>> scan(List<String> folders) {
    final roots = List<String>.from(folders);
    return Isolate.run(() => scanSync(roots));
  }

  static List<Track> scanSync(List<String> folders) {
    final seen = <String>{};
    final tracks = <Track>[];

    for (final folder in folders) {
      _walk(Directory(folder), (file) {
        if (!isPlayable(file.path) || !seen.add(file.path)) return;
        if (p.extension(file.path).toLowerCase() == '.ts' &&
            !_looksLikeMpegTs(file.path)) {
          return;
        }
        tracks.add(trackFor(file.path));
      });
    }

    // The library reads like WMP's did: by artist, then album, then track
    // order within the album.
    tracks.sort((a, b) {
      final byArtist = a.artistLabel.toLowerCase().compareTo(
        b.artistLabel.toLowerCase(),
      );
      if (byArtist != 0) return byArtist;
      final byAlbum = a.albumLabel.toLowerCase().compareTo(
        b.albumLabel.toLowerCase(),
      );
      if (byAlbum != 0) return byAlbum;
      final byNumber = (a.trackNumber ?? 1 << 20) - (b.trackNumber ?? 1 << 20);
      if (byNumber != 0) return byNumber;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return tracks;
  }

  /// A single file dropped in from Open — same tag treatment as the scan.
  static Track trackFor(String path) {
    final ext = p.extension(path).toLowerCase();
    final fallbackTitle = p.basenameWithoutExtension(path);

    if (videoExtensions.contains(ext)) {
      return Track(path: path, title: fallbackTitle, isVideo: true);
    }

    try {
      final meta = readMetadata(File(path));
      final title = meta.title?.trim();
      final artist = meta.artist?.trim();
      final album = meta.album?.trim();
      return Track(
        path: path,
        title: (title == null || title.isEmpty) ? fallbackTitle : title,
        artist: (artist == null || artist.isEmpty) ? null : artist,
        album: (album == null || album.isEmpty) ? null : album,
        duration: meta.duration,
        trackNumber: meta.trackNumber,
      );
    } catch (_) {
      // Unreadable or exotic tags: the file is still playable.
      return Track(path: path, title: fallbackTitle);
    }
  }

  static void _walk(Directory dir, void Function(File) onFile) {
    List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } catch (_) {
      return; // Unreadable directory: skip, don't abort the scan.
    }
    for (final entry in entries) {
      final name = p.basename(entry.path);
      if (name.startsWith('.')) continue;
      if (entry is Directory) {
        _walk(entry, onFile);
      } else if (entry is File) {
        onFile(entry);
      }
    }
  }
}

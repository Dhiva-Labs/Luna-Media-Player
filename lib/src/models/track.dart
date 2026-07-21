/// One playable item in the library or queue.
///
/// Plain and sendable: the scanner builds these inside an isolate.
class Track {
  const Track({
    required this.path,
    required this.title,
    this.artist,
    this.album,
    this.duration,
    this.trackNumber,
    this.isVideo = false,
  });

  final String path;
  final String title;
  final String? artist;
  final String? album;
  final Duration? duration;
  final int? trackNumber;

  /// Video files play in the Now Playing area instead of a visualisation.
  final bool isVideo;

  String get artistLabel => artist ?? 'Unknown artist';
  String get albumLabel => album ?? 'Unknown album';

  @override
  bool operator ==(Object other) => other is Track && other.path == path;

  @override
  int get hashCode => path.hashCode;
}

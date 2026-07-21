import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app_info.dart';
import 'src/models/track.dart';
import 'src/services/library_scanner.dart';
import 'src/state/player_state.dart';
import 'src/ui/main_window.dart';
import 'src/ui/wmp_theme.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  // No explicit libmpv path: the media_kit_video plugin already links
  // libmpv.so.2, so dlopen-by-soname reuses that copy. Passing a file path
  // here loaded a SECOND libmpv into the process, and creating a video
  // render context across two copies aborts inside mpv
  // (m_config_cache_from_shadow assert).
  MediaKit.ensureInitialized();
  await windowManager.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  const options = WindowOptions(
    size: Size(1150, 740),
    minimumSize: Size(900, 600),
    center: true,
    title: AppInfo.name,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: LunaMediaPlayerApp(launchPaths: arguments),
    ),
  );
}

class LunaMediaPlayerApp extends ConsumerStatefulWidget {
  const LunaMediaPlayerApp({super.key, this.launchPaths = const []});

  /// Files and folders named on the command line — by the file manager's
  /// "Open With", or by `luna-media-player song.mp3`.
  final List<String> launchPaths;

  @override
  ConsumerState<LunaMediaPlayerApp> createState() => _LunaMediaPlayerAppState();
}

class _LunaMediaPlayerAppState extends ConsumerState<LunaMediaPlayerApp> {
  @override
  void initState() {
    super.initState();
    // Deliberately after the first frame, and never awaited before runApp:
    // reading tags is synchronous file IO, and the window must come up first.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openLaunchPaths());
  }

  Future<void> _openLaunchPaths() async {
    final paths = widget.launchPaths.where((a) => !a.startsWith('-')).toList();
    if (paths.isEmpty) return;

    final tracks = await Isolate.run(() {
      final found = <Track>[];
      for (final path in paths) {
        if (Directory(path).existsSync()) {
          found.addAll(LibraryScanner.scanSync([path]));
        } else if (File(path).existsSync() && LibraryScanner.isPlayable(path)) {
          found.add(LibraryScanner.trackFor(path));
        }
      }
      return found;
    });

    if (!mounted || tracks.isEmpty) return;
    ref.read(playbackProvider.notifier).playQueue(tracks);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: Wmp.theme(),
      home: const MainWindow(),
    );
  }
}

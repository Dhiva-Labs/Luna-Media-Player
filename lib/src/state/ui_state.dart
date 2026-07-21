import 'package:flutter_riverpod/legacy.dart';

/// The feature taskbar tabs, as WMP 10 had them across the top.
enum AppTab {
  nowPlaying('Now Playing'),
  library('Library');

  const AppTab(this.label);
  final String label;
}

final appTabProvider = StateProvider<AppTab>((_) => AppTab.nowPlaying);

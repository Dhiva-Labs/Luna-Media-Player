import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/visualizer_style.dart';
import '../state/player_state.dart';
import 'blue_bars.dart';
import 'visualizer/visualizer.dart';
import 'wmp_theme.dart';

/// The Now Playing screen: the blue options toolbar, the black stage —
/// visualisation for audio, the picture for video — and the light blue
/// Now Playing List pane on the right.
class NowPlayingView extends ConsumerWidget {
  const NowPlayingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vizStyle = ref.watch(visualizerStyleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlueToolbar(
          children: [
            BlueBarButton(
              label: 'Now Playing Options',
              dropdown: true,
              menuItems: [
                for (final style in VisualizerStyle.values)
                  blueMenuItem(
                    style == vizStyle
                        ? '●  ${style.label}'
                        : '    ${style.label}',
                    () => ref.read(visualizerStyleProvider.notifier).set(style),
                  ),
              ],
            ),
            const Spacer(),
            const BlueBarButton(label: 'Now Playing List', dropdown: true),
          ],
        ),
        const Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _Stage()),
              NowPlayingListPane(),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stage extends ConsumerWidget {
  const _Stage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(playbackProvider.select((s) => s.current));
    final playing = ref.watch(isPlayingProvider).value ?? false;
    final style = ref.watch(visualizerStyleProvider);
    final art = ref.watch(currentArtProvider).value;

    final isVideo = current?.isVideo ?? false;

    return ColoredBox(
      color: Wmp.stage,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isVideo)
            Video(
              controller: ref.watch(videoControllerProvider),
              controls: NoVideoControls,
              fill: Wmp.stage,
            )
          else
            Visualizer(
              style: style,
              isPlaying: playing,
              primary: Wmp.vizPrimary,
              secondary: Wmp.vizSecondary,
              onCycle: () => ref.read(visualizerStyleProvider.notifier).cycle(),
            ),

          // Track caption, bottom left — gold on black, as WMP captioned it.
          if (current != null)
            Positioned(
              left: 14,
              bottom: 34,
              right: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (art != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Image.memory(
                          art,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          current.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Wmp.stageCaption,
                            fontFamilyFallback: Wmp.fontFallback,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 4),
                            ],
                          ),
                        ),
                        if (!current.isVideo)
                          Text(
                            '${current.artistLabel} — ${current.albumLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.white70,
                              fontFamilyFallback: Wmp.fontFallback,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 4),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // The visualisation switcher, bottom centre — WMP's little arrows.
          if (!isVideo)
            Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _VizArrow(
                    icon: Icons.chevron_left,
                    onTap: () =>
                        ref.read(visualizerStyleProvider.notifier).cycleBack(),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 110,
                    child: Text(
                      style.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                        fontFamilyFallback: Wmp.fontFallback,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _VizArrow(
                    icon: Icons.chevron_right,
                    onTap: () =>
                        ref.read(visualizerStyleProvider.notifier).cycle(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _VizArrow extends StatelessWidget {
  const _VizArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 18, color: Colors.white54),
    );
  }
}

/// The light blue Now Playing List pane — shared by the Now Playing screen
/// and the library, exactly as WMP 10 kept it docked on the right.
class NowPlayingListPane extends ConsumerWidget {
  const NowPlayingListPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);

    final totalTime = playback.queue.fold<Duration>(
      Duration.zero,
      (sum, t) => sum + (t.duration ?? Duration.zero),
    );

    return Container(
      width: 210,
      decoration: const BoxDecoration(
        color: Wmp.listPane,
        border: Border(left: BorderSide(color: Color(0xFF9FBBDD))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Wmp.listPaneHeader,
            child: Row(
              children: [
                const Text(
                  'Now Playing List',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Wmp.listPaneText,
                    fontFamilyFallback: Wmp.fontFallback,
                  ),
                ),
                const Spacer(),
                Text(
                  '${playback.queue.length}',
                  style: const TextStyle(fontSize: 11, color: Wmp.listPaneText),
                ),
              ],
            ),
          ),
          Expanded(
            child: playback.queue.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'Double-click an item in the Library to build a list '
                        'of items to play.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Wmp.listPaneText,
                          height: 1.5,
                          fontFamilyFallback: Wmp.fontFallback,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: playback.queue.length,
                    itemExtent: 20,
                    itemBuilder: (context, i) {
                      final track = playback.queue[i];
                      return _PlaylistRow(
                        title: track.title,
                        duration: track.duration,
                        isCurrent: i == playback.index,
                        onPlay: () =>
                            ref.read(playbackProvider.notifier).playAt(i),
                      );
                    },
                  ),
          ),
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerRight,
            child: Text(
              'Total Time: ${formatDuration(totalTime)}',
              style: const TextStyle(
                fontSize: 11,
                color: Wmp.listPaneText,
                fontFamilyFallback: Wmp.fontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistRow extends StatefulWidget {
  const _PlaylistRow({
    required this.title,
    required this.duration,
    required this.isCurrent,
    required this.onPlay,
  });

  final String title;
  final Duration? duration;
  final bool isCurrent;
  final VoidCallback onPlay;

  @override
  State<_PlaylistRow> createState() => _PlaylistRowState();
}

class _PlaylistRowState extends State<_PlaylistRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onDoubleTap: widget.onPlay,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: widget.isCurrent
              ? const Color(0xFFBBD4F2)
              : _hover
              ? const Color(0xFFCFE1F6)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              if (widget.isCurrent)
                const Padding(
                  padding: EdgeInsets.only(right: 3),
                  child: Icon(
                    Icons.play_arrow,
                    size: 11,
                    color: Color(0xFF2FA32F),
                  ),
                ),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Wmp.listPaneText,
                    fontWeight: widget.isCurrent
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontFamilyFallback: Wmp.fontFallback,
                  ),
                ),
              ),
              Text(
                formatDuration(widget.duration),
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF5B72A8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

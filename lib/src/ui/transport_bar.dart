import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/player_state.dart';
import 'wmp_theme.dart';

/// WMP 10's transport: a pale blue-silver band with round glass buttons on
/// the left — play, stop, previous, next — the speaker and its famous green
/// volume slider, then the seek channel running out to the right.
class TransportBar extends ConsumerWidget {
  const TransportBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);
    final playing = ref.watch(isPlayingProvider).value ?? false;
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = ref.watch(durationProvider).value ?? Duration.zero;
    final volume = ref.watch(volumeProvider).value ?? 80.0;
    final notifier = ref.read(playbackProvider.notifier);

    return Container(
      height: 54,
      decoration: const BoxDecoration(
        gradient: Wmp.transportGradient,
        border: Border(top: BorderSide(color: Colors.white)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          _GlassButton(
            size: 36,
            icon: playing ? Icons.pause : Icons.play_arrow,
            tooltip: playing ? 'Pause' : 'Play',
            onTap: notifier.togglePlayPause,
          ),
          const SizedBox(width: 5),
          _GlassButton(
            size: 26,
            icon: Icons.stop,
            tooltip: 'Stop',
            onTap: notifier.stop,
          ),
          const SizedBox(width: 8),
          _GlassButton(
            size: 26,
            icon: Icons.fast_rewind,
            tooltip: 'Previous',
            onTap: notifier.previous,
          ),
          const SizedBox(width: 4),
          _GlassButton(
            size: 26,
            icon: Icons.fast_forward,
            tooltip: 'Next',
            onTap: notifier.next,
          ),
          const SizedBox(width: 10),
          _FlatToggle(
            icon: Icons.shuffle,
            active: playback.shuffle,
            tooltip: 'Shuffle',
            onTap: notifier.toggleShuffle,
          ),
          _FlatToggle(
            icon: playback.repeat == RepeatMode.one
                ? Icons.repeat_one
                : Icons.repeat,
            active: playback.repeat != RepeatMode.off,
            tooltip: playback.repeat.label,
            onTap: notifier.cycleRepeat,
          ),
          const SizedBox(width: 8),
          _GlassButton(
            size: 24,
            icon: volume <= 0 ? Icons.volume_off : Icons.volume_up,
            tooltip: volume <= 0 ? 'Unmute' : 'Mute',
            onTap: notifier.toggleMute,
          ),
          const SizedBox(width: 2),
          // The green volume slider.
          SizedBox(
            width: 86,
            child: _WmpSlider(
              value: volume.clamp(0.0, 100.0),
              max: 100,
              fill: Wmp.volumeFill,
              onChanged: notifier.setVolume,
            ),
          ),
          const SizedBox(width: 14),
          // The seek channel takes the rest of the bar.
          Expanded(
            child: _WmpSlider(
              value: duration.inMilliseconds == 0
                  ? 0
                  : (position.inMilliseconds / duration.inMilliseconds).clamp(
                      0.0,
                      1.0,
                    ),
              max: 1,
              fill: Wmp.seekFill,
              onChanged: duration.inMilliseconds == 0
                  ? null
                  : (v) => notifier.seek(
                      Duration(
                        milliseconds: (v * duration.inMilliseconds).round(),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: Text(
              duration.inMilliseconds == 0
                  ? '--:-- / --:--'
                  : '${formatDuration(position)} / ${formatDuration(duration)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                color: Wmp.glyph,
                fontFamilyFallback: Wmp.fontFallback,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A recessed XP slider channel with a silver round thumb.
class _WmpSlider extends StatelessWidget {
  const _WmpSlider({
    required this.value,
    required this.max,
    required this.fill,
    required this.onChanged,
  });

  final double value;
  final double max;
  final Color fill;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: fill,
        inactiveTrackColor: Wmp.seekChannel,
        disabledActiveTrackColor: Wmp.seekChannel,
        disabledInactiveTrackColor: Wmp.seekChannel,
        trackShape: const _ChannelTrackShape(),
        thumbColor: const Color(0xFFF2F7FC),
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 7,
          disabledThumbRadius: 0,
          elevation: 1,
        ),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(value: value, max: max, onChanged: onChanged),
    );
  }
}

/// The groove: a rounded channel with a hairline border, like XP drew.
class _ChannelTrackShape extends RoundedRectSliderTrackShape {
  const _ChannelTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      secondaryOffset: secondaryOffset,
      isDiscrete: isDiscrete,
      isEnabled: isEnabled,
      additionalActiveTrackHeight: 0,
    );
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Wmp.glassBorder,
    );
  }
}

/// A round silver-glass button with a navy glyph — the WMP 10 control.
class _GlassButton extends StatefulWidget {
  const _GlassButton({
    required this.size,
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final double size;
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.45),
                colors: _hover
                    ? const [Colors.white, Color(0xFFE9F3FD), Color(0xFFBAD4EE)]
                    : const [
                        Colors.white,
                        Color(0xFFDCEAF8),
                        Color(0xFFA9C6E6),
                      ],
                stops: const [0.0, 0.55, 1.0],
              ),
              border: Border.all(color: Wmp.glassBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x334A6EA0),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              size: widget.size * 0.58,
              color: Wmp.glyph,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shuffle and repeat: small flat navy icons that press in when active.
class _FlatToggle extends StatelessWidget {
  const _FlatToggle({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: active ? const Color(0xFFCADFF5) : Colors.transparent,
            border: Border.all(
              color: active ? Wmp.glassBorder : Colors.transparent,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: active ? Wmp.glyph : const Color(0xFF6B84B4),
          ),
        ),
      ),
    );
  }
}

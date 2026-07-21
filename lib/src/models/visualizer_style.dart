/// The visualisations, named after the Windows Media Player presets they are
/// modelled on.
///
/// Each one leans on a different part of the signal — the bar styles read the
/// spectrum, the scope styles read the waveform.
enum VisualizerStyle {
  // The flowing ones. These are what WMP on XP actually felt like: a continuous
  // field that never resets, more like a video than a chart. They rely on the
  // trail buffer — each frame is drawn over a faded copy of the last, which is
  // where the smearing, liquid quality comes from.
  ambience('Ambience', 'Flowing plasma that never repeats', flows: true),
  alchemy('Alchemy', 'Ribbons winding around each other', flows: true),
  plenty('Plenty', 'A drifting particle flow field', flows: true),

  // The Bars and Waves / Battery families.
  bars('Bars', 'The classic spectrum'),
  oceanMist('Ocean Mist', 'Mirrored bars with a drifting swell'),
  scope('Scope', 'An oscilloscope trace of the waveform'),
  battery('Battery', 'Spikes radiating from the centre'),
  fireStorm('Fire Storm', 'A burning spectrum');

  const VisualizerStyle(this.label, this.description, {this.flows = false});

  final String label;
  final String description;

  /// Whether this style is a full-bleed flowing field rather than a strip of
  /// bars.
  final bool flows;

  VisualizerStyle get next =>
      VisualizerStyle.values[(index + 1) % VisualizerStyle.values.length];

  VisualizerStyle get previous =>
      VisualizerStyle.values[(index - 1 + VisualizerStyle.values.length) %
          VisualizerStyle.values.length];
}

/// One frame of signal for the painters: spectrum bands plus a waveform.
class VisualizerFrame {
  const VisualizerFrame({required this.bands, required this.wave});

  /// Per-band magnitudes, 0..1, low frequency first.
  final List<double> bands;

  /// Samples normalised to -1..1.
  final List<double> wave;

  static const int bandCount = 24;
  static const int wavePoints = 96;

  static VisualizerFrame silent = VisualizerFrame(
    bands: List.filled(bandCount, 0),
    wave: List.filled(wavePoints, 0),
  );
}

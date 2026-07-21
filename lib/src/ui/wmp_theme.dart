import 'package:flutter/material.dart';

/// Windows Media Player 10 on XP, taken from the real thing: pale Luna-blue
/// chrome, royal-blue toolbars, white content with blue text, and glass
/// buttons in silver and navy.
abstract final class Wmp {
  // ── Chrome ────────────────────────────────────────────────────────────
  /// The pale blue title bar.
  static const titleBarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEAF2FC), Color(0xFFD2E2F5), Color(0xFFC0D6EF)],
    stops: [0.0, 0.55, 1.0],
  );

  static const chromeBorder = Color(0xFF7A9CC8);
  static const titleText = Color(0xFF1E3287);

  /// The feature-taskbar strip behind the tabs.
  static const taskbarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFD5E4F6), Color(0xFFB6CEEA)],
  );

  /// The active tab's white face, shared with the toolbar it merges into.
  static const activeTab = Color(0xFFF7FAFE);
  static const tabText = Color(0xFF16337F);
  static const tabBorder = Color(0xFF8FB0D4);

  // ── Royal blue bars (sub-toolbar and status strip) ────────────────────
  static const toolbarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6379D6), Color(0xFF4A5CC0), Color(0xFF3D4FB2)],
    stops: [0.0, 0.6, 1.0],
  );

  static const statusGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF5A6ECC), Color(0xFF3D4FB2)],
  );

  // ── Content ───────────────────────────────────────────────────────────
  static const content = Colors.white;

  /// WMP 10 set its library text in blue, not black.
  static const itemText = Color(0xFF2444B0);
  static const itemTextDim = Color(0xFF7A8BC8);
  static const headerText = Color(0xFF333333);
  static const gridLine = Color(0xFFE4E8F0);
  static const rowSelected = Color(0xFFCBE0F7);
  static const rowHover = Color(0xFFE4EEFA);

  /// The light blue "Now Playing List" pane.
  static const listPane = Color(0xFFD9E7F8);
  static const listPaneHeader = Color(0xFFC3D7F0);
  static const listPaneText = Color(0xFF1E3287);

  // ── The stage ─────────────────────────────────────────────────────────
  static const stage = Color(0xFF000000);
  static const stageCaption = Color(0xFFF5C242);

  // ── Transport ─────────────────────────────────────────────────────────
  static const transportGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEDF4FC), Color(0xFFD3E3F4), Color(0xFFBAD2EC)],
    stops: [0.0, 0.5, 1.0],
  );

  static const glyph = Color(0xFF1E3C8C);
  static const glassBorder = Color(0xFF7FA3CC);
  static const seekChannel = Color(0xFFAEC7E4);
  static const seekFill = Color(0xFF3B6ED0);

  /// The famous green volume slider.
  static const volumeFill = Color(0xFF43B93C);

  // ── Visualisations ────────────────────────────────────────────────────
  static const vizPrimary = Color(0xFF2F84D0);
  static const vizSecondary = Color(0xFFFFD34E);

  static const fontFallback = [
    'Tahoma',
    'Verdana',
    'DejaVu Sans',
    'Liberation Sans',
  ];

  static ThemeData theme() {
    const scheme = ColorScheme.light(
      primary: Color(0xFF316AC5),
      secondary: itemText,
      surface: content,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: content,
      textTheme: base.textTheme.apply(
        fontFamilyFallback: fontFallback,
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
      // XP menus: white, hairline border, blue selection.
      popupMenuTheme: const PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(side: BorderSide(color: chromeBorder)),
        textStyle: TextStyle(
          fontSize: 12.5,
          color: Colors.black,
          fontFamilyFallback: fontFallback,
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 600),
        textStyle: TextStyle(fontSize: 11.5, color: Colors.black),
        decoration: BoxDecoration(
          color: Color(0xFFFFFFE1), // the XP tooltip yellow
          border: Border.fromBorderSide(BorderSide(color: Colors.black54)),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: const WidgetStatePropertyAll(Color(0xFFB7CDE8)),
        trackColor: const WidgetStatePropertyAll(Color(0xFFF0F5FB)),
        thickness: const WidgetStatePropertyAll(12),
        radius: const Radius.circular(3),
      ),
    );
  }
}

String formatDuration(Duration? d) {
  if (d == null) return '--:--';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

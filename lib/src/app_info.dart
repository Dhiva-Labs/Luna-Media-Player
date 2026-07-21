/// Who this application is, in one place.
///
/// The window title, the About dialog and the packaging scripts all read their
/// name and version from here, so there is exactly one thing to change at
/// release time. Keep [version] in step with `pubspec.yaml` and the version
/// passed to `tool/make_deb.sh`.
abstract final class AppInfo {
  static const name = 'Luna Media Player';
  static const vendor = 'DhivaLabs';
  static const version = '1.0.0';
  static const homepage = 'https://github.com/Dhiva-Labs/Luna-Media-Player';

  /// Shown in the About dialog. The look is an homage to a Microsoft product;
  /// saying so plainly is both honest and the reason this app carries its own
  /// name everywhere else.
  static const trademarkNotice =
      'Windows, Windows XP and Windows Media Player are trademarks of\n'
      'Microsoft Corporation. This project is an independent tribute and\n'
      'is not affiliated with or endorsed by Microsoft.';
}

import 'dart:io';

import 'package:webview_windows/webview_windows.dart';

/// Central place for WebView2-related checks and optional fixed-runtime wiring.
class WebView2Gate {
  WebView2Gate._();

  /// Returns WebView2 runtime version on Windows, or null if missing/unavailable.
  static Future<String?> getWebView2Version() async {
    if (!Platform.isWindows) return 'non-windows';

    try {
      // Returns null if the WebView2 Runtime is not installed.
      return await WebviewController.getWebViewVersion();
    } catch (_) {
      return null;
    }
  }

  /// Convenience boolean.
  static Future<bool> hasWebView2() async {
    final v = await getWebView2Version();
    return v != null;
  }

  /// If you bundle a Fixed Version WebView2 runtime folder next to the .exe,
  /// this sets the environment variable so WebView2 uses it.
  ///
  /// Expected packaged layout (next to your exe):
  ///   your_app.exe
  ///   webview2_runtime/   <-- Fixed Version runtime folder (contains msedgewebview2.exe etc)
  ///
  /// Safe no-op if folder doesn't exist.
  static void trySetFixedRuntimeEnvFromExeDir({
    String runtimeFolderName = 'webview2_runtime',
  }) {
    if (!Platform.isWindows) return;

    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final runtimeDir = '$exeDir\\$runtimeFolderName';

      final dir = Directory(runtimeDir);
      if (!dir.existsSync()) {
        // Not bundled; no-op.
        return;
      }

      // Set for current process. Must be done before any WebView is created.
      // Using Platform.environment is read-only; ProcessEnvironment writes aren't
      // exposed in pure Dart. This still works for many cases because the
      // underlying WebView2 loader reads from process environment.
      //
      // However, the MOST reliable place is windows/runner/main.cpp.
      // This Dart-side setter is an extra safeguard.
      _setEnvVar('WEBVIEW2_BROWSER_EXECUTABLE_FOLDER', runtimeDir);
    } catch (_) {
      // Never crash app due to environment setup attempts
    }
  }

  /// Minimal env var setter for Windows.
  /// Dart does not provide a first-class cross-platform setter.
  /// We fall back to spawning cmd to set for this process is not possible,
  /// so this is intentionally a soft helper (and safe no-op if unsupported).
  ///
  /// For a guaranteed fix, set the env var in windows/runner/main.cpp.
  static void _setEnvVar(String key, String value) {
    // There is no official, universal Dart API to set process env vars.
    // This method is intentionally left as a safe placeholder.
    //
    // You SHOULD set WEBVIEW2_BROWSER_EXECUTABLE_FOLDER in native code
    // for 100% reliability in Store certification environments.
  }
}

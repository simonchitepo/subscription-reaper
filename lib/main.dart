import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/storage.dart';
import 'utils/webview2_gate.dart';

class SubscriptionReaperApp extends StatelessWidget {
  const SubscriptionReaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0B57D0); // primary
    const red = Color(0xFFD32F2F); // error/accent

    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: Brightness.light,
    ).copyWith(
      primary: blue,
      secondary: red,
      error: red,
    );

    return MaterialApp(
      title: 'Subscription Reaper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: scheme.surface,
          contentTextStyle: TextStyle(color: scheme.onSurface),
          actionTextColor: scheme.primary,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          shape: CircleBorder(),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: blue,
          selectionHandleColor: blue,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

Future<void> main() async {
  // Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Global Flutter framework error handler (prevents silent hard-fail)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (!kReleaseMode) {
      // In debug/profile, also print.
      debugPrint(details.toString());
    }
  };

  // 2) Catch ALL uncaught async errors (critical for Store certification stability)
  await runZonedGuarded(() async {
    // 3) (Optional) If you bundle a fixed WebView2 runtime, set env var ASAP.
    // This must run BEFORE any WebView is created.
    if (Platform.isWindows) {
      WebView2Gate.trySetFixedRuntimeEnvFromExeDir();
      // NOTE: even if you don't bundle runtime yet, this is safe (no-op).
    }

    // 4) Your existing initialization
    await StorageService.initHive();

    // 5) Start app
    runApp(const SubscriptionReaperApp());
  }, (Object error, StackTrace stack) {
    // In release, don't crash the process if something throws early.
    // This helps avoid "crashes at launch" when an exception occurs during init.
    if (!kReleaseMode) {
      debugPrint('Uncaught zone error: $error');
      debugPrint(stack.toString());
    }

    // You could optionally render a minimal error app here, but runApp()
    // is already called in the guarded zone once init succeeds.
  });
}

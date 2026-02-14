import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

class WindowsAdBanner extends StatefulWidget {
  final String adUrl;
  final double height;

  const WindowsAdBanner({
    super.key,
    required this.adUrl,
    this.height = 100,
  });

  @override
  State<WindowsAdBanner> createState() => _WindowsAdBannerState();
}

class _WindowsAdBannerState extends State<WindowsAdBanner> {
  final _controller = WebviewController();
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();

      // Optional: basic settings
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      // Load your hosted ad page
      await _controller.loadUrl(widget.adUrl);

      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // Fail gracefully in production. You can hide it or show a placeholder.
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'Ad failed to load',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    if (!_ready) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Webview(_controller),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

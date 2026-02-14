import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

import '../models/subscription.dart';
import '../services/storage.dart';
import '../widgets/windows_ad_banner.dart';

class WebCancelAssistantScreen extends StatefulWidget {
  final String subscriptionId;
  final String initialUrl;

  const WebCancelAssistantScreen({
    super.key,
    required this.subscriptionId,
    required this.initialUrl,
  });

  @override
  State<WebCancelAssistantScreen> createState() => _WebCancelAssistantScreenState();
}

class _WebCancelAssistantScreenState extends State<WebCancelAssistantScreen> {
  final WebviewController _controller = WebviewController();

  bool _ready = false;
  bool _recording = false;
  bool _playing = false;
  bool _showClearOverlay = false;

  // WebView2 availability gate (prevents Store certification "crash at launch")
  bool _webView2Checked = false;
  String? _webView2Version; // null = missing

  final List<FlowStep> _steps = <FlowStep>[];

  static const String _windowsAdUrl = 'https://cyph3r.live/ads/windows_banner.html';
  static const double _adHeight = 100;

  // Keep ads OFF until we know WebView2 exists (ads use WebView too).
  bool get _showAds => _webView2Version != null;

  @override
  void initState() {
    super.initState();

    final s = StorageService.getById(widget.subscriptionId);
    final existing = s?.flow?.steps ?? const <FlowStep>[];
    _steps.addAll(existing);

    _init();
  }

  Future<void> _init() async {
    // 1) Check WebView2 runtime on Windows BEFORE initializing any WebView
    await _checkWebView2();

    // 2) If missing, do not initialize WebviewController (avoids hard crash)
    if (!mounted) return;
    if (Platform.isWindows && _webView2Version == null) {
      setState(() {
        _webView2Checked = true;
        _ready = false;
      });
      return;
    }

    // 3) Safe to initialize controller + load URL
    await _initWebView();
  }

  Future<void> _checkWebView2() async {
    if (!Platform.isWindows) {
      // Not needed on other platforms
      _webView2Checked = true;
      _webView2Version = 'non-windows';
      return;
    }

    try {
      // Returns null when WebView2 runtime is not installed
      final v = await WebviewController.getWebViewVersion();
      _webView2Version = v;
    } catch (_) {
      _webView2Version = null;
    }

    if (mounted) {
      setState(() {
        _webView2Checked = true;
      });
    }
  }

  Future<void> _initWebView() async {
    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.white);
      await _controller.loadUrl(widget.initialUrl);

      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      // If something still goes wrong, show a safe error UI instead of crashing.
      if (!mounted) return;
      setState(() {
        _ready = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Web view failed to start: $e')),
      );
    }
  }

  Future<void> _saveFlow() async {
    final s = StorageService.getById(widget.subscriptionId);
    if (s == null) return;

    s.flow = CancellationFlow(steps: List<FlowStep>.from(_steps));
    await StorageService.upsertSubscription(s);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved ${_steps.length} steps')),
    );
  }

  Future<void> _toggleRecording() async {
    if (!_ready) return;

    setState(() => _recording = !_recording);

    if (_recording) {
      await _injectRecorder();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording ON')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording OFF')),
      );
    }
  }

  Future<void> _injectRecorder() async {
    const js = r"""
window.__reaperEvents = [];

function cssPath(el) {
  if (!(el instanceof Element)) return '';
  const path = [];
  while (el && el.nodeType === Node.ELEMENT_NODE) {
    let selector = el.nodeName.toLowerCase();
    if (el.id) {
      selector += '#' + el.id;
      path.unshift(selector);
      break;
    } else {
      let sib = el, nth = 1;
      while ((sib = sib.previousElementSibling)) {
        if (sib.nodeName.toLowerCase() === selector) nth++;
      }
      selector += ':nth-of-type(' + nth + ')';
    }
    path.unshift(selector);
    el = el.parentElement;
  }
  return path.join(' > ');
}

document.addEventListener('click', function(e) {
  const sel = cssPath(e.target);
  window.__reaperEvents.push({type:'click', selector: sel});
}, true);

document.addEventListener('change', function(e) {
  const t = e.target;
  const tag = (t.tagName || '').toLowerCase();
  if (tag === 'input' || tag === 'textarea' || tag === 'select') {
    window.__reaperEvents.push({
      type:'input',
      selector: cssPath(t),
      value: t.value
    });
  }
}, true);
""";

    await _controller.executeScript(js);
    _pollEvents();
  }

  Future<void> _pollEvents() async {
    while (_recording && mounted) {
      final result =
      await _controller.executeScript("JSON.stringify(window.__reaperEvents.splice(0));");

      if (result != null && result.isNotEmpty) {
        try {
          final list = jsonDecode(result);
          for (final map in list) {
            final type = map['type'];
            final sel = map['selector'];

            if (type == 'click') {
              _steps.add(FlowStep.scrollIntoView(sel));
              _steps.add(FlowStep.click(sel));
            } else if (type == 'input') {
              _steps.add(FlowStep.scrollIntoView(sel));
              _steps.add(FlowStep.input(sel, map['value']));
            }
          }
          if (mounted) setState(() {});
        } catch (_) {
          // ignore malformed results
        }
      }

      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  Future<void> _play() async {
    if (!_ready) return;

    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No steps')),
      );
      return;
    }

    setState(() => _playing = true);

    for (final step in _steps) {
      switch (step.type) {
        case FlowActionType.wait:
          await Future.delayed(Duration(milliseconds: step.waitMs ?? 0));
          break;

        case FlowActionType.scrollIntoView:
          await _controller.executeScript(
            "try{document.querySelector(${jsonEncode(step.selector)}).scrollIntoView({behavior:'smooth',block:'center'});}catch(e){}",
          );
          break;

        case FlowActionType.click:
          await _controller.executeScript(
            "try{document.querySelector(${jsonEncode(step.selector)}).click();}catch(e){}",
          );
          break;

        case FlowActionType.input:
          await _controller.executeScript("""
try{
const el=document.querySelector(${jsonEncode(step.selector)});
if(el){
el.value=${jsonEncode(step.value ?? '')};
el.dispatchEvent(new Event('input',{bubbles:true}));
el.dispatchEvent(new Event('change',{bubbles:true}));
}
}catch(e){}
""");
          break;
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (mounted) setState(() => _playing = false);
  }

  Widget _bottomAdBar() {
    // Only show ads after WebView2 is confirmed present (ads rely on WebView too).
    if (!_showAds) return const SizedBox.shrink();

    return SizedBox(
      height: _adHeight,
      child: WindowsAdBanner(
        adUrl: _windowsAdUrl,
        height: _adHeight,
      ),
    );
  }

  Widget _missingWebView2Screen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Web Cancel Assistant')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 52),
              const SizedBox(height: 12),
              const Text(
                'Microsoft Edge WebView2 Runtime is not available.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'This screen requires WebView2 to open subscription cancellation pages.\n\n'
                    'Install “Microsoft Edge WebView2 Runtime” and reopen the app.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Detected: ${_webView2Version ?? "not installed"}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // While checking runtime (especially on Windows), show a spinner.
    if (!_webView2Checked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If missing on Windows, never attempt to create/paint Webview().
    if (Platform.isWindows && _webView2Version == null) {
      return _missingWebView2Screen();
    }

    // If runtime exists but controller not ready yet
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Web Cancel Assistant'),
        actions: [
          IconButton(
            onPressed: _playing ? null : _toggleRecording,
            icon: Icon(_recording ? Icons.stop : Icons.fiber_manual_record),
          ),
          IconButton(
            onPressed: _playing ? null : _play,
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            onPressed: _saveFlow,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: Webview(_controller)),
          _bottomAdBar(),
        ],
      ),
    );
  }
}

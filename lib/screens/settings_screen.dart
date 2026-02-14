import 'package:flutter/material.dart';

import '../widgets/windows_ad_banner.dart';

class HomeSettings {
  final bool includeInactiveInTotals;
  final bool showInactiveSection;
  final bool warnForPriceNotSet;

  const HomeSettings({
    required this.includeInactiveInTotals,
    required this.showInactiveSection,
    required this.warnForPriceNotSet,
  });

  HomeSettings copyWith({
    bool? includeInactiveInTotals,
    bool? showInactiveSection,
    bool? warnForPriceNotSet,
  }) {
    return HomeSettings(
      includeInactiveInTotals: includeInactiveInTotals ?? this.includeInactiveInTotals,
      showInactiveSection: showInactiveSection ?? this.showInactiveSection,
      warnForPriceNotSet: warnForPriceNotSet ?? this.warnForPriceNotSet,
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final HomeSettings initial;

  const SettingsScreen({super.key, required this.initial});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late HomeSettings _s;

  // ----------------------------
  // Ads (Windows WebView2)
  // ----------------------------
  static const String _windowsAdUrl = 'https://cyph3r.live/ads/windows_banner.html';
  static const double _adHeight = 100.0;

  bool get _showAds => true;

  @override
  void initState() {
    super.initState();
    _s = widget.initial;
  }

  void _saveAndExit() {
    Navigator.pop(context, _s);
  }

  Widget _bottomAdBar(BuildContext context) {
    if (!_showAds) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Container(
      height: _adHeight,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: WindowsAdBanner(
        adUrl: _windowsAdUrl,
        height: _adHeight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ✅ FIX: make bottomPadding a double (not num)
    final double bottomPadding = (_showAds ? _adHeight : 0.0) + 24.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saveAndExit,
            child: Text(
              'Done',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            // ✅ FIX: use doubles in EdgeInsets too
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, bottomPadding),
            children: [
              Text(
                'Totals',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Include inactive in totals'),
                      subtitle: const Text('If enabled, inactive subscriptions count toward monthly spend.'),
                      value: _s.includeInactiveInTotals,
                      onChanged: (v) =>
                          setState(() => _s = _s.copyWith(includeInactiveInTotals: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'List',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Show Inactive section'),
                      subtitle: const Text('Groups inactive subscriptions under a separate header.'),
                      value: _s.showInactiveSection,
                      onChanged: (v) => setState(() => _s = _s.copyWith(showInactiveSection: v)),
                    ),
                    SwitchListTile(
                      title: const Text('Warn when price is not set'),
                      subtitle: const Text('Shows a small “Fix” indicator when price is 0.'),
                      value: _s.warnForPriceNotSet,
                      onChanged: (v) => setState(() => _s = _s.copyWith(warnForPriceNotSet: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'About',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: const Text('Subscription Reaper'),
                  subtitle: const Text('Polish + filters + settings enabled'),
                  trailing: Icon(Icons.info_outline, color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _bottomAdBar(context),
          ),
        ],
      ),
    );
  }
}

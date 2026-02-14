import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../services/storage.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/windows_ad_banner.dart';
import 'subscription_editor_screen.dart';
import 'web_cancel_assistant_screen.dart';

class SubscriptionDetailScreen extends StatefulWidget {
  final String subscriptionId;

  const SubscriptionDetailScreen({super.key, required this.subscriptionId});

  @override
  State<SubscriptionDetailScreen> createState() => _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  Subscription? _sub;

  // ----------------------------
  // Ads (Windows WebView2)
  // ----------------------------
  static const String _windowsAdUrl = 'https://cyph3r.live/ads/windows_banner.html';
  static const double _adHeight = 100.0;

  // Later you can switch this off for premium users
  bool get _showAds => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _sub = StorageService.getById(widget.subscriptionId));
  }

  Future<void> _edit() async {
    final s = _sub;
    if (s == null) return;

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SubscriptionEditorScreen(existing: s.copy())),
    );

    if (changed == true) {
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.name} updated')),
      );
    }
  }

  Future<void> _delete() async {
    final s = _sub;
    if (s == null) return;

    final ok = await confirmDialog(
      context,
      title: 'Delete subscription?',
      message: 'This will permanently remove "${s.name}".',
      confirmText: 'Delete',
      danger: true,
    );
    if (!ok) return;

    await StorageService.deleteSubscription(s.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${s.name} deleted')),
    );
    Navigator.pop(context, true);
  }

  Future<void> _openCancelAssistant() async {
    final s = _sub;
    if (s == null) return;

    final url = _bestCancellationUrl(s);
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a provider domain or cancellation URL to use the assistant.'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebCancelAssistantScreen(
          subscriptionId: s.id,
          initialUrl: url,
        ),
      ),
    );

    _load();
  }

  String? _bestCancellationUrl(Subscription s) {
    final direct = (s.cancellationUrl ?? '').trim();
    if (direct.isNotEmpty) return _normalizeUrl(direct);

    final domain = (s.providerDomain ?? '').trim();
    if (domain.isNotEmpty) return _normalizeUrl(domain);

    return null;
  }

  String _normalizeUrl(String raw) {
    final v = raw.trim();
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    return 'https://$v';
  }

  int _daysUntil(DateTime dt) {
    final now = DateTime.now();
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(dt.year, dt.month, dt.day);
    return b.difference(a).inDays;
  }

  String _formatDateMMMddyyyy(DateTime dt) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final d = dt.toLocal();
    final m = months[d.month - 1];
    final day = d.day.toString().padLeft(2, '0');
    return '$m $day, ${d.year}';
  }

  String _relativeRenewalText(DateTime next) {
    final days = _daysUntil(next);
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Today';
    if (days == 1) return 'In 1 day';
    return 'In $days days';
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
    final s = _sub;

    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subscription')),
        body: const Center(child: Text('Not found')),
      );
    }

    final priceAndPeriod = '${formatMoney(s.price, s.currency)} · ${periodLabel(s.period)}';
    final nextDate = _formatDateMMMddyyyy(s.nextBillingDate);
    final nextRelative = _relativeRenewalText(s.nextBillingDate);
    final cancelUrl = (s.cancellationUrl ?? '').trim();
    final domain = (s.providerDomain ?? '').trim();
    final hasCancel = cancelUrl.isNotEmpty || domain.isNotEmpty;

    // ✅ FIX: make bottomPadding a double
    final double bottomPadding = (_showAds ? _adHeight : 0.0) + 24.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.name),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            // ✅ FIX: use doubles in EdgeInsets too
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, bottomPadding),
            children: [
              Card(
                elevation: 0,
                color: cs.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Semantics(
                    label:
                    '${s.name}. $priceAndPeriod. Next renewal $nextDate ($nextRelative). ${s.active ? "Subscription active." : "Subscription inactive."}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.subscriptions, color: cs.onPrimaryContainer),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Billing',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.active ? 'Subscription active' : 'Subscription inactive',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            if (!s.active) const _Pill(label: 'Inactive', icon: Icons.pause_circle),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          priceAndPeriod,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.calendar_month, size: 18, color: cs.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Next renewal: $nextDate',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _Pill(label: nextRelative, icon: Icons.schedule),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Tip: inactive subscriptions are excluded from totals.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: hasCancel ? _openCancelAssistant : _edit,
                                icon: const Icon(Icons.public),
                                label: Text(
                                  hasCancel ? 'Cancel via Web Assistant' : 'Add cancellation info',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Provider',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),

              Card(
                child: ListTile(
                  minVerticalPadding: 14,
                  title: const Text('Provider domain'),
                  subtitle: Text(domain.isEmpty ? '—' : domain),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _edit,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
                child: Text(
                  'Used to identify the provider and show its logo.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),

              Card(
                child: ListTile(
                  minVerticalPadding: 14,
                  title: const Text('Cancellation URL'),
                  subtitle: Text(cancelUrl.isEmpty ? '—' : cancelUrl),
                  trailing: cancelUrl.isEmpty ? const Icon(Icons.chevron_right) : const Icon(Icons.link),
                  onTap: _edit,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4),
                child: Text(
                  'Link to the page where you can cancel this subscription.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Cancellation flow',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),

              Card(
                child: ListTile(
                  minVerticalPadding: 14,
                  title: const Text('Recorded steps'),
                  subtitle: Text(
                    s.flow == null ? 'None' : '${s.flow!.steps.length} steps saved',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openCancelAssistant,
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _edit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit subscription'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
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

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Pill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

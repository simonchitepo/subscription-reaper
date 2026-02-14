import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../services/storage.dart';
import '../utils/format.dart';
import '../widgets/windows_ad_banner.dart';
import 'settings_screen.dart';
import 'subscription_detail_screen.dart';
import 'subscription_editor_screen.dart';

enum SortMode {
  renewalSoonest,
  priceHighToLow,
  priceLowToHigh,
  nameAZ,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Subscription> _subs = <Subscription>[];

  // Filters / sort (working)
  SortMode _sortMode = SortMode.renewalSoonest;
  bool _filterActive = true;
  bool _filterInactive = false;
  bool _filterPriceNotSet = false; // "price = 0" only
  final Set<BillingPeriod> _periodFilter = <BillingPeriod>{}; // empty = all

  // Settings (working)
  HomeSettings _settings = const HomeSettings(
    includeInactiveInTotals: false,
    showInactiveSection: true,
    warnForPriceNotSet: true,
  );

  // ----------------------------
  // Ads (Windows WebView2)
  // ----------------------------
  static const String _windowsAdUrl = 'https://cyph3r.live/ads/windows_banner.html';

  // ✅ FIX: keep as double
  static const double _adHeight = 100.0;

  bool get _showAds => true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _subs = StorageService.getSubscriptions());
  }

  Future<void> _add() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SubscriptionEditorScreen()),
    );
    if (created == true) {
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription added')),
      );
    }
  }

  Future<void> _openDetails(Subscription s) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionDetailScreen(subscriptionId: s.id),
      ),
    );
    if (changed == true) _reload();
  }

  // ----------------------------
  // Totals
  // ----------------------------
  double _toMonthlyAmount(Subscription s) {
    switch (s.period) {
      case BillingPeriod.weekly:
        return s.price * 4.345; // avg weeks per month
      case BillingPeriod.monthly:
        return s.price;
      case BillingPeriod.yearly:
        return s.price / 12.0;
    }
  }

  Map<String, double> _monthlyTotalsByCurrency() {
    final Map<String, double> totals = {};
    final includeInactive = _settings.includeInactiveInTotals;

    for (final s in _subs) {
      if (!includeInactive && !s.active) continue;

      // If price is unset (0), don't inflate spend.
      if (s.price <= 0) continue;

      final cur = (s.currency).trim().toUpperCase();
      totals[cur] = (totals[cur] ?? 0) + _toMonthlyAmount(s);
    }
    return totals;
  }

  // ----------------------------
  // Filtering + Sorting
  // ----------------------------
  List<Subscription> _filteredSortedSubs() {
    Iterable<Subscription> items = _subs;

    // State filters
    items = items.where((s) {
      if (s.active && !_filterActive) return false;
      if (!s.active && !_filterInactive) return false;
      return true;
    });

    // Price not set filter
    if (_filterPriceNotSet) {
      items = items.where((s) => s.price <= 0);
    }

    // Period filter
    if (_periodFilter.isNotEmpty) {
      items = items.where((s) => _periodFilter.contains(s.period));
    }

    final list = items.toList();

    // Sort
    list.sort((a, b) {
      switch (_sortMode) {
        case SortMode.renewalSoonest:
          return a.nextBillingDate.compareTo(b.nextBillingDate);
        case SortMode.priceHighToLow:
          return b.price.compareTo(a.price);
        case SortMode.priceLowToHigh:
          return a.price.compareTo(b.price);
        case SortMode.nameAZ:
          return _titleCase(a.name).compareTo(_titleCase(b.name));
      }
    });

    return list;
  }

  String _sortLabel(SortMode m) {
    switch (m) {
      case SortMode.renewalSoonest:
        return 'Renewal date';
      case SortMode.priceHighToLow:
        return 'Price (high → low)';
      case SortMode.priceLowToHigh:
        return 'Price (low → high)';
      case SortMode.nameAZ:
        return 'Name (A–Z)';
    }
  }

  // ----------------------------
  // UI helpers
  // ----------------------------
  static String _currencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'PLN':
        return 'zł';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return code.toUpperCase(); // fallback to code if unknown
    }
  }

  static String _formatMonthlyAmount(double value, String currencyCode) {
    final v = value.toStringAsFixed(2);
    final sym = _currencySymbol(currencyCode);

    if (sym == 'zł') return '$v zł';
    if (sym.length == 3) return '$v $sym';
    return '$sym$v';
  }

  static String _titleCase(String input) {
    final s = input.trim();
    if (s.isEmpty) return s;
    final parts = s.split(RegExp(r'\s+'));
    return parts
        .map((w) {
      if (w.isEmpty) return w;
      final lower = w.toLowerCase();
      final isAllCaps = w == w.toUpperCase() && w.length <= 4;
      if (isAllCaps) return w;
      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    })
        .join(' ');
  }

  static String _formatDateMMMddyyyy(DateTime dt) {
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

  int _daysUntil(DateTime dt) {
    final now = DateTime.now();
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(dt.year, dt.month, dt.day);
    return b.difference(a).inDays;
  }

  String _statusHint(Subscription s) {
    if (!s.active) return 'Inactive';
    final days = _daysUntil(s.nextBillingDate);
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Renews today';
    if (days <= 3) return 'Renews in $days day${days == 1 ? '' : 's'}';
    return '';
  }

  // ----------------------------
  // Filters bottom sheet (WORKING)
  // ----------------------------
  Future<void> _openFilters() async {
    final cs = Theme.of(context).colorScheme;

    SortMode sort = _sortMode;
    bool active = _filterActive;
    bool inactive = _filterInactive;
    bool priceNotSet = _filterPriceNotSet;
    final Set<BillingPeriod> periods = {..._periodFilter};

    final applied = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            Widget periodChip(BillingPeriod p, String label) {
              final selected = periods.contains(p);
              return FilterChip(
                selected: selected,
                label: Text(label),
                onSelected: (v) => setModal(() {
                  if (v) {
                    periods.add(p);
                  } else {
                    periods.remove(p);
                  }
                }),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16.0,
                top: 8.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort & filters',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text('Sort by', style: Theme.of(ctx).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SortMode.values.map((m) {
                      final selected = sort == m;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(_sortLabel(m)),
                        onSelected: (_) => setModal(() => sort = m),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Show', style: Theme.of(ctx).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: active,
                    onChanged: (v) => setModal(() => active = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Inactive'),
                    value: inactive,
                    onChanged: (v) => setModal(() => inactive = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Price not set'),
                    subtitle: const Text('Shows subscriptions with price = 0'),
                    value: priceNotSet,
                    onChanged: (v) => setModal(() => priceNotSet = v),
                  ),
                  const SizedBox(height: 8),
                  Text('Billing period', style: Theme.of(ctx).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      periodChip(BillingPeriod.monthly, 'Monthly'),
                      periodChip(BillingPeriod.yearly, 'Yearly'),
                      periodChip(BillingPeriod.weekly, 'Weekly'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModal(() {
                              sort = SortMode.renewalSoonest;
                              active = true;
                              inactive = false;
                              priceNotSet = false;
                              periods.clear();
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (!active && !inactive) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: const Text('Select at least one: Active or Inactive'),
                                  backgroundColor: cs.error,
                                ),
                              );
                              return;
                            }
                            Navigator.pop(ctx, true);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (applied == true) {
      setState(() {
        _sortMode = sort;
        _filterActive = active;
        _filterInactive = inactive;
        _filterPriceNotSet = priceNotSet;
        _periodFilter
          ..clear()
          ..addAll(periods);
      });
    }
  }

  // ----------------------------
  // Settings (WORKING)
  // ----------------------------
  Future<void> _openSettings() async {
    final updated = await Navigator.push<HomeSettings>(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen(initial: _settings)),
    );
    if (updated != null) {
      setState(() => _settings = updated);
    }
  }

  // ----------------------------
  // Cards
  // ----------------------------
  Widget _monthlySpendCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totals = _monthlyTotalsByCurrency();

    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final numberStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800);

    final suffixStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.paid, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly spend',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total across all subscriptions',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  if (entries.isEmpty) ...[
                    RichText(
                      text: TextSpan(
                        style: numberStyle,
                        children: [
                          const TextSpan(text: '0.00'),
                          TextSpan(text: ' / month', style: suffixStyle),
                        ],
                      ),
                    ),
                  ] else if (entries.length == 1) ...[
                    RichText(
                      text: TextSpan(
                        style: numberStyle,
                        children: [
                          TextSpan(text: _formatMonthlyAmount(entries.first.value, entries.first.key)),
                          TextSpan(text: ' / month', style: suffixStyle),
                        ],
                      ),
                    ),
                  ] else ...[
                    RichText(
                      text: TextSpan(
                        style: numberStyle,
                        children: [
                          TextSpan(text: _formatMonthlyAmount(entries.first.value, entries.first.key)),
                          TextSpan(text: ' / month', style: suffixStyle),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...entries.skip(1).map(
                          (e) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${_formatMonthlyAmount(e.value, e.key)} / month',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Multiple currencies detected.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'Sorted by: ${_sortLabel(_sortMode)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 14),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Icon(
                  Icons.subscriptions_outlined,
                  size: 40,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Never forget a renewal or overpay again.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Track renewals, spending, and cancellations in one place.\nStay in control of your subscriptions.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _add,
                  child: const Text('Add your first subscription'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subscriptionCard(BuildContext context, Subscription s) {
    final cs = Theme.of(context).colorScheme;
    final name = _titleCase(s.name);
    final period = periodLabel(s.period);
    final renewal = _formatDateMMMddyyyy(s.nextBillingDate);

    final priceNotSet = s.price <= 0;
    final showWarn = _settings.warnForPriceNotSet && priceNotSet;
    final showFree = priceNotSet;

    final priceLine = showFree ? (showWarn ? 'Price not set' : 'Free') : '${formatMoney(s.price, s.currency)} · $period';
    final status = _statusHint(s);

    final semanticsLabel = [
      name,
      if (!priceNotSet) '${formatMoney(s.price, s.currency)}, $period',
      if (priceNotSet) (showWarn ? 'price not set' : 'free'),
      'renews $renewal',
      if (status.isNotEmpty) status,
      if (!s.active) 'inactive',
    ].join(', ');

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDetails(s),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  s.active ? Icons.subscriptions : Icons.pause_circle,
                  color: s.active ? cs.primary : cs.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              priceLine,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                          if (showWarn)
                            const _DotPill(
                              label: 'Fix',
                              tooltip: 'Price is 0. Set a price to improve totals.',
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.calendar_month, size: 18, color: cs.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Renews $renewal',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                          if (status.isNotEmpty)
                            _StatusPill(
                              label: status,
                              isWarning: status.contains('Overdue') || status.contains('today') || status.contains('Renews in'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildList(BuildContext context, List<Subscription> items) {
    final active = items.where((s) => s.active).toList();
    final inactive = items.where((s) => !s.active).toList();

    final List<Widget> out = [];

    out.addAll(
      active.map(
            (s) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _subscriptionCard(context, s),
        ),
      ),
    );

    if (_settings.showInactiveSection && inactive.isNotEmpty) {
      out.add(const SizedBox(height: 6));
      out.add(
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Inactive',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      );
      out.addAll(
        inactive.map(
              (s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _subscriptionCard(context, s),
          ),
        ),
      );
    } else {
      if (!_settings.showInactiveSection) {
        out.addAll(
          inactive.map(
                (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _subscriptionCard(context, s),
            ),
          ),
        );
      }
    }

    return out;
  }

  // ----------------------------
  // Ad UI
  // ----------------------------
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

    final filtered = _filteredSortedSubs();
    final hasAny = _subs.isNotEmpty;
    final shownCount = filtered.length;

    final title = hasAny ? 'Subscriptions ($shownCount)' : 'Your subscriptions';

    // ✅ FIX: bottomPadding must be double
    final double bottomPadding = (_showAds ? _adHeight : 0.0) + (hasAny ? 96.0 : 24.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Sort & filters',
            onPressed: _openFilters,
            icon: Icon(Icons.tune, color: cs.onSurfaceVariant),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: Icon(Icons.settings_outlined, color: cs.onSurfaceVariant),
          ),
        ],
      ),
      floatingActionButton: hasAny
          ? FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      )
          : null,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, bottomPadding),
              children: [
                _monthlySpendCard(context),
                const SizedBox(height: 16),
                if (!hasAny) ...[
                  SizedBox(height: MediaQuery.of(context).size.height * 0.10),
                  _emptyState(context),
                ] else if (filtered.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 40, color: cs.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          'No subscriptions match your filters.',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting filters or resetting them.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _sortMode = SortMode.renewalSoonest;
                              _filterActive = true;
                              _filterInactive = false;
                              _filterPriceNotSet = false;
                              _periodFilter.clear();
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset filters'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ..._buildList(context, filtered),
                  const SizedBox(height: 8),
                ],
              ],
            ),
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

class _StatusPill extends StatelessWidget {
  final String label;
  final bool isWarning;

  const _StatusPill({required this.label, required this.isWarning});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.schedule,
            size: 16,
            color: cs.onSurfaceVariant,
          ),
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

class _DotPill extends StatelessWidget {
  final String label;
  final String tooltip;

  const _DotPill({required this.label, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: cs.tertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

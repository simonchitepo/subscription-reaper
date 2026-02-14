import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/subscription.dart';
import '../services/storage.dart';
import '../widgets/common.dart';
import '../widgets/windows_ad_banner.dart';

class SubscriptionEditorScreen extends StatefulWidget {
  final Subscription? existing;

  const SubscriptionEditorScreen({super.key, this.existing});

  @override
  State<SubscriptionEditorScreen> createState() => _SubscriptionEditorScreenState();
}

class _SubscriptionEditorScreenState extends State<SubscriptionEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _currency;
  late final TextEditingController _domain;
  late final TextEditingController _cancelUrl;

  BillingPeriod _period = BillingPeriod.monthly;
  DateTime _next = DateTime.now().add(const Duration(days: 30));
  bool _active = true;

  bool _saving = false;
  bool _advancedOpen = false;

  bool _dateTouched = false;
  bool _dirty = false;
  late final Map<String, Object?> _initialSnapshot;

  bool get _editing => widget.existing != null;

  // ----------------------------
  // Ads (Windows WebView2)
  // ----------------------------
  static const String _windowsAdUrl = 'https://cyph3r.live/ads/windows_banner.html';
  static const double _adHeight = 100.0;

  // Later you can switch off for premium users / remove-ads
  bool get _showAds => true;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;

    _name = TextEditingController(text: s?.name ?? '');
    _price = TextEditingController(text: _initialPriceText(s?.price));
    _currency = TextEditingController(
      text: (s?.currency ?? _defaultCurrencyFromLocale()).toUpperCase(),
    );
    _domain = TextEditingController(text: s?.providerDomain ?? '');
    _cancelUrl = TextEditingController(text: s?.cancellationUrl ?? '');

    _period = s?.period ?? BillingPeriod.monthly;
    _active = s?.active ?? true;
    _next = s?.nextBillingDate ?? _nextForPeriod(_period);

    _initialSnapshot = _snapshot();

    for (final c in [_name, _price, _currency, _domain, _cancelUrl]) {
      c.addListener(_recomputeDirty);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _currency.dispose();
    _domain.dispose();
    _cancelUrl.dispose();
    super.dispose();
  }

  String _initialPriceText(double? v) {
    if (v == null || v == 0) return '';
    return v.toStringAsFixed(2);
  }

  Map<String, Object?> _snapshot() => {
    'name': _name.text.trim(),
    'price': _parsePrice(_price.text),
    'currency': _currency.text.trim().toUpperCase(),
    'period': _period.name,
    'next': DateTime(_next.year, _next.month, _next.day).toIso8601String(),
    'domain': _domain.text.trim(),
    'cancel': _cancelUrl.text.trim(),
    'active': _active,
  };

  void _recomputeDirty() {
    final d = _snapshot().toString() != _initialSnapshot.toString();
    if (d != _dirty) setState(() => _dirty = d);
  }

  double? _parsePrice(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  String _defaultCurrencyFromLocale() {
    try {
      final loc = WidgetsBinding.instance.platformDispatcher.locale;
      final cc = (loc.countryCode ?? '').toUpperCase();
      switch (cc) {
        case 'PL':
          return 'PLN';
        case 'GB':
          return 'GBP';
        case 'US':
          return 'USD';
        case 'JP':
          return 'JPY';
        default:
          return 'EUR';
      }
    } catch (_) {
      return 'USD';
    }
  }

  DateTime _nextForPeriod(BillingPeriod p) {
    final now = DateTime.now();
    switch (p) {
      case BillingPeriod.weekly:
        return now.add(const Duration(days: 7));
      case BillingPeriod.monthly:
        return now.add(const Duration(days: 30));
      case BillingPeriod.yearly:
        return now.add(const Duration(days: 365));
    }
  }

  String _perSuffixForPeriod(BillingPeriod p) {
    switch (p) {
      case BillingPeriod.weekly:
        return 'per week';
      case BillingPeriod.monthly:
        return 'per month';
      case BillingPeriod.yearly:
        return 'per year';
    }
  }

  int _daysUntil(DateTime dt) {
    final now = DateTime.now();
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(dt.year, dt.month, dt.day);
    return b.difference(a).inDays;
  }

  String _relativeHint(DateTime dt) {
    final d = _daysUntil(dt);
    if (d < 0) return 'Overdue';
    if (d == 0) return 'Today';
    if (d == 1) return 'In 1 day';
    return 'In $d days';
  }

  String _ymd(DateTime d) => d.toLocal().toString().split(' ').first;

  String _normalizeDomain(String v) {
    final t = v.trim();
    if (t.isEmpty) return t;
    var d = t.toLowerCase();
    d = d.replaceAll(RegExp(r'^https?://'), '');
    d = d.replaceAll(RegExp(r'/.*$'), '');
    return d;
  }

  String _normalizeUrl(String v) {
    final t = v.trim();
    if (t.isEmpty) return t;
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return 'https://$t';
  }

  void _maybeAutofillDomainFromName() {
    if (_domain.text.trim().isNotEmpty) return;
    final n = _name.text.trim().toLowerCase();

    const known = <String, String>{
      'netflix': 'netflix.com',
      'spotify': 'spotify.com',
      'icloud': 'apple.com',
      'youtube': 'youtube.com',
      'google': 'google.com',
      'amazon prime': 'amazon.com',
      'prime video': 'amazon.com',
      'disney': 'disneyplus.com',
    };

    for (final e in known.entries) {
      if (n.contains(e.key)) {
        _domain.text = e.value;
        return;
      }
    }
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required';
    return null;
  }

  String? _validatePrice(String? v) {
    final p = _parsePrice(v ?? '');
    if (p == null) return 'Price is required';
    if (p <= 0) return 'Price must be greater than 0';
    return null;
  }

  bool get _requiredValid {
    final n = _name.text.trim();
    final p = _parsePrice(_price.text);
    return n.isNotEmpty && p != null && p > 0;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _next,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      helpText: 'Next billing date',
    );
    if (picked != null) {
      setState(() {
        _next = picked;
        _dateTouched = true;
      });
      _recomputeDirty();
    }
  }

  void _onPeriodChanged(BillingPeriod p) {
    setState(() {
      _period = p;
      if (!_dateTouched && !_editing) {
        _next = _nextForPeriod(p);
      }
    });
    _recomputeDirty();
  }

  Future<bool> _confirmDiscardIfDirty() async {
    if (!_dirty || _saving) return true;

    final ok = await confirmDialog(
      context,
      title: 'Discard changes?',
      message: 'You have unsaved changes.',
      confirmText: 'Discard',
      danger: true,
    );
    return ok;
  }

  Future<void> _save() async {
    final validForm = _formKey.currentState?.validate() ?? false;
    if (!validForm || !_requiredValid) return;

    setState(() => _saving = true);
    try {
      final price = _parsePrice(_price.text) ?? 0.0;
      final currency = _currency.text.trim().isEmpty
          ? _defaultCurrencyFromLocale()
          : _currency.text.trim().toUpperCase();

      _maybeAutofillDomainFromName();

      final domain = _normalizeDomain(_domain.text);
      final cancel = _normalizeUrl(_cancelUrl.text);

      final sub = (widget.existing ??
          Subscription(
            name: _name.text.trim(),
            price: price,
            currency: currency,
            nextBillingDate: _next,
            period: _period,
            active: _active,
          ))
        ..name = _name.text.trim()
        ..price = price
        ..currency = currency
        ..period = _period
        ..nextBillingDate = _next
        ..active = _active
        ..providerDomain = domain.isEmpty ? null : domain
        ..cancellationUrl = cancel.isEmpty ? null : cancel;

      await StorageService.upsertSubscription(sub);

      if (!mounted) return;

      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editing ? '${sub.name} updated' : '${sub.name} added')),
      );

      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
    final perSuffix = _perSuffixForPeriod(_period);

    final pricePreview = _parsePrice(_price.text) ?? 0.0;
    final currencyPreview = (_currency.text.trim().isNotEmpty
        ? _currency.text.trim().toUpperCase()
        : _defaultCurrencyFromLocale())
        .toUpperCase();

    final saveEnabled = !_saving && _requiredValid;

    // ✅ FIX: make bottomPadding a double
    final double bottomPadding = (_showAds ? _adHeight : 0.0) + 24.0;

    return WillPopScope(
      onWillPop: _confirmDiscardIfDirty,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editing ? 'Edit subscription' : 'Add subscription'),
          actions: [
            TextButton(
              onPressed: saveEnabled ? _save : null,
              child: Text(
                'Save',
                style: TextStyle(
                  color: saveEnabled ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, bottomPadding),
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Netflix, Spotify, iCloud…',
                    ),
                    validator: _validateName,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _maybeAutofillDomainFromName(),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _price,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d\.,]')),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Price',
                            hintText: '9.99',
                            helperText: 'Charged $perSuffix',
                          ),
                          validator: _validatePrice,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () {
                            final p = _parsePrice(_price.text);
                            if (p != null) _price.text = p.toStringAsFixed(2);
                            FocusScope.of(context).nextFocus();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _currency,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                            LengthLimitingTextInputFormatter(3),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Currency',
                            hintText: 'USD',
                            helperText: 'ISO code',
                          ),
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () => FocusScope.of(context).nextFocus(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Billing period',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<BillingPeriod>(
                    segments: const <ButtonSegment<BillingPeriod>>[
                      ButtonSegment(value: BillingPeriod.monthly, label: Text('Monthly')),
                      ButtonSegment(value: BillingPeriod.yearly, label: Text('Yearly')),
                      ButtonSegment(value: BillingPeriod.weekly, label: Text('Weekly')),
                    ],
                    selected: <BillingPeriod>{_period},
                    onSelectionChanged: (set) => _onPeriodChanged(set.first),
                    showSelectedIcon: false,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How often you’re charged.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),

                  const SizedBox(height: 18),

                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerHighest,
                    child: InkWell(
                      onTap: _pickDate,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.calendar_month, color: cs.onPrimaryContainer),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Next billing date',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _ymd(_next),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Date of your next charge · ${_relativeHint(_next)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: cs.onSurfaceVariant),
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

                  const SizedBox(height: 18),

                  Card(
                    child: ExpansionTile(
                      initiallyExpanded: _advancedOpen,
                      onExpansionChanged: (v) => setState(() => _advancedOpen = v),
                      title: Text(
                        'Advanced options',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        'Provider domain and cancellation link',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        TextFormField(
                          controller: _domain,
                          decoration: const InputDecoration(
                            labelText: 'Provider domain (optional)',
                            hintText: 'netflix.com',
                            helperText: 'Used to identify the provider and show its logo.',
                          ),
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () {
                            _domain.text = _normalizeDomain(_domain.text);
                            FocusScope.of(context).nextFocus();
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cancelUrl,
                          decoration: const InputDecoration(
                            labelText: 'Cancellation URL (optional)',
                            hintText: 'https://…',
                            helperText: 'Link to the page where you can cancel this subscription.',
                            suffixIcon: Icon(Icons.link),
                          ),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.done,
                          onEditingComplete: () {
                            _cancelUrl.text = _normalizeUrl(_cancelUrl.text);
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _active,
                    onChanged: (v) {
                      setState(() => _active = v);
                      _recomputeDirty();
                    },
                    title: const Text('Subscription active'),
                    subtitle: const Text('Inactive subscriptions are excluded from totals'),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Summary',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$pricePreview $currencyPreview · ${_period.name[0].toUpperCase()}${_period.name.substring(1)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Renews ${_ymd(_next)} (${_relativeHint(_next)})',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  FilledButton(
                    onPressed: saveEnabled ? _save : null,
                    child: _saving
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Save subscription'),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () async {
                      final ok = await _confirmDiscardIfDirty();
                      if (!ok) return;
                      if (!mounted) return;
                      Navigator.pop(context, false);
                    },
                    child: const Text('Cancel'),
                  ),
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
      ),
    );
  }
}

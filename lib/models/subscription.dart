import 'package:uuid/uuid.dart';

class Subscription {
  final String id;
  String name;
  String? providerDomain; // e.g. "netflix.com"
  String? cancellationUrl; // direct cancellation page if known
  double price;
  String currency; // e.g. "USD", "PLN"
  DateTime nextBillingDate;
  BillingPeriod period;
  bool active;

  /// Optional recorded cancellation flow.
  CancellationFlow? flow;

  Subscription({
    String? id,
    required this.name,
    this.providerDomain,
    this.cancellationUrl,
    required this.price,
    required this.currency,
    required this.nextBillingDate,
    required this.period,
    this.active = true,
    this.flow,
  }) : id = id ?? const Uuid().v4();

  Subscription copy() => Subscription(
    id: id,
    name: name,
    providerDomain: providerDomain,
    cancellationUrl: cancellationUrl,
    price: price,
    currency: currency,
    nextBillingDate: nextBillingDate,
    period: period,
    active: active,
    flow: flow,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'providerDomain': providerDomain,
    'cancellationUrl': cancellationUrl,
    'price': price,
    'currency': currency,
    'nextBillingDate': nextBillingDate.toIso8601String(),
    'period': period.name,
    'active': active,
    'flow': flow?.toJson(),
  };

  static Subscription fromJson(Map<String, dynamic> json) => Subscription(
    id: json['id'] as String?,
    name: (json['name'] as String?) ?? 'Subscription',
    providerDomain: json['providerDomain'] as String?,
    cancellationUrl: json['cancellationUrl'] as String?,
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    currency: (json['currency'] as String?) ?? 'USD',
    nextBillingDate: DateTime.tryParse((json['nextBillingDate'] as String?) ?? '') ??
        DateTime.now().add(const Duration(days: 30)),
    period: BillingPeriod.values.firstWhere(
          (p) => p.name == (json['period'] as String?),
      orElse: () => BillingPeriod.monthly,
    ),
    active: (json['active'] as bool?) ?? true,
    flow: (json['flow'] is Map)
        ? CancellationFlow.fromJson(
      Map<String, dynamic>.from(json['flow'] as Map),
    )
        : null,
  );
}

enum BillingPeriod { weekly, monthly, yearly }

class CancellationFlow {
  final List<FlowStep> steps;

  CancellationFlow({required this.steps});

  Map<String, dynamic> toJson() => {
    'steps': steps.map((s) => s.toJson()).toList(),
  };

  static CancellationFlow fromJson(Map<String, dynamic> json) => CancellationFlow(
    steps: (json['steps'] as List? ?? const [])
        .map((e) => FlowStep.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

enum FlowActionType { click, input, wait, scrollIntoView }

class FlowStep {
  final FlowActionType type;
  final String? selector;
  final String? value;
  final int? waitMs;

  FlowStep._({
    required this.type,
    this.selector,
    this.value,
    this.waitMs,
  });

  factory FlowStep.click(String selector) => FlowStep._(type: FlowActionType.click, selector: selector);
  factory FlowStep.input(String selector, String value) =>
      FlowStep._(type: FlowActionType.input, selector: selector, value: value);
  factory FlowStep.wait(int ms) => FlowStep._(type: FlowActionType.wait, waitMs: ms);
  factory FlowStep.scrollIntoView(String selector) =>
      FlowStep._(type: FlowActionType.scrollIntoView, selector: selector);

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'selector': selector,
    'value': value,
    'waitMs': waitMs,
  };

  static FlowStep fromJson(Map<String, dynamic> json) {
    final t = FlowActionType.values.firstWhere(
          (x) => x.name == (json['type'] as String?),
      orElse: () => FlowActionType.click,
    );

    return FlowStep._(
      type: t,
      selector: json['selector'] as String?,
      value: json['value'] as String?,
      waitMs: (json['waitMs'] as num?)?.toInt(),
    );
  }

  @override
  String toString() {
    switch (type) {
      case FlowActionType.click:
        return 'Click: ${selector ?? "(no selector)"}';
      case FlowActionType.input:
        return 'Input: ${selector ?? "(no selector)"} = "${_redacted(value)}"';
      case FlowActionType.wait:
        return 'Wait: ${waitMs ?? 0} ms';
      case FlowActionType.scrollIntoView:
        return 'Scroll into view: ${selector ?? "(no selector)"}';
    }
  }

  static String _redacted(String? v) {
    if (v == null) return '';
    if (v.length <= 3) return '***';
    return '${v.substring(0, 1)}***${v.substring(v.length - 1)}';
  }
}

import '../models/subscription.dart';

String formatMoney(double value, String currency) {
  final v = value.toStringAsFixed(2);
  return '$v $currency';
}

String periodLabel(BillingPeriod p) {
  switch (p) {
    case BillingPeriod.weekly:
      return 'Weekly';
    case BillingPeriod.monthly:
      return 'Monthly';
    case BillingPeriod.yearly:
      return 'Yearly';
  }
}

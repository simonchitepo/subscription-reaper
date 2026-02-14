import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/subscription.dart';

class StorageService {
  static const String _boxName = 'subscription_reaper_box_v1';
  static const String _keySubscriptions = 'subscriptions';

  static Box<dynamic>? _box;

  static Future<void> initHive() async {
    if (_box != null && _box!.isOpen) return;

    // Works on mobile/desktop and on web.
    await Hive.initFlutter();

    _box = await Hive.openBox<dynamic>(_boxName);

    // Ensure the key exists.
    final existing = _box!.get(_keySubscriptions);
    if (existing == null) {
      await _box!.put(_keySubscriptions, jsonEncode(<dynamic>[]));
    } else if (existing is! String) {
      // If older versions stored a non-string, normalize.
      await _box!.put(_keySubscriptions, jsonEncode(existing));
    }
  }

  static Box<dynamic> get _requiredBox {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('Hive box is not initialized. Call StorageService.initHive() first.');
    }
    return b;
  }

  static List<Subscription> getSubscriptions() {
    final raw = _requiredBox.get(_keySubscriptions);
    if (raw == null) return <Subscription>[];

    try {
      final decoded = jsonDecode(raw as String);
      if (decoded is! List) return <Subscription>[];
      return decoded
          .whereType<Map>()
          .map((e) => Subscription.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: true);
    } catch (_) {
      return <Subscription>[];
    }
  }

  static Future<void> saveSubscriptions(List<Subscription> subs) async {
    final payload = jsonEncode(subs.map((s) => s.toJson()).toList());
    await _requiredBox.put(_keySubscriptions, payload);
  }

  static Future<void> upsertSubscription(Subscription sub) async {
    final subs = getSubscriptions();
    final idx = subs.indexWhere((s) => s.id == sub.id);
    if (idx >= 0) {
      subs[idx] = sub;
    } else {
      subs.add(sub);
    }
    await saveSubscriptions(subs);
  }

  static Future<void> deleteSubscription(String id) async {
    final subs = getSubscriptions()..removeWhere((s) => s.id == id);
    await saveSubscriptions(subs);
  }

  static Subscription? getById(String id) {
    final subs = getSubscriptions();
    try {
      return subs.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

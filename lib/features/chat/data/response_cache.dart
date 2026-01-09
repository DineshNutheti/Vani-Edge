import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ResponseCache {
  ResponseCache({this.storageKey = 'response_cache'});

  final String storageKey;
  final Map<String, String> _memory = {};

  Future<void> load() async {
    // Load cached responses from shared preferences for consistency.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    for (final entry in data.entries) {
      _memory[entry.key] = entry.value.toString();
    }
  }

  String? get(String key) => _memory[key];

  Future<void> set(String key, String value) async {
    _memory[key] = value;
    await _persist();
  }

  Future<void> clear() async {
    _memory.clear();
    await _persist();
  }

  Future<void> _persist() async {
    // Persist full cache map; small size keeps it lightweight.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(_memory));
  }
}

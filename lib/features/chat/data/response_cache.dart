import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// In-memory + persisted cache keyed by language/intent/text.
class ResponseCache {
  ResponseCache({this.storageKey = 'response_cache'});

  final String storageKey;
  final Map<String, String> _memory = {};

  /// Loads cached responses into memory for fast lookup.
  Future<void> load() async {
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

  /// Stores a response by cache key and persists the map.
  Future<void> set(String key, String value) async {
    _memory[key] = value;
    await _persist();
  }

  Future<void> clear() async {
    _memory.clear();
    await _persist();
  }

  Future<void> _persist() async {
    // Persist full cache map; size is small because entries are short texts.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(_memory));
  }
}

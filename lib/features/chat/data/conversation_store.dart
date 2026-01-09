import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/message.dart';

class ConversationStore {
  ConversationStore({this.storageKey = 'conversation_history'});

  final String storageKey;

  Future<List<Message>> load() async {
    // History is stored as a JSON array in shared preferences.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final data = jsonDecode(raw) as List<dynamic>;
    return data
        .map((entry) => Message.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<Message> messages) async {
    // Persist the full list to keep ordering stable across launches.
    final prefs = await SharedPreferences.getInstance();
    final data = messages.map((message) => message.toJson()).toList();
    await prefs.setString(storageKey, jsonEncode(data));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}

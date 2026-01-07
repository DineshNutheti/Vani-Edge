// lib/core/services/llm_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The contract for our AI Brain.
abstract class LLMService {
  Future<void> initialize();
  Stream<String> streamResponse(String prompt);
  void dispose();
}

/// Provider to access the service globally
final llmServiceProvider = Provider<LLMService>((ref) {
  throw UnimplementedError('Initialize this provider in main.dart');
});
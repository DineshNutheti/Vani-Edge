import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vani_edge/core/app_language.dart';
import 'package:vani_edge/features/chat/data/knowledge_base.dart';
import 'package:vani_edge/features/chat/data/response_cache.dart';
import 'package:vani_edge/features/chat/domain/intent.dart';
import 'package:vani_edge/features/chat/domain/intent_model.dart';
import 'package:vani_edge/features/chat/domain/local_model.dart';
import 'package:vani_edge/features/chat/domain/prompt_wrapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('IntentModel detects translation intent', () async {
    final model = IntentModel();
    await model.loadFromAssets('assets/intent_samples.json');

    final result = model.predict('Translate this to Hindi');

    expect(result.intent, equals(Intent.translate));
    expect(result.confidence, greaterThan(0));
  });

  test('PromptWrapper caches repeated requests', () async {
    final model = IntentModel();
    final knowledgeBase = KnowledgeBase();
    final cache = ResponseCache();

    await model.loadFromAssets('assets/intent_samples.json');
    await knowledgeBase.loadFromAssets('assets/knowledge_base.json');
    await cache.load();

    final wrapper = PromptWrapper(
      intentModel: model,
      localModel: LocalModel(knowledgeBase: knowledgeBase),
      cache: cache,
    );

    final first = await wrapper.handle('What can you do?', AppLanguage.english);
    final second = await wrapper.handle('What can you do?', AppLanguage.english);

    expect(first.usedCache, isFalse);
    expect(second.usedCache, isTrue);
    expect(first.response.text, equals(second.response.text));
  });

  test('OutputValidator enforces language script', () {
    final validator = OutputValidator();

    expect(
      validator.isValid('नमस्ते', AppLanguage.hindi, 10),
      isTrue,
    );
    expect(
      validator.isValid('Hello', AppLanguage.hindi, 10),
      isFalse,
    );
  });
}

# Prompt Wrapper Spec

## 9.1 Goals
- Enforce output language based on user selection
- Enforce output format (short answer / steps / summary)
- Reduce low-quality output with a retry
- Reduce wasted work with caching
- Keep logic deterministic and testable

## 9.2 Implementation Location
- `lib/features/chat/domain/prompt_wrapper.dart`
- Depends on `IntentModel` (Naive Bayes), `LocalModel`, and `ResponseCache`.

## 9.3 Wrapper Logic (Pseudo)
```
intent = intent_model.predict(text)
request = build_request(intent, language, constraints)
key = cache_key(language, intent, normalized_text)
if cache has key: return cached
response = local_model.generate(request)
if invalid(response):
  request = build_request(intent, language, strict=true)
  response = local_model.generate(request)
cache[key] = response
return response
```

## 9.4 Constraints
- Max words per intent:
  - translate: 30
  - summarize: 40
  - qna: 35
  - task: 45
  - chat: 20
- Normalization: lowercase + trim.
- Cache key: `langCode::intent::normalizedText`.
- Cache storage: `shared_preferences` key `response_cache`.

## 9.5 Validation Rules
- non-empty output
- word limit (maxWords + 10 guard)
- output contains language script
  - Devanagari for Hindi/Marathi
  - Tamil script for Tamil
  - Gujarati script for Gujarati

## 9.6 Retry Policy
- One retry only.
- Strict mode forces more conservative fallback templates.

## 9.7 Examples Where Wrapper Improves Output
- If intent detection is weak, the wrapper retries with a stricter template to keep responses concise.
- If output language does not match selection, validation fails and the wrapper falls back to a localized template.
- Repeated questions are served from cache for consistent responses and low latency.

## 9.8 10 Test Prompts + Expected Behavior
| User Speech | Intent | Wrapper Prompt Used | Expected Output Type |
|---|---|---|---|
| Translate this to Hindi | translate | translation template | Translation (Hindi) |
| Summarize this paragraph about travel | summarize | summary template | Short summary |
| What can you do? | qna | short answer + KB lookup | KB answer |
| Give me steps to prepare for an interview | task | steps template | Step list |
| Hello there | chat | greeting template | Greeting |
| इसका सारांश बताओ | summarize | summary template (HI) | Summary in Hindi |
| ऐप ऑफलाइन है? | qna | short answer + KB lookup (HI) | Offline answer |
| இதை மொழிபெயர்க்கவும் | translate | translation template (TA) | Translation or fallback |
| મને પગલાં આપો | task | steps template (GU) | Steps in Gujarati |
| कसे आहात? | chat | greeting template (MR) | Greeting |

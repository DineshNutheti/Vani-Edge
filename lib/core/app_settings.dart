import 'package:flutter/foundation.dart';

import 'app_language.dart';

/// App-level settings that drive UI (currently selected language).
class AppSettings extends ChangeNotifier {
  AppSettings({AppLanguage? language})
      : _language = language ?? AppLanguage.english;

  AppLanguage _language;

  AppLanguage get language => _language;

  /// Updates language and notifies listeners for rebuilds.
  void setLanguage(AppLanguage language) {
    if (_language == language) {
      return;
    }
    // Notify listeners so UI rebuilds with new locale and strings.
    _language = language;
    notifyListeners();
  }
}

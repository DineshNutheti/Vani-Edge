import 'package:flutter/foundation.dart';

import 'app_language.dart';

class AppSettings extends ChangeNotifier {
  AppSettings({AppLanguage? language})
      : _language = language ?? AppLanguage.english;

  AppLanguage _language;

  AppLanguage get language => _language;

  void setLanguage(AppLanguage language) {
    if (_language == language) {
      return;
    }
    // Notify listeners so UI rebuilds with new locale and strings.
    _language = language;
    notifyListeners();
  }
}

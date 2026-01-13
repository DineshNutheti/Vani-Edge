import 'package:flutter/widgets.dart';

import 'app_language.dart';

/// Lightweight localization wrapper used by widgets to access AppStrings.
class AppLocalizations {
  const AppLocalizations(this.language);

  final AppLanguage language;

  AppStrings get strings => AppStrings(language);

  /// Lookup helper from BuildContext.
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}

/// Delegate wired into MaterialApp for localization resolution.
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLanguages.configs.values
        .any((config) => config.locale.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(AppLanguages.fromLocale(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

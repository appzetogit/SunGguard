import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/app_localizations.dart';

/// Fallback wrapper for GlobalMaterialLocalizations.delegate
class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
  }

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    if (GlobalMaterialLocalizations.delegate.isSupported(locale)) {
      return GlobalMaterialLocalizations.delegate.load(locale);
    }
    return GlobalMaterialLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(LocalizationsDelegate<MaterialLocalizations> old) => false;
}

/// Fallback wrapper for GlobalWidgetsLocalizations.delegate
class FallbackWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const FallbackWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
  }

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    if (GlobalWidgetsLocalizations.delegate.isSupported(locale)) {
      return GlobalWidgetsLocalizations.delegate.load(locale);
    }
    return GlobalWidgetsLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(LocalizationsDelegate<WidgetsLocalizations> old) => false;
}

/// Fallback wrapper for GlobalCupertinoLocalizations.delegate
class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
  }

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    if (GlobalCupertinoLocalizations.delegate.isSupported(locale)) {
      return GlobalCupertinoLocalizations.delegate.load(locale);
    }
    return GlobalCupertinoLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(LocalizationsDelegate<CupertinoLocalizations> old) => false;
}

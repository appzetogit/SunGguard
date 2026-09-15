import 'package:flutter/material.dart';
import '../constants/storage_keys.dart';
import '../storage/local_storage_service.dart';

const Map<String, String> kLanguageNativeNames = {
  'en': 'English',
  'hi': 'हिंदी',
  'gu': 'ગુજરાતી',
  'mr': 'मराठी',
  'bn': 'বাংলা',
  'ta': 'தமிழ்',
  'te': 'తెలుగు',
  'kn': 'ಕನ್ನಡ',
  'ml': 'മലയാളം',
  'pa': 'ਪੰਜਾਬੀ',
  'or': 'ଓଡ଼ିଆ',
  'as': 'অসমীয়া',
  'ur': 'اردو',
  'kok': 'कोंकणी',
  'ne': 'नेपाली',
  'sa': 'संस्कृतम्',
  'ks': 'कॉशुर',
  'mai': 'मैथिली',
  'mni': 'ꯃꯤꯇꯩꯂꯣꯟ',
  'brx': 'बर\'',
  'sat': 'ᱥᱟᱱᱛᱟᱲᱤ',
  'sd': 'سنڌي',
  'doi': 'डोगरी',
};

class AppLocaleController extends ValueNotifier<Locale> {
  final LocalStorageService _localStorage;

  static AppLocaleController? _instance;
  static AppLocaleController get instance => _instance!;

  AppLocaleController(this._localStorage)
      : super(Locale(_localStorage.getString(StorageKeys.userLanguage) ?? 'en')) {
    _instance = this;
  }

  Future<void> changeLocale(String languageCode) async {
    await _localStorage.setString(StorageKeys.userLanguage, languageCode);
    value = Locale(languageCode);
  }

  bool get isHindi => value.languageCode == 'hi';

  String get currentLanguageNativeName =>
      kLanguageNativeNames[value.languageCode] ?? 'English';
}

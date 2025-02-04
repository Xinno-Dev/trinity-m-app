import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/localization_service.dart';
import '../common_package.dart';
import '../const/utils/languageHelper.dart';
import '../const/utils/localStorageHelper.dart';

final languageProvider = ChangeNotifierProvider<LanguageProvider>((_) {
  return LanguageProvider();
});

class LanguageProvider with ChangeNotifier {
  LanguageProvider() {
    // set language from system default..
    readFromLocal().then((local) {
      if (local == null) {
        final platformLocale = Platform.localeName.split('_')[0];
        if (platformLocale.isNotEmpty) {
          local = platformLocale;
        }
      }
      setLocale(local);
      notifyListeners();
    });
  }

  String? currentLanguage;
  Locale? locale;

  LanguageHelper languageHelper = LanguageHelper();
  Locale? get getLocale => locale;

  get isKor {
    return locale?.languageCode == 'ko';
  }

  void setLocale(String newLocale) {
    locale = languageHelper.convertLocaleToLocale(newLocale);
    currentLanguage = languageHelper.convertLocaleToLangName(newLocale);
    print('---> setLocale : $currentLanguage => $locale');
    writeToLocal();
  }

  void changeLocale(String newLocale) {
    setLocale(newLocale);
    notifyListeners();
  }

  writeToLocal() {
    return LocalStorageManager.saveData('locale', locale.toString());
  }

  readFromLocal() async {
    try {
      final localValue = await LocalStorageManager.readData('locale');
      return localValue;
    } catch (e) {
      print('---> readFromLocal error : $e');
    }
  }
}

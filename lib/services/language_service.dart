import 'package:flutter/material.dart';

class LanguageService extends ChangeNotifier {
  bool _isEnglish = true;

  bool get isEnglish => _isEnglish;
  String get languageCode => _isEnglish ? 'EN' : 'BN';

  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    notifyListeners();
  }

  void setLanguage(bool english) {
    _isEnglish = english;
    notifyListeners();
  }
}

class AppStrings {
  static const Map<String, String> english = {
    'medicine_details': 'Medicine Details',
    'usage': 'Usage',
    'dosage': 'Dosage',
    'side_effects': 'Side Effects',
    'price': 'Price',
    'english': 'English',
    'bengali': 'বাংলা',
    'no_side_effects': 'No known side effects',
    'tk': '৳',
  };

  static const Map<String, String> bengali = {
    'medicine_details': 'ওষুধের বিস্তারিত',
    'usage': 'ব্যবহার',
    'dosage': 'মাত্রা',
    'side_effects': 'পার্শ্বপ্রতিক্রিয়া',
    'price': 'মূল্য',
    'english': 'English',
    'bengali': 'বাংলা',
    'no_side_effects': 'কোনো পরিচিত পার্শ্বপ্রতিক্রিয়া নেই',
    'tk': '৳',
  };

  static String getString(String key, bool isEnglish) {
    if (isEnglish) {
      return english[key] ?? key;
    } else {
      return bengali[key] ?? key;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'localstorage/hive.dart';
import 'localstorage/keys.dart';

class LanguageService {
  static const String keyLanguageCode = 'app_language_code';

  static const Map<String, String> english = {
    'Home': 'Home',
    'Udhar': 'Udhar',
    'History': 'History',
    'Profile': 'Profile',
    'Aapko Milega': 'Aapko Milega',
    'Aapko Dena': 'Aapko Dena',
    'Udhar Diya': 'Udhar Diya',
    'Vasooli': 'Vasooli',
    'Voice Entry': 'Voice Entry',
    'Add Customer': 'Add Customer',
    'Customer Directory': 'Customer Directory',
    'All Customers': 'All Customers',
    'Settled': 'Settled',
    'Search customer': 'Search customer by name or phone...',
    'Give Credit': 'Give Credit',
    'Collect Payment': 'Collect Payment',
    'Language': 'Language',
    'App Language': 'App Language',
    'English': 'English',
    'Hindi': 'हिंदी (Hindi)',
    'Save Customer': 'Save Customer',
    'Customer Name': 'Customer Name',
    'Phone Number': 'Phone Number',
    'Credit Limit': 'Credit Limit',
    'Merchant Settings': 'Merchant Settings',
    'Edit Profile': 'Edit Profile',
    'Security & PIN': 'Security & PIN',
    'Help & Support': 'Help & Support',
    'Merchant QR': 'Merchant QR',
    'Upload Merchant QR': 'Upload Merchant QR',
  };

  static const Map<String, String> hindi = {
    'Home': 'होम',
    'Udhar': 'उधार खाता',
    'History': 'लेन-देन इतिहास',
    'Profile': 'प्रोफ़ाइल सेटिंग्स',
    'Aapko Milega': 'आपको मिलेगा',
    'Aapko Dena': 'आपको देना',
    'Udhar Diya': 'उधार दिया',
    'Vasooli': 'वसूली (पेमेंट मिला)',
    'Voice Entry': 'वॉइस एंट्री',
    'Add Customer': 'नया ग्राहक जोड़ें',
    'Customer Directory': 'ग्राहक सूची',
    'All Customers': 'सभी ग्राहक',
    'Settled': 'हिसाब चुकता',
    'Search customer': 'ग्राहक का नाम या मोबाइल नंबर खोजें...',
    'Give Credit': 'उधार दें',
    'Collect Payment': 'पेमेंट वसूलें',
    'Language': 'भाषा बदलें',
    'App Language': 'ऐप की भाषा',
    'English': 'English',
    'Hindi': 'हिंदी (Hindi)',
    'Save Customer': 'ग्राहक सुरक्षित करें',
    'Customer Name': 'ग्राहक का नाम',
    'Phone Number': 'मोबाइल नंबर',
    'Credit Limit': 'उधार सीमा (लिमिट)',
    'Merchant Settings': 'व्यापारी सेटिंग्स',
    'Edit Profile': 'प्रोफ़ाइल संपादित करें',
    'Security & PIN': 'सुरक्षा एवं पिन',
    'Help & Support': 'सहायता एवं सपोर्ट',
    'Merchant QR': 'मर्चेंट क्यूआर',
    'Upload Merchant QR': 'मर्चेंट क्यूआर अपलोड करें',
  };

  static String get currentLanguageCode =>
      HiveHelp.read(keyLanguageCode) ?? 'en';

  static bool get isHindi => currentLanguageCode == 'hi';

  static Map<String, String> get currentTranslations =>
      isHindi ? hindi : english;

  static String tr(String key) {
    return currentTranslations[key] ?? key;
  }

  static Future<void> changeLanguage(String langCode) async {
    HiveHelp.write(keyLanguageCode, langCode);
    final map = langCode == 'hi' ? hindi : english;
    HiveHelp.write(Keys.languageData, map);

    // Update Get locale
    final locale =
        langCode == 'hi' ? const Locale('hi', 'IN') : const Locale('en', 'US');
    Get.updateLocale(locale);
  }
}

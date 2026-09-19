import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'localstorage/hive.dart';

class VoiceSoundboxService extends GetxService {
  static VoiceSoundboxService get to => Get.find<VoiceSoundboxService>();

  final FlutterTts _tts = FlutterTts();
  final RxBool isSoundboxEnabled = true.obs;
  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    final dynamic stored = HiveHelp.read('soundbox_voice_alerts');
    isSoundboxEnabled.value = stored == null ? true : (stored == true);
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);

      final dynamic lang = HiveHelp.read('language_code');
      if (lang == 'hi' || lang == 'hindi') {
        await _tts.setLanguage('hi-IN');
      } else {
        await _tts.setLanguage('en-IN');
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint("VoiceSoundboxService init error: $e");
    }
  }

  void toggleSoundbox(bool enabled) {
    isSoundboxEnabled.value = enabled;
    HiveHelp.write('soundbox_voice_alerts', enabled);
  }

  /// Speak loud payment confirmation alert (In-app Soundbox)
  Future<void> announcePayment({
    required double amount,
    String? customerName,
  }) async {
    if (!isSoundboxEnabled.value) return;

    if (!_isInitialized) {
      await _initTts();
    }

    try {
      final dynamic lang = HiveHelp.read('language_code');
      final bool isHindi = (lang == 'hi' || lang == 'hindi');

      String announcement = "";
      final int formattedAmt = amount.toInt();

      if (isHindi) {
        if (customerName != null && customerName.trim().isNotEmpty) {
          announcement = "$customerName se Udhar Card par $formattedAmt rupaye prapt hue.";
        } else {
          announcement = "Udhar Card par $formattedAmt rupaye prapt hue.";
        }
        await _tts.setLanguage('hi-IN');
      } else {
        if (customerName != null && customerName.trim().isNotEmpty) {
          announcement = "Received $formattedAmt rupees from $customerName on Udhar Card.";
        } else {
          announcement = "Received $formattedAmt rupees on Udhar Card.";
        }
        await _tts.setLanguage('en-IN');
      }

      await _tts.stop();
      await _tts.speak(announcement);
    } catch (e) {
      debugPrint("VoiceSoundboxService announcement error: $e");
    }
  }
}

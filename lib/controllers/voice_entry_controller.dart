import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'udhar_controller.dart';
import '../utils/services/localstorage/hive.dart';
import '../utils/services/helpers.dart';
import '../routes/routes_name.dart';

enum VoiceAssistantState { idle, listening, thinking, speaking }

class VoiceParseResult {
  const VoiceParseResult({
    this.name = '',
    this.amount = 0.0,
    this.type = 'Given',
    this.isQuery = false,
    this.isHelp = false,
    this.reply = '',
  });

  final String name;
  final double amount;
  final String type;
  final bool isQuery;
  final bool isHelp;
  final String reply;
}

class VoiceEntryController extends GetxController {
  static VoiceEntryController get to => Get.find<VoiceEntryController>();

  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isSpeechInitialized = false;
  bool get isSpeechInitialized => _isSpeechInitialized;

  VoiceAssistantState _assistantState = VoiceAssistantState.idle;
  VoiceAssistantState get assistantState => _assistantState;

  bool get isListening => _assistantState == VoiceAssistantState.listening;
  bool get isThinking => _assistantState == VoiceAssistantState.thinking;
  bool get isSpeaking => _assistantState == VoiceAssistantState.speaking;

  // Talk Back Feature Controls
  bool _isTalkBackEnabled = true;
  bool get isTalkBackEnabled => _isTalkBackEnabled;

  String _talkBackLanguage = "hi-IN";
  String get talkBackLanguage => _talkBackLanguage;

  String _transcribedText = "";
  String get transcribedText => _transcribedText;

  String _aiReply = "";
  String get aiReply => _aiReply;

  // Parsed fields
  String parsedName = "";
  double parsedAmount = 0.0;
  String parsedType = ""; // "Given" or "Received" or ""
  bool get hasQuickEntry => parsedName.isNotEmpty && parsedAmount > 0;
  bool get hasCustomerSelection => parsedName.isNotEmpty;

  List<Map<String, dynamic>> voiceTransactions = [];
  List<String> recentVoiceContacts = [];

  final TextEditingController sandboxTextCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadTalkBackSettings();
    loadTransactions();
  }

  Future<void> initializeVoiceFeatures() async {
    await initSpeech();
    await initTts();
  }

  @override
  void onClose() {
    _flutterTts.stop();
    super.onClose();
  }

  void loadTalkBackSettings() {
    final savedToggle = HiveHelp.read('voice_talk_back_enabled');
    if (savedToggle != null) {
      _isTalkBackEnabled = savedToggle == true;
    }
    final savedLang = HiveHelp.read('voice_talk_back_lang');
    if (savedLang != null && savedLang.toString().isNotEmpty) {
      _talkBackLanguage = savedLang.toString();
    }
  }

  void toggleTalkBack(bool value) {
    _isTalkBackEnabled = value;
    HiveHelp.write('voice_talk_back_enabled', value);
    if (!value && isSpeaking) {
      stopSpeaking();
    }
    update();
  }

  Future<void> changeTalkBackLanguage(String lang) async {
    _talkBackLanguage = lang;
    HiveHelp.write('voice_talk_back_lang', lang);
    await _flutterTts.setLanguage(lang);
    update();
  }

  Future<void> initSpeech() async {
    try {
      _isSpeechInitialized = await _speechToText.initialize(
        onError: (val) {
          if (kDebugMode) print('Speech to text error: $val');
          _changeState(VoiceAssistantState.idle);
        },
        onStatus: (val) {
          if (kDebugMode) print('Speech to text status: $val');
          if (val == 'done' || val == 'notListening') {
            if (_assistantState == VoiceAssistantState.listening) {
              _processSpeech();
            }
          }
        },
      );
    } catch (e) {
      if (kDebugMode) print('Failed to init speech: $e');
      _isSpeechInitialized = false;
    }
    update();
  }

  Future<void> initTts() async {
    await _flutterTts.setLanguage(_talkBackLanguage);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      _changeState(VoiceAssistantState.idle);
    });
    _flutterTts.setErrorHandler((err) {
      if (kDebugMode) print("TTS error: $err");
      _changeState(VoiceAssistantState.idle);
    });
  }

  void _changeState(VoiceAssistantState newState) {
    _assistantState = newState;
    update();
  }

  Future<void> startListening() async {
    if (_assistantState == VoiceAssistantState.speaking) {
      await _flutterTts.stop();
    }

    if (!_isSpeechInitialized) {
      await initSpeech();
    }

    if (_isSpeechInitialized) {
      _transcribedText = "";
      _aiReply = "";
      _changeState(VoiceAssistantState.listening);

      await _speechToText.listen(
        onResult: (val) {
          _transcribedText = val.recognizedWords;
          update();
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 10),
        ),
      );
    } else {
      Helpers.showSnackBar(msg: "Speech recognition unavailable.");
    }
  }

  Future<void> stopListening() async {
    if (_assistantState == VoiceAssistantState.listening) {
      await _speechToText.stop();
    } else if (_assistantState == VoiceAssistantState.speaking) {
      await _flutterTts.stop();
      _changeState(VoiceAssistantState.idle);
    }
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _changeState(VoiceAssistantState.idle);
  }

  void parseSentence(String text) {
    _transcribedText = text;
    _processSpeech();
  }

  Future<void> _processSpeech() async {
    if (_transcribedText.trim().isEmpty) {
      _changeState(VoiceAssistantState.idle);
      return;
    }

    _changeState(VoiceAssistantState.thinking);

    final parsed = parseVoiceInstruction(_transcribedText);

    if (parsed.isQuery) {
      _aiReply = _calculateBalanceReply(
        parsed.name.isNotEmpty ? parsed.name : null,
      );
    } else if (parsed.isHelp) {
      _aiReply = parsed.reply;
    } else if (parsed.amount > 0) {
      parsedName = parsed.name;
      parsedAmount = parsed.amount;
      parsedType = parsed.type;
      _aiReply = parsed.reply;
      saveTransaction();
    } else {
      _aiReply = parsed.reply;
    }

    await speakReply(_aiReply);
  }

  VoiceParseResult parseVoiceInstruction(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return const VoiceParseResult(
        reply: 'Please say the customer name and amount clearly.',
      );
    }

    final lower = normalized.toLowerCase();
    final helpWords = [
      'hello',
      'hi',
      'help',
      'kya kar',
      'kaise',
      'what can',
      'namaste',
      'start',
      'kya hai',
    ];
    if (helpWords.any((word) => lower.contains(word))) {
      return const VoiceParseResult(
        isHelp: true,
        reply:
            'Namaste! Aap simple bol sakte hain: Ramesh ko 500 udhar diya, ya Suresh se 200 mil gaye.',
      );
    }

    final queryWords = [
      'kitna',
      'balance',
      'total',
      'baki',
      'hisab',
      'summary',
      'paisa',
      'paise',
      'lene',
      'kiska',
      'kaun',
      'how much',
    ];
    if (queryWords.any((word) => lower.contains(word))) {
      String cleaned =
          lower
              .replaceAll(
                RegExp(
                  r'\b(kitna|balance|total|baki|hisab|summary|paisa|paise|lene|kiska|kaun|hai|ka|ki|ko|se|ne|what|is|my|amount|tell|me|how|much)\b',
                ),
                '',
              )
              .trim();
      cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z\u0900-\u097F\s]'), ' ');
      final words =
          cleaned
              .split(RegExp(r'\s+'))
              .where((word) => word.isNotEmpty)
              .toList();
      final matchedName =
          words.isEmpty
              ? ''
              : words
                  .join(' ')
                  .split(' ')
                  .map((word) {
                    if (word.isEmpty) return word;
                    return word[0].toUpperCase() + word.substring(1);
                  })
                  .join(' ');
      return VoiceParseResult(isQuery: true, name: matchedName, reply: '');
    }

    final amountMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(lower);
    double amount = 0.0;
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1)!) ?? 0.0;
    }

    String type = 'Given';
    if (lower.contains('mila') ||
        lower.contains('mile') ||
        lower.contains('liya') ||
        lower.contains('received') ||
        lower.contains('paid') ||
        lower.contains('aaya') ||
        lower.contains('aaye')) {
      type = 'Received';
    } else if (lower.contains('diya') ||
        lower.contains('diye') ||
        lower.contains('de') ||
        lower.contains('udhar') ||
        lower.contains('given') ||
        lower.contains('gave')) {
      type = 'Given';
    }

    String cleaned =
        lower
            .replaceAll(RegExp(r'\d+(?:\.\d+)?'), '')
            .replaceAll(
              RegExp(
                r'\b(rupaye|rupees|rs|udhar|ko|se|ne|diya|diye|mila|mile|liya|paid|received|gave|given|hai|hain|aaya|aaye|de)\b',
              ),
              '',
            )
            .trim();
    cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z\u0900-\u097F\s]'), ' ');
    final words =
        cleaned.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    final name =
        words.isEmpty
            ? 'Customer'
            : words
                .map((word) {
                  if (word.isEmpty) return word;
                  return word[0].toUpperCase() + word.substring(1);
                })
                .join(' ');

    if (amount > 0) {
      final friendlyReply =
          type == 'Given'
              ? '$name ko ${amount.toInt()} rupaye udhar add ho gaye.'
              : '$name se ${amount.toInt()} rupaye mil gaye.';
      return VoiceParseResult(
        name: name,
        amount: amount,
        type: type,
        reply: friendlyReply,
      );
    }

    return const VoiceParseResult(
      reply: 'Please say the amount clearly, like 500 or 200.',
    );
  }

  Future<void> openQuickAddEntry() async {
    if (!hasQuickEntry) {
      Helpers.showSnackBar(
        msg: 'Say a phrase like “Ramesh ko 500 udhar diya” first.',
      );
      return;
    }

    Get.toNamed(
      RoutesName.addUdharScreen,
      arguments: {
        'name': parsedName,
        'amount': parsedAmount,
        'type': parsedType.isEmpty ? 'Given' : parsedType,
      },
    );
  }

  Future<void> saveParsedEntryDirectly() async {
    if (!hasQuickEntry) {
      Helpers.showSnackBar(
        msg: 'Say a phrase like “Ramesh ko 500 udhar diya” first.',
      );
      return;
    }

    if (!Get.isRegistered<UdharController>()) {
      Get.put(UdharController());
    }

    final udharController = Get.find<UdharController>();
    udharController.applyVoiceEntryPrefill(
      name: parsedName,
      amount: parsedAmount,
      type: parsedType.isEmpty ? 'Given' : parsedType,
    );
    await udharController.submitUdhar();
  }

  String _calculateBalanceReply(String? targetName) {
    try {
      List<dynamic> users = [];
      if (Get.isRegistered<UdharController>()) {
        users = List<dynamic>.from(Get.find<UdharController>().usersList);
      }
      if (users.isEmpty) {
        final cached = HiveHelp.read('cached_users');
        if (cached != null && cached is List) {
          users = cached;
        }
      }

      // Check if asking for a specific customer
      if (targetName != null &&
          targetName.trim().isNotEmpty &&
          targetName.toLowerCase() != "unknown" &&
          targetName.toLowerCase() != "customer") {
        String queryName = targetName.trim().toLowerCase();

        double customerBalance = 0.0;
        bool found = false;
        String actualName = targetName.trim();

        for (var u in users) {
          if (u is Map) {
            String uName = (u['name'] ?? '').toString();
            if (uName.toLowerCase().contains(queryName) ||
                queryName.contains(uName.toLowerCase())) {
              found = true;
              actualName = uName;
              customerBalance =
                  double.tryParse(
                    u['outstanding_balance']?.toString() ??
                        u['balance']?.toString() ??
                        '0',
                  ) ??
                  0.0;
              break;
            }
          }
        }

        for (var tx in voiceTransactions) {
          String txName = (tx['name'] ?? '').toString();
          if (txName.toLowerCase().contains(queryName) ||
              queryName.contains(txName.toLowerCase())) {
            found = true;
            if (tx['type'] == 'Given') {
              customerBalance += (tx['amount'] ?? 0).toDouble();
            } else if (tx['type'] == 'Received') {
              customerBalance -= (tx['amount'] ?? 0).toDouble();
            }
          }
        }

        if (!found) {
          return "$targetName naam ka customer list mein nahi mila, par aap bolkar unka udhar add kar sakte hain.";
        } else if (customerBalance > 0) {
          return "$actualName ka kul udhar balance ${customerBalance.toInt()} rupaye baki hai.";
        } else if (customerBalance < 0) {
          return "$actualName ke paas aapke ${(-customerBalance).toInt()} rupaye advance jama hain.";
        } else {
          return "$actualName ka hisab clear hai, koi udhar baki nahi hai.";
        }
      }

      // Total overall balance query
      double totalBalance = 0.0;
      int count = 0;
      for (var u in users) {
        if (u is Map) {
          count++;
          totalBalance +=
              double.tryParse(
                u['outstanding_balance']?.toString() ??
                    u['balance']?.toString() ??
                    '0',
              ) ??
              0.0;
        }
      }

      for (var tx in voiceTransactions) {
        if (tx['type'] == 'Given') {
          totalBalance += (tx['amount'] ?? 0).toDouble();
        } else if (tx['type'] == 'Received') {
          totalBalance -= (tx['amount'] ?? 0).toDouble();
        }
      }

      if (totalBalance > 0) {
        return "Aapka kul udhar balance ${totalBalance.toInt()} rupaye baki hai. Kul $count customers hain.";
      } else {
        return "Aapka koi udhar baki nahi hai. Sabhi hisab clear hain.";
      }
    } catch (e) {
      if (kDebugMode) print("Error calculating balance reply: $e");
      return "Balance check karne mein error aayi, kripya dobara try karein.";
    }
  }

  Future<void> talkBackTransaction(Map<String, dynamic> tx) async {
    String name = tx['name'] ?? "Unknown";
    double amt = (tx['amount'] ?? 0).toDouble();
    bool isRec = tx['type'] == 'Received';
    String speech =
        isRec
            ? "$name se ${amt.toInt()} rupaye mil gaye hai."
            : "$name ko ${amt.toInt()} rupaye udhar diye hai.";
    _aiReply = speech;
    update();
    await speakReply(speech);
  }

  Future<void> speakReply(String text) async {
    if (!_isTalkBackEnabled || text.trim().isEmpty) {
      _changeState(VoiceAssistantState.idle);
      return;
    }
    _changeState(VoiceAssistantState.speaking);
    await _flutterTts.speak(text);
  }

  void saveTransaction() {
    if (parsedName.isEmpty || parsedName == "Unknown" || parsedAmount <= 0) {
      return;
    }

    Map<String, dynamic> newTx = {
      "name": parsedName,
      "amount": parsedAmount,
      "type": parsedType,
      "date": DateTime.now().toString(),
    };

    if (parsedName.trim().isNotEmpty) {
      recentVoiceContacts.remove(parsedName.trim());
      recentVoiceContacts.insert(0, parsedName.trim());
      recentVoiceContacts = recentVoiceContacts.take(5).toList();
      HiveHelp.write('voice_recent_contacts', recentVoiceContacts);
    }

    voiceTransactions.insert(0, newTx);

    List<String> jsonList =
        voiceTransactions.map((tx) => jsonEncode(tx)).toList();
    HiveHelp.write('voice_transactions', jsonList);

    sandboxTextCtrl.clear();
    update();
  }

  void deleteTransaction(int index) {
    if (index >= 0 && index < voiceTransactions.length) {
      voiceTransactions.removeAt(index);
      List<String> jsonList =
          voiceTransactions.map((tx) => jsonEncode(tx)).toList();
      HiveHelp.write('voice_transactions', jsonList);
      update();
    }
  }

  void loadTransactions() {
    dynamic savedData = HiveHelp.read('voice_transactions');
    if (savedData != null && savedData is List) {
      voiceTransactions =
          savedData.map((e) {
            return Map<String, dynamic>.from(jsonDecode(e.toString()));
          }).toList();
    } else {
      voiceTransactions = [];
    }

    final savedContacts = HiveHelp.read('voice_recent_contacts');
    if (savedContacts is List) {
      recentVoiceContacts = savedContacts.map((e) => e.toString()).toList();
    } else {
      recentVoiceContacts = [];
    }
    update();
  }

  Future<void> useRecentContact(String contactName) async {
    if (contactName.trim().isEmpty) return;
    sandboxTextCtrl.text = contactName;
    parsedName = contactName.trim();
    parsedAmount = 0;
    parsedType = 'Given';
    update();
    await openQuickAddEntry();
  }

  void postToUdharLedger(Map<String, dynamic> tx) {
    Get.toNamed(
      RoutesName.addUdharScreen,
      arguments: {
        "name": tx["name"],
        "amount": tx["amount"],
        "type": tx["type"],
      },
    );
  }
}

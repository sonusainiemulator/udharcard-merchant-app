import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/services/localstorage/hive.dart';
import '../utils/services/helpers.dart';
import '../routes/routes_name.dart';

enum VoiceAssistantState { idle, listening, thinking, speaking }

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

  List<Map<String, dynamic>> voiceTransactions = [];

  final TextEditingController sandboxTextCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadTalkBackSettings();
    initSpeech();
    initTts();
    loadTransactions();
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
        listenOptions: SpeechListenOptions(listenFor: const Duration(seconds: 10)),
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

    // Try Gemini AI first, with fallback to local Regex & Query NLP parser
    bool processedWithAi = false;
    try {
      await dotenv.load();
      final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();
      if (apiKey != null && apiKey.isNotEmpty && !apiKey.contains('Xxxx')) {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
        );

        final prompt = '''
You are an AI assistant for a merchant's Udhar (credit ledger) app with real-time "Talk Back" voice capabilities.
The user speaks in Hindi, English, or Hinglish.
Extract intent and return strictly valid JSON without markdown or backticks.

1. If user wants to ADD a transaction (e.g. "Ramesh ko 500 udhar diye", "Received 300 from Suresh", "Suresh se 200 mile"):
{
  "action": "add_udhar",
  "name": "Customer Name (Capitalized)",
  "amount": 500,
  "type": "Given", // or "Received"
  "reply": "Okay, Ramesh ko 500 rupaye udhar diye hai."
}

2. If user asks about BALANCE, TOTAL UDHAR, or CUSTOMER LEDGER (e.g. "Total udhar kitna hai?", "Ramesh ka balance kitna hai?", "Kitne paise lene hai?", "Summary batao"):
{
  "action": "query_balance",
  "name": "Ramesh", // empty string "" if asking total balance
  "reply": "" // leave empty, will be calculated from live ledger
}

3. If user asks for HELP, GREETING, or general questions (e.g. "Help", "Tum kya kar sakte ho?", "Hello"):
{
  "action": "help",
  "reply": "Namaste! Main aapka Udhar Voice Assistant hoon. Talk back feature active hai. Aap bol sakte hain: Ramesh ko 500 udhar diye, ya Total balance kitna hai."
}

User's speech: "$_transcribedText"
''';

        final response = await model.generateContent([Content.text(prompt)]);
        final textResp = response.text ?? '';
        final jsonStr = textResp.replaceAll('```json', '').replaceAll('```', '').trim();
        
        if (jsonStr.isNotEmpty && jsonStr.startsWith('{')) {
          final Map<String, dynamic> data = jsonDecode(jsonStr);

          if (data['action'] == 'add_udhar') {
            parsedName = data['name'] ?? "Unknown";
            parsedAmount = (data['amount'] ?? 0).toDouble();
            parsedType = data['type'] ?? "Given";
            _aiReply = data['reply'] ?? "Transaction recorded.";
            saveTransaction();
            processedWithAi = true;
          } else if (data['action'] == 'query_balance') {
            final targetName = data['name']?.toString();
            _aiReply = _calculateBalanceReply(targetName);
            processedWithAi = true;
          } else if (data['action'] == 'help') {
            _aiReply = data['reply'] ??
                "Namaste! Main aapka Udhar Voice Assistant hoon. Talk back feature active hai. Aap bol sakte hain: Ramesh ko 500 udhar diye, ya Total balance kitna hai.";
            processedWithAi = true;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print("Gemini Error, falling back to local NLP: $e");
    }

    // Local Regex NLP Fallback (Offline Mode for Actions & Queries)
    if (!processedWithAi) {
      _processOfflineSpeech(_transcribedText);
    }

    await speakReply(_aiReply);
  }

  void _processOfflineSpeech(String text) {
    String lower = text.toLowerCase();
    
    // 1. Check for Query keywords (Talk Back balance & summary queries)
    final queryWords = ['kitna', 'balance', 'total', 'baki', 'hisab', 'summary', 'query', 'paisa', 'paise', 'lene', 'kaun', 'kiska', 'how much'];
    final bool isQuery = queryWords.any((w) => lower.contains(w));

    // 2. Check for Help / Greeting keywords
    final helpWords = ['hello', 'hi', 'help', 'kya kar', 'kaise', 'what can', 'namaste', 'start', 'kya hai'];
    final bool isHelp = helpWords.any((w) => lower.contains(w));

    if (isQuery) {
      // Try to extract a customer name if mentioned
      String cleaned = lower
          .replaceAll(RegExp(r'\b(kitna|balance|total|baki|hisab|summary|query|paisa|paise|lene|kaun|kiska|hai|ka|ki|ko|se|ne|what|is|my|amount|tell|me)\b'), '')
          .trim();
      List<String> words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      String? matchedName;
      if (words.isNotEmpty && words.first.length > 2) {
        matchedName = words.first[0].toUpperCase() + words.first.substring(1);
      }
      _aiReply = _calculateBalanceReply(matchedName);
      return;
    }

    if (isHelp && !lower.contains("diya") && !lower.contains("mila")) {
      _aiReply = "Namaste! Main aapka Udhar Voice Assistant hoon. Talk back feature active hai. Aap bol sakte hain: Ramesh ko 500 udhar diye, ya Total balance kitna hai.";
      return;
    }

    // 3. Extract numbers/amount for transactions
    final amountMatch = RegExp(r'(\d+)').firstMatch(lower);
    double amount = 0.0;
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1)!) ?? 0.0;
    }

    // Determine type (Given / Received)
    String type = "Given";
    if (lower.contains("mila") ||
        lower.contains("mile") ||
        lower.contains("liya") ||
        lower.contains("received") ||
        lower.contains("paid") ||
        lower.contains("aaye")) {
      type = "Received";
    } else if (lower.contains("diya") ||
        lower.contains("diye") ||
        lower.contains("udhar") ||
        lower.contains("given") ||
        lower.contains("gave")) {
      type = "Given";
    }

    // Clean text to extract name
    String cleaned = lower
        .replaceAll(RegExp(r'\d+'), '')
        .replaceAll(RegExp(r'\b(rupaye|rupees|rs|udhar|ko|se|ne|diya|diye|mila|mile|liya|paid|received|gave|given|hai|hain)\b'), '')
        .trim();

    List<String> words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    String name = "Customer";
    if (words.isNotEmpty) {
      name = words.first[0].toUpperCase() + words.first.substring(1);
    }

    if (amount > 0) {
      parsedName = name;
      parsedAmount = amount;
      parsedType = type;

      if (type == "Given") {
        _aiReply = "$name ko ${amount.toInt()} rupaye udhar add ho gaye.";
      } else {
        _aiReply = "$name se ${amount.toInt()} rupaye mil gaye.";
      }
      saveTransaction();
    } else {
      _aiReply = "Samajh nahi aaya. Kripya bolo: Ramesh ko 500 udhar diya, ya Total balance kitna hai.";
    }
  }

  String _calculateBalanceReply(String? targetName) {
    try {
      final cached = HiveHelp.read('cached_users');
      List<dynamic> users = [];
      if (cached != null && cached is List) {
        users = cached;
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
            if (uName.toLowerCase().contains(queryName) || queryName.contains(uName.toLowerCase())) {
              found = true;
              actualName = uName;
              customerBalance = double.tryParse(
                u['outstanding_balance']?.toString() ?? u['balance']?.toString() ?? '0',
              ) ?? 0.0;
              break;
            }
          }
        }

        for (var tx in voiceTransactions) {
          String txName = (tx['name'] ?? '').toString();
          if (txName.toLowerCase().contains(queryName) || queryName.contains(txName.toLowerCase())) {
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
          totalBalance += double.tryParse(
            u['outstanding_balance']?.toString() ?? u['balance']?.toString() ?? '0',
          ) ?? 0.0;
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
    String speech = isRec
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

    voiceTransactions.insert(0, newTx);
    
    List<String> jsonList = voiceTransactions.map((tx) => jsonEncode(tx)).toList();
    HiveHelp.write('voice_transactions', jsonList);

    parsedName = "";
    parsedAmount = 0.0;
    parsedType = "";
    sandboxTextCtrl.clear();
    
    update();
  }

  void deleteTransaction(int index) {
    if (index >= 0 && index < voiceTransactions.length) {
      voiceTransactions.removeAt(index);
      List<String> jsonList = voiceTransactions.map((tx) => jsonEncode(tx)).toList();
      HiveHelp.write('voice_transactions', jsonList);
      update();
    }
  }

  void loadTransactions() {
    dynamic savedData = HiveHelp.read('voice_transactions');
    if (savedData != null && savedData is List) {
      voiceTransactions = savedData.map((e) {
        return Map<String, dynamic>.from(jsonDecode(e.toString()));
      }).toList();
    } else {
      voiceTransactions = [];
    }
    update();
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

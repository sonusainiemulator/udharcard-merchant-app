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
    initSpeech();
    initTts();
    loadTransactions();
  }

  @override
  void onClose() {
    _flutterTts.stop();
    super.onClose();
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
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
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
        listenFor: const Duration(seconds: 10),
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

    // Try Gemini AI first, with fallback to local Regex parser
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
You are an AI assistant for a merchant's Udhar (credit ledger) app.
The user speaks in a mix of Hindi and English (Hinglish).
Extract the following information from the user's speech to record a transaction:
- Name of the customer (Capitalize first letter).
- Amount (as a number).
- Type: "Given" (merchant gave udhar/loan/credit) or "Received" (merchant received payment).
- Reply: A very short, friendly confirmation message in Roman Hinglish that you will speak back to the user. (e.g. "Okay, Pankaj ko 500 rupaye udhar diye.")

If the user asks a general question, respond with action "unknown" and say "I can only add transactions right now." in the reply.

Output MUST be strictly valid JSON without any markdown or backticks. Format:
{
  "action": "add_udhar",
  "name": "Pankaj",
  "amount": 500,
  "type": "Given",
  "reply": "Okay, Pankaj ko 500 rupaye udhar diye hai."
}

User's speech: "$_transcribedText"
''';

        final response = await model.generateContent([Content.text(prompt)]);
        final jsonStr = response.text?.replaceAll('```json', '')?.replaceAll('```', '')?.trim() ?? '{}';
        
        final Map<String, dynamic> data = jsonDecode(jsonStr);

        if (data['action'] == 'add_udhar') {
          parsedName = data['name'] ?? "Unknown";
          parsedAmount = (data['amount'] ?? 0).toDouble();
          parsedType = data['type'] ?? "Given";
          _aiReply = data['reply'] ?? "Transaction recorded.";
          saveTransaction();
          processedWithAi = true;
        }
      }
    } catch (e) {
      if (kDebugMode) print("Gemini Error, falling back to local NLP: $e");
    }

    // Local Regex NLP Fallback (Offline Mode)
    if (!processedWithAi) {
      _processOfflineSpeech(_transcribedText);
    }

    await _speakReply(_aiReply);
  }

  void _processOfflineSpeech(String text) {
    String lower = text.toLowerCase();
    
    // Extract numbers/amount
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
        .replaceAll(RegExp(r'\b(rupaye|rupees|rs|udhar|ko|se|ne|diya|diye|mila|mile|liya|paid|received|gave|given)\b'), '')
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
      _aiReply = "Samajh nahi aaya. Kripya bolo: Ramesh ko 500 udhar diya.";
    }
  }

  Future<void> _speakReply(String text) async {
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
}

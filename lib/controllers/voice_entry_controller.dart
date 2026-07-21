import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../utils/services/localstorage/hive.dart';
import '../utils/services/helpers.dart';

class VoiceEntryController extends GetxController {
  static VoiceEntryController get to => Get.find<VoiceEntryController>();

  final SpeechToText _speechToText = SpeechToText();
  
  bool _isSpeechInitialized = false;
  bool get isSpeechInitialized => _isSpeechInitialized;

  bool _isListening = false;
  bool get isListening => _isListening;

  String _transcribedText = "";
  String get transcribedText => _transcribedText;

  // Parsed fields
  String parsedName = "";
  double parsedAmount = 0.0;
  String parsedType = ""; // "Given" or "Received" or ""

  // History list
  List<Map<String, dynamic>> voiceTransactions = [];

  final TextEditingController sandboxTextCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    initSpeech();
    loadTransactions();
  }

  Future<void> initSpeech() async {
    try {
      _isSpeechInitialized = await _speechToText.initialize(
        onError: (val) {
          if (kDebugMode) print('Speech to text error: $val');
          _isListening = false;
          update();
        },
        onStatus: (val) {
          if (kDebugMode) print('Speech to text status: $val');
          if (val == 'done' || val == 'notListening') {
            _isListening = false;
          }
          update();
        },
      );
    } catch (e) {
      if (kDebugMode) print('Failed to initialize speech to text: $e');
      _isSpeechInitialized = false;
    }
    update();
  }

  Future<void> startListening() async {
    if (!_isSpeechInitialized) {
      await initSpeech();
    }
    
    if (_isSpeechInitialized) {
      _transcribedText = "";
      _isListening = true;
      update();
      
      await _speechToText.listen(
        onResult: (val) {
          _transcribedText = val.recognizedWords;
          if (kDebugMode) print("Recognized: $_transcribedText");
          parseSentence(_transcribedText);
          update();
        },
      );
    } else {
      Helpers.showSnackBar(msg: "Speech recognition is not available on this device.");
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      update();
    }
  }

  void parseSentence(String text) {
    if (text.isEmpty) {
      parsedName = "";
      parsedAmount = 0.0;
      parsedType = "";
      update();
      return;
    }

    String lowerText = text.toLowerCase();

    // 1. Parse Amount
    RegExp digitRegex = RegExp(r'\b\d+\b');
    Match? match = digitRegex.firstMatch(lowerText);
    if (match != null) {
      parsedAmount = double.tryParse(match.group(0)!) ?? 0.0;
    } else {
      parsedAmount = 0.0;
    }

    // 2. Parse Transaction Type (Given/Received)
    List<String> givenKeywords = [
      'udhar', 'udhaar', 'diya', 'given', 'gave', 'paid', 'spent', 'pay', 
      'out', 'de diya', 'dediya', 'pay kiya', 'paykiya', 'lent', 'loan'
    ];
    List<String> receivedKeywords = [
      'jama', 'liya', 'received', 'got', 'mila', 'receive', 'mil gaya', 
      'milgaya', 'milla', 'in', 'lia', 'le liya', 'leliya', 'received kiya'
    ];

    bool isGiven = false;
    bool isReceived = false;

    for (var word in givenKeywords) {
      if (lowerText.contains(word)) {
        isGiven = true;
        break;
      }
    }

    for (var word in receivedKeywords) {
      if (lowerText.contains(word)) {
        isReceived = true;
        break;
      }
    }

    if (isGiven && !isReceived) {
      parsedType = "Given";
    } else if (isReceived && !isGiven) {
      parsedType = "Received";
    } else if (isGiven && isReceived) {
      // If both are found, inspect which keyword appears first or prioritize
      int givenIdx = 9999;
      int recIdx = 9999;
      for (var word in givenKeywords) {
        int idx = lowerText.indexOf(word);
        if (idx != -1 && idx < givenIdx) givenIdx = idx;
      }
      for (var word in receivedKeywords) {
        int idx = lowerText.indexOf(word);
        if (idx != -1 && idx < recIdx) recIdx = idx;
      }
      parsedType = (givenIdx < recIdx) ? "Given" : "Received";
    } else {
      // Default fallback based on common Hinglish verbs if not matched
      parsedType = "Given"; 
    }

    // 3. Parse Name
    // Split the sentence and filter out helper words, digits, and transaction keywords
    List<String> stopWords = [
      'ne', 'ko', 'se', 'kiya', 'le', 'de', 'me', 'to', 'for', 'from', 'rs', 'rupees',
      'rupee', 'rupay', 'rupe', 'ka', 'ki', 'ke', 'ta', 'tha', 'hai', 'and', 'the',
      'a', 'an', 'is', 'was', 'were', 'are', 'of', 'in', 'on', 'at', 'with', 'by', 'i'
    ];

    List<String> words = text.split(RegExp(r'\s+'));
    List<String> nameParts = [];

    for (var word in words) {
      String cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
      
      // Skip if it's a number
      if (RegExp(r'^\d+$').hasMatch(cleanWord)) continue;
      
      // Skip if it's empty or a stop word
      if (cleanWord.isEmpty || stopWords.contains(cleanWord)) continue;
      
      // Skip if it is a transaction type keyword
      if (givenKeywords.contains(cleanWord) || receivedKeywords.contains(cleanWord)) continue;

      // CleanWord looks like a valid name part
      nameParts.add(word); // Keep original casing
    }

    if (nameParts.isNotEmpty) {
      // Reassemble and capitalize name
      String joinedName = nameParts.join(" ");
      parsedName = joinedName.split(" ").map((w) {
        if (w.isEmpty) return "";
        return w[0].toUpperCase() + w.substring(1);
      }).join(" ");
    } else {
      parsedName = "Unknown";
    }

    update();
  }

  void saveTransaction() {
    if (parsedName.isEmpty || parsedName == "Unknown" || parsedAmount <= 0) {
      Helpers.showSnackBar(msg: "Please make sure Name and Amount are parsed correctly before saving.");
      return;
    }

    Map<String, dynamic> newTx = {
      "name": parsedName,
      "amount": parsedAmount,
      "type": parsedType,
      "date": DateTime.now().toString(),
    };

    voiceTransactions.insert(0, newTx);
    
    // Save to Hive
    List<String> jsonList = voiceTransactions.map((tx) => jsonEncode(tx)).toList();
    HiveHelp.write('voice_transactions', jsonList);

    // Reset current parsed item
    parsedName = "";
    parsedAmount = 0.0;
    parsedType = "";
    _transcribedText = "";
    sandboxTextCtrl.clear();
    
    update();
    Helpers.showSnackBar(msg: "Transaction added successfully.");
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

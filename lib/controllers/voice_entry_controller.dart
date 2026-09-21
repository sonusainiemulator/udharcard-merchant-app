import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'udhar_controller.dart';
import '../utils/services/localstorage/hive.dart';
import '../utils/services/helpers.dart';
import '../routes/routes_name.dart';

enum VoiceAssistantState { idle, listening, thinking, speaking }

enum GeminiAiMode {
  geminiLive,
  geminiExtendedThinking,
}

class VoiceBillItem {
  final String title;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;

  const VoiceBillItem({
    required this.title,
    this.quantity = 1.0,
    this.unit = '',
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'quantity': quantity,
        'unit': unit,
        'unit_price': unitPrice,
        'total_price': totalPrice,
      };

  factory VoiceBillItem.fromMap(Map<String, dynamic> map) => VoiceBillItem(
        title: map['title'] ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
        unit: map['unit'] ?? '',
        unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
        totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      );
}

class VoiceParseResult {
  const VoiceParseResult({
    this.name = '',
    this.phone = '',
    this.amount = 0.0,
    this.type = 'Given', // 'Given', 'Received', 'PurchaseOrder'
    this.category = 'UDHAR', // 'UDHAR', 'COLLECTION', 'BILL', 'PURCHASE'
    this.isQuery = false,
    this.isHelp = false,
    this.isPurchaseOrder = false,
    this.items = const [],
    this.purchaseItems = const [],
    this.reply = '',
    this.isPaid = false,
    this.remarks = '',
    this.matchedCustomer,
  });

  final String name;
  final String phone;
  final double amount;
  final String type;
  final String category;
  final bool isQuery;
  final bool isHelp;
  final bool isPurchaseOrder;
  final List<VoiceBillItem> items;
  final List<String> purchaseItems;
  final String reply;
  final bool isPaid;
  final String remarks;
  final Map<String, dynamic>? matchedCustomer;
}

class VoiceEntryController extends GetxController {
  static VoiceEntryController get to => Get.find<VoiceEntryController>();

  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final ImagePicker _picker = ImagePicker();

  bool _isSpeechInitialized = false;
  bool get isSpeechInitialized => _isSpeechInitialized;

  VoiceAssistantState _assistantState = VoiceAssistantState.idle;
  VoiceAssistantState get assistantState => _assistantState;

  bool get isListening => _assistantState == VoiceAssistantState.listening;
  bool get isThinking => _assistantState == VoiceAssistantState.thinking;
  bool get isSpeaking => _assistantState == VoiceAssistantState.speaking;
  bool get isIdle => _assistantState == VoiceAssistantState.idle;

  // Talk Back Feature Controls
  bool _isTalkBackEnabled = true;
  bool get isTalkBackEnabled => _isTalkBackEnabled;

  String _talkBackLanguage = "hi-IN";
  String get talkBackLanguage => _talkBackLanguage;

  String _selectedSpeechLocale = "hi_IN";
  String get selectedSpeechLocale => _selectedSpeechLocale;
  List<LocaleName> availableSpeechLocales = [];

  void setSpeechLocale(String localeId) {
    _selectedSpeechLocale = localeId;
    HiveHelp.write('voice_speech_locale', localeId);
    update();
  }

  void toggleSpeechLocale() {
    if (_selectedSpeechLocale.toLowerCase().startsWith('hi')) {
      setSpeechLocale('en_IN');
    } else {
      setSpeechLocale('hi_IN');
    }
  }

  String _resolveSpeechLocale() {
    final saved = HiveHelp.read('voice_speech_locale')?.toString();
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }
    final prefersHindi = _talkBackLanguage.startsWith('hi');
    final targetCandidates = prefersHindi
        ? ['hi_IN', 'hi-IN', 'en_IN', 'en-IN']
        : ['en_IN', 'en-IN', 'hi_IN', 'hi-IN'];

    for (final cand in targetCandidates) {
      for (final loc in availableSpeechLocales) {
        if (loc.localeId.toLowerCase().replaceAll('-', '_') ==
            cand.toLowerCase().replaceAll('-', '_')) {
          return loc.localeId;
        }
      }
    }
    return availableSpeechLocales.isNotEmpty
        ? availableSpeechLocales.first.localeId
        : 'hi_IN';
  }

  static String normalizeTransactionType(dynamic rawType, dynamic rawAction) {
    final t = (rawType ?? '').toString().toLowerCase().trim();
    final a = (rawAction ?? '').toString().toLowerCase().trim();
    if (t == 'received' ||
        t == 'jama' ||
        t == 'mila' ||
        t == 'mile' ||
        t == 'credit' ||
        t.contains('receiv') ||
        t.contains('collect') ||
        a.contains('receiv') ||
        a.contains('collect')) {
      return 'Received';
    }
    return 'Given';
  }

  String _transcribedText = "";
  String get transcribedText => _transcribedText;

  String _aiReply = "";
  String get aiReply => _aiReply;

  bool isUsingGeminiAi = false;
  bool isLiveMode = false;
  GeminiAiMode activeGeminiMode = GeminiAiMode.geminiLive;
  bool get isExtendedThinking => activeGeminiMode == GeminiAiMode.geminiExtendedThinking;

  // Active Category Filter
  String activeCategory = 'ALL'; // 'ALL', 'UDHAR', 'COLLECTION', 'BILL', 'PURCHASE'

  // Parsed fields
  String parsedName = "";
  double parsedAmount = 0.0;
  String parsedType = "Given"; // "Given" or "Received"
  String parsedRemarks = "";
  String parsedPhone = "";
  VoiceParseResult? latestParsedResult;
  XFile? attachedBillImage;
  bool isSubmittingEntry = false;
  bool _isProcessingSpeech = false;

  void adjustParsedAmount(double delta) {
    parsedAmount = (parsedAmount + delta).clamp(0.0, 9999999.0);
    update();
  }

  void setParsedAmount(double newAmount) {
    parsedAmount = newAmount.clamp(0.0, 9999999.0);
    update();
  }

  void setParsedPhone(String phone) {
    parsedPhone = phone.trim();
    update();
  }

  bool get hasQuickEntry =>
      (parsedName.isNotEmpty && parsedAmount > 0) ||
      (latestParsedResult != null &&
          latestParsedResult!.isPurchaseOrder &&
          latestParsedResult!.purchaseItems.isNotEmpty);
  bool get hasCustomerSelection => parsedName.isNotEmpty;

  List<Map<String, dynamic>> voiceTransactions = [];
  List<Map<String, dynamic>> purchaseOrders = [];
  List<String> recentVoiceContacts = [];

  final TextEditingController sandboxTextCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadTalkBackSettings();
    loadTransactions();
    loadPurchaseOrders();
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

  void setActiveCategory(String cat) {
    activeCategory = cat;
    update();
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

  void toggleLiveMode() {
    isLiveMode = !isLiveMode;
    HapticFeedback.heavyImpact();
    if (isLiveMode) {
      if (!isListening && !isSpeaking) {
        startListening();
      }
      Helpers.showSnackBar(
        msg: "Gemini Live mode ON: Continuous hands-free voice assistant active.",
        title: "Gemini Live Active",
      );
    } else {
      if (isListening) {
        stopListening();
      }
      Helpers.showSnackBar(
        msg: "Gemini Live mode paused.",
        title: "Live Mode Paused",
      );
    }
    update();
  }

  void toggleExtendedThinking() {
    if (activeGeminiMode == GeminiAiMode.geminiExtendedThinking) {
      activeGeminiMode = GeminiAiMode.geminiLive;
      Helpers.showSnackBar(
        msg: "Gemini 3.8 Live active (Ultra-Fast 3.8 Flash Mode)",
        title: "Gemini 3.8 Live",
      );
    } else {
      activeGeminiMode = GeminiAiMode.geminiExtendedThinking;
      Helpers.showSnackBar(
        msg: "Gemini 3.8 Live Extended Thinking active (Deep Reasoning & Calculation Mode)",
        title: "Gemini 3.8 Extended Thinking",
      );
    }
    HapticFeedback.mediumImpact();
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
          if (_transcribedText.trim().isNotEmpty && !_isProcessingSpeech) {
            _processSpeech();
          } else {
            _changeState(VoiceAssistantState.idle);
          }
        },
        onStatus: (val) {
          if (kDebugMode) print('Speech to text status: $val');
          if (val == 'done' || val == 'notListening') {
            if (_assistantState == VoiceAssistantState.listening && !_isProcessingSpeech) {
              _processSpeech();
            }
          }
        },
      );
      if (_isSpeechInitialized) {
        try {
          availableSpeechLocales = await _speechToText.locales();
          _selectedSpeechLocale = _resolveSpeechLocale();
        } catch (_) {}
      }
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
      // Continuous hands-free live listening loop in Gemini Live mode
      if (isLiveMode) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (isLiveMode && !isListening && !isSpeaking) {
            startListening();
          }
        });
      }
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

  Future<void> toggleListening() async {
    if (isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  Future<void> startListening() async {
    HapticFeedback.mediumImpact();
    if (_assistantState == VoiceAssistantState.speaking) {
      await _flutterTts.stop();
    }

    if (!_isSpeechInitialized) {
      await initSpeech();
    }

    if (_isSpeechInitialized) {
      _transcribedText = "";
      _aiReply = "";
      latestParsedResult = null;
      _changeState(VoiceAssistantState.listening);

      await _speechToText.listen(
        onResult: (val) {
          _transcribedText = val.recognizedWords;
          if (_transcribedText.trim().isNotEmpty) {
            final liveParsed = parseVoiceInstruction(_transcribedText);
            if (liveParsed.amount > 0 || liveParsed.isPurchaseOrder) {
              latestParsedResult = liveParsed;
              parsedName = liveParsed.name;
              parsedAmount = liveParsed.amount;
              parsedType = liveParsed.type;
              parsedRemarks = liveParsed.remarks;
            }
          }
          update();
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          localeId: _selectedSpeechLocale,
        ),
      );
    } else {
      Helpers.showSnackBar(msg: "Speech recognition unavailable. Check microphone permissions.");
    }
  }

  Future<void> stopListening() async {
    HapticFeedback.lightImpact();
    if (_assistantState == VoiceAssistantState.listening) {
      await _speechToText.stop();
      _processSpeech();
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

  Future<void> pickBillImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1200,
      );
      if (image != null) {
        attachedBillImage = image;
        update();
        Helpers.showSnackBar(msg: "Bill photo attached successfully.", title: "Attached");
      }
    } catch (e) {
      if (kDebugMode) print("Error picking bill image: $e");
    }
  }

  void clearAttachedBillImage() {
    attachedBillImage = null;
    update();
  }

  /// Google Gemini AI Parser supporting:
  /// 1. Gemini Live (Fast Conversational Real-Time Voice - gemini-3.6-flash)
  /// 2. Gemini Extended Thinking (Deep Arithmetic & Complex Ledger Reasoning - gemini-3.1-pro-preview)
  Future<VoiceParseResult?> _parseWithGemini(String speechText) async {
    final apiKey = (dotenv.env['GEMINI_API_KEY'] ?? '').trim();
    if (apiKey.isEmpty || apiKey.length < 10) {
      isUsingGeminiAi = false;
      return null;
    }

    final bool useThinking = activeGeminiMode == GeminiAiMode.geminiExtendedThinking;

    // Resolve model name based on active mode and .env settings (Gemini 3.8 Live / 3.8 Extended Thinking)
    String modelName;
    if (useThinking) {
      final envThinking = (dotenv.env['GEMINI_THINKING_MODEL'] ?? '').trim();
      modelName = envThinking.isNotEmpty ? envThinking : 'gemini-3.8-flash';
    } else {
      final envLive = (dotenv.env['GEMINI_LIVE_MODEL'] ?? dotenv.env['GEMINI_MODEL'] ?? '').trim();
      modelName = envLive.isNotEmpty ? envLive : 'gemini-3.8-flash';
    }

    if (modelName.contains('2.0') || modelName.contains('2.5') || modelName.contains('3.6') || modelName.contains('3.1')) {
      modelName = 'gemini-3.8-flash';
    }

    try {
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: useThinking ? 0.2 : 0.1,
        ),
      );

      final String prompt;
      if (useThinking) {
        prompt = '''
You are an advanced retail accounting AI with Extended Thinking capabilities (Gemini 3.8 Live Extended Thinking) for an Indian merchant ledger app (UdharCard).
The merchant speaks in Hindi, Hinglish, or English.
Carefully perform step-by-step arithmetic reasoning and ledger disambiguation before generating JSON.

Extended Thinking Reasoning Guidelines:
1. Multi-Item Calculations:
   - If user says item quantities and rates (e.g., "5 kg chini 42 rupaye, aur 2 packet tel 120 rupaye"), compute:
     chini = 5 * 42 = 210
     tel = 2 * 120 = 240
     total = 450
2. Split Payments & Net Credit:
   - If user gave partial cash (e.g., "total bill 450 me se 200 cash diya, baki udhar"), compute net credit = 450 - 200 = 250.
   - Set type: "Given", amount: 250, remarks: "Bill: ₹450, Cash Paid: ₹200, Net Udhar: ₹250".
3. Previous Balance Settlement:
   - If user settled past balance (e.g., "purana 300 baki tha usme se 200 diya"), compute net payment received = 200, type: "Received".
4. Purchase Orders:
   - If user lists finished grocery items ("ye khatam ho gaya"), categorize as "purchase_order".

Output JSON structure:
{
  "action": "transaction" | "purchase_order" | "balance_query" | "itemized_bill" | "help",
  "name": "Customer Name or empty string",
  "amount": computed_final_number,
  "type": "Given" | "Received",
  "category": "UDHAR" | "COLLECTION" | "PURCHASE" | "BILL",
  "purchase_items": ["item 1", "item 2"],
  "bill_items": [{"title": "Item", "quantity": 1, "unit": "kg", "unitPrice": 50, "totalPrice": 50}],
  "remarks": "detailed calculation remarks",
  "reply": "Clear, friendly Roman Hinglish explanation of the calculation and result to speak back to the merchant"
}

Merchant speech: "$speechText"
''';
      } else {
        prompt = '''
You are a real-time Gemini 3.8 Live AI assistant (gemini-3.8-flash) for an Indian merchant ledger app (UdharCard).
The merchant speaks in Hindi, Hinglish, or English.
Analyze the user's speech and extract information into strictly valid JSON with ultra-low latency.

Categories of speech:
1. "transaction": Merchant giving credit or receiving payment.
   Examples:
   - "Ramesh ko 500 rupaye udhar diya" -> action: "transaction", name: "Ramesh", amount: 500, type: "Given", category: "UDHAR"
   - "Suresh se 1200 mile" -> action: "transaction", name: "Suresh", amount: 1200, type: "Received", category: "COLLECTION"
2. "purchase_order": Stock/grocery items that are finished and need to be ordered.
   Example: "Doodh aur bread khatam ho gaya mangwana hai" -> action: "purchase_order", purchase_items: ["Doodh", "Bread"]
3. "balance_query": Checking balance of customer or total.
   Example: "Ramesh ka kitna baki hai?" -> action: "balance_query", name: "Ramesh"
4. "itemized_bill": Items with quantity and price.
   Example: "2 kg cheeni 40 rupaye aur 1 packet surf 60 rupaye" -> action: "itemized_bill", bill_items: [{"title": "Cheeni", "quantity": 2, "unit": "kg", "unitPrice": 40, "totalPrice": 80}]
5. "help": Greeting or asking how to use.

Output JSON structure:
{
  "action": "transaction" | "purchase_order" | "balance_query" | "itemized_bill" | "help",
  "name": "Customer Name or empty string",
  "amount": number,
  "type": "Given" | "Received",
  "category": "UDHAR" | "COLLECTION" | "PURCHASE" | "BILL",
  "purchase_items": ["item 1", "item 2"],
  "bill_items": [{"title": "Item", "quantity": 1, "unit": "kg", "unitPrice": 50, "totalPrice": 50}],
  "remarks": "short remarks if any",
  "reply": "Friendly short reply in Roman Hinglish to speak back to the merchant"
}

Merchant speech: "$speechText"
''';
      }

      final timeoutDuration = useThinking
          ? const Duration(milliseconds: 5500)
          : const Duration(milliseconds: 3500);

      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(timeoutDuration);

      final text = response.text?.trim() ?? '';
      if (text.isEmpty) return null;

      final data = jsonDecode(text);
      final action = (data['action'] ?? '').toString().toLowerCase();
      final name = (data['name'] ?? '').toString().trim();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final type = normalizeTransactionType(data['type'], action);
      final category = (data['category'] ?? (type == 'Received' ? 'COLLECTION' : 'UDHAR')).toString();
      final reply = (data['reply'] ?? '').toString();
      final remarks = (data['remarks'] ?? '').toString();

      List<VoiceBillItem> billItems = [];
      if (data['bill_items'] is List) {
        for (final item in data['bill_items']) {
          if (item is Map) {
            billItems.add(VoiceBillItem(
              title: (item['title'] ?? 'Item').toString(),
              quantity: (item['quantity'] as num?)?.toDouble() ?? 1.0,
              unit: (item['unit'] ?? '').toString(),
              unitPrice: (item['unitPrice'] as num?)?.toDouble() ?? 0.0,
              totalPrice: (item['totalPrice'] as num?)?.toDouble() ?? 0.0,
            ));
          }
        }
      }

      List<String> pItems = [];
      if (data['purchase_items'] is List) {
        for (final it in data['purchase_items']) {
          pItems.add(it.toString());
        }
      }

      // Link with existing customer ledger if found
      final matchedCustomer = findMatchingCustomer(name, '');
      final displayName = matchedCustomer != null ? (matchedCustomer['name'] ?? name) : name;

      isUsingGeminiAi = true;
      return VoiceParseResult(
        name: displayName,
        phone: matchedCustomer?['phone']?.toString() ?? '',
        amount: amount,
        type: type,
        category: category,
        isQuery: action == 'balance_query',
        isHelp: action == 'help',
        isPurchaseOrder: action == 'purchase_order',
        items: billItems,
        purchaseItems: pItems,
        matchedCustomer: matchedCustomer,
        remarks: remarks,
        reply: reply.isNotEmpty
            ? reply
            : (type == 'Given'
                ? '$displayName ko ₹${amount.toInt()} udhar add kar diya gaya.'
                : '$displayName se ₹${amount.toInt()} mil gaye.'),
      );
    } catch (e) {
      if (kDebugMode) print("Gemini Live/Thinking parsing error, fallback to local NLP: $e");
      isUsingGeminiAi = false;
      return null;
    }
  }

  /// Secondary AI Parser: Calls Live Production Backend (pay.udharcard.shop/api/ai-assistant/voice-parse)
  Future<VoiceParseResult?> _parseWithLiveServer(String speechText, bool useThinking) async {
    try {
      final url = Uri.parse('https://pay.udharcard.shop/api/ai-assistant/voice-parse');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'speech_text': speechText,
          'mode': useThinking ? 'extended_thinking' : 'live',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if ((body['status'] == 'success' || body['status'] == 'fallback') && body['data'] is Map) {
          final data = body['data'];
          final action = (data['action'] ?? '').toString().toLowerCase();
          final name = (data['name'] ?? '').toString().trim();
          final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          final type = normalizeTransactionType(data['type'], action);
          final category = (data['category'] ?? (type == 'Received' ? 'COLLECTION' : 'UDHAR')).toString();
          final reply = (data['reply'] ?? '').toString();
          final remarks = (data['remarks'] ?? '').toString();

          List<VoiceBillItem> billItems = [];
          if (data['bill_items'] is List) {
            for (final item in data['bill_items']) {
              if (item is Map) {
                billItems.add(VoiceBillItem(
                  title: (item['title'] ?? 'Item').toString(),
                  quantity: (item['quantity'] as num?)?.toDouble() ?? 1.0,
                  unit: (item['unit'] ?? '').toString(),
                  unitPrice: (item['unitPrice'] as num?)?.toDouble() ?? 0.0,
                  totalPrice: (item['totalPrice'] as num?)?.toDouble() ?? 0.0,
                ));
              }
            }
          }

          List<String> pItems = [];
          if (data['purchase_items'] is List) {
            for (final it in data['purchase_items']) {
              pItems.add(it.toString());
            }
          }

          final matchedCustomer = findMatchingCustomer(name, '');
          final displayName = matchedCustomer != null ? (matchedCustomer['name'] ?? name) : name;

          isUsingGeminiAi = true;
          return VoiceParseResult(
            name: displayName,
            phone: matchedCustomer?['phone']?.toString() ?? '',
            amount: amount,
            type: type,
            category: category,
            isQuery: action == 'balance_query',
            isHelp: action == 'help',
            isPurchaseOrder: action == 'purchase_order',
            items: billItems,
            purchaseItems: pItems,
            matchedCustomer: matchedCustomer,
            remarks: remarks,
            reply: reply.isNotEmpty
                ? reply
                : (type == 'Given'
                    ? '$displayName ko ₹${amount.toInt()} udhar add kar diya gaya.'
                    : '$displayName se ₹${amount.toInt()} mil gaye.'),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print("Live server Gemini 3.8 parse fallback error: $e");
    }
    return null;
  }

  Future<void> _processSpeech() async {
    if (_isProcessingSpeech) return;
    _isProcessingSpeech = true;

    try {
      if (_transcribedText.trim().isEmpty) {
        _changeState(VoiceAssistantState.idle);
        return;
      }

      final cleanSpeech = _transcribedText.toLowerCase().trim();
      if (cleanSpeech == 'band karo' ||
          cleanSpeech == 'stop' ||
          cleanSpeech == 'ruk jao' ||
          cleanSpeech == 'cancel' ||
          cleanSpeech == 'exit') {
        isLiveMode = false;
        _changeState(VoiceAssistantState.idle);
        HapticFeedback.mediumImpact();
        await speakReply("Gemini 3.8 Live session band kar diya gaya.");
        update();
        return;
      }

      _changeState(VoiceAssistantState.thinking);
      HapticFeedback.lightImpact();

      // 1. Try Direct Google Gemini 3.8 Live / Extended Thinking AI
      VoiceParseResult? parsed;
      try {
        parsed = await _parseWithGemini(_transcribedText);
      } catch (_) {}

      // 2. Try Live Server Gemini 3.8 Backend Endpoint (pay.udharcard.shop)
      if (parsed == null) {
        try {
          parsed = await _parseWithLiveServer(_transcribedText, isExtendedThinking);
        } catch (_) {}
      }

      // 3. Seamless Instant Fallback to Local Smart NLP (0ms, Offline Kirana dictionary)
      if (parsed == null) {
        isUsingGeminiAi = false;
        parsed = parseVoiceInstruction(_transcribedText);
      }

      latestParsedResult = parsed;

      if (parsed.isQuery) {
        _aiReply = _calculateBalanceReply(
          parsed.name.isNotEmpty ? parsed.name : null,
        );
      } else if (parsed.isHelp) {
        _aiReply = parsed.reply;
      } else if (parsed.isPurchaseOrder) {
        _aiReply = parsed.reply;
        savePurchaseOrder(parsed.purchaseItems);
      } else if (parsed.amount > 0) {
        parsedName = parsed.name;
        parsedAmount = parsed.amount;
        parsedType = parsed.type;
        parsedRemarks = parsed.remarks;
        _aiReply = parsed.reply;

        // Automatically sync to Udhar ledger if customer is matched
        final matched = findMatchingCustomer(parsed.name, parsed.phone);
        if (matched != null) {
          await saveParsedEntryDirectly();
        } else {
          saveTransaction();
          await speakReply(_aiReply);
        }
        return;
      } else {
        _aiReply = parsed.reply;
      }

      await speakReply(_aiReply);
    } finally {
      _isProcessingSpeech = false;
    }
  }

  /// Strips Indian/Hindi honorifics (ji, bhai, bhaiya, uncle, sethji, etc.) from party names
  static String stripHonorifics(String raw) {
    if (raw.trim().isEmpty) return raw;
    var cleaned = raw.trim();
    final pattern = RegExp(
      r'(?:(?<=^|\s)(?:ji|bhai|bhaiya|bhaya|uncle|sethji|seth\s+ji|sahab|saab|aunty|anti|didi|sir|panditji|babu|chacha|chachaji|mama|mamaji|kaka|kakaji|जी|भाई|भैया|अंकल|सेठजी|साहब|आंटी|दीदी|सर|पंडितजी|बाबू|चाचा|मामा|काका)(?=$|\s))',
      caseSensitive: false,
    );
    cleaned = cleaned.replaceAll(pattern, '').replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isEmpty ? raw.trim() : cleaned;
  }

  static final Map<String, double> _hindiWordToNumber = {
    'ek': 1, 'एक': 1,
    'do': 2, 'दो': 2,
    'teen': 3, 'tin': 3, 'तीन': 3,
    'chaar': 4, 'char': 4, 'चार': 4,
    'paanch': 5, 'panch': 5, 'पांच': 5, 'पाँच': 5,
    'che': 6, 'chhe': 6, 'chheh': 6, 'छह': 6,
    'saat': 7, 'सात': 7,
    'aath': 8, 'ath': 8, 'आठ': 8,
    'nau': 9, 'नौ': 9,
    'das': 10, 'दस': 10,
    'gyarah': 11, 'ग्यारह': 11,
    'barah': 12, 'बारह': 12,
    'terah': 13, 'तेरह': 13,
    'chaudah': 14, 'चौदह': 14,
    'pandrah': 15, 'pandra': 15, 'पंद्रह': 15,
    'solah': 16, 'sola': 16, 'सोलह': 16,
    'satrah': 17, 'satra': 17, 'सत्रह': 17,
    'atharah': 18, 'athara': 18, 'अठारह': 18,
    'unnees': 19, 'unnis': 19, 'उन्नीस': 19,
    'bees': 20, 'bis': 20, 'बीस': 20,
    'ikkees': 21, 'ikkis': 21, 'इक्कीस': 21,
    'baees': 22, 'baais': 22, 'बाईस': 22,
    'teees': 23, 'teis': 23, 'तेईस': 23,
    'chaubees': 24, 'chaubis': 24, 'चौबीस': 24,
    'pachees': 25, 'pachis': 25, 'पच्चीस': 25,
    'chhabbees': 26, 'chhabis': 26, 'छब्बीस': 26,
    'sattaees': 27, 'satais': 27, 'सत्ताईस': 27,
    'atthaees': 28, 'athais': 28, 'अट्ठाईस': 28,
    'untees': 29, 'untis': 29, 'उनतीस': 29,
    'tees': 30, 'tis': 30, 'तीस': 30,
    'iktees': 31, 'iktis': 31, 'इकतीस': 31,
    'battees': 32, 'battis': 32, 'बत्तीस': 32,
    'taitees': 33, 'tentis': 33, 'तैंतीस': 33,
    'chautees': 34, 'chautis': 34, 'चौंतीस': 34,
    'paintees': 35, 'paintis': 35, 'पैंतीस': 35,
    'chhatees': 36, 'chhattis': 36, 'छत्तीस': 36,
    'saintees': 37, 'saintis': 37, 'सैंतीस': 37,
    'adtees': 38, 'artis': 38, 'अड़तीस': 38,
    'untalees': 39, 'untalis': 39, 'उनतालीस': 39,
    'chaalis': 40, 'chalis': 40, 'चालीस': 40,
    'iktalees': 41, 'iktalis': 41, 'इकतालीस': 41,
    'bayalees': 42, 'bayalis': 42, 'बयालीस': 42,
    'tetalees': 43, 'tetalis': 43, 'तैंतालीस': 43,
    'chauwalees': 44, 'chauwalis': 44, 'चवालीस': 44,
    'paintalees': 45, 'paintalis': 45, 'पैंतालीस': 45,
    'chhiyalees': 46, 'chhiyalis': 46, 'छियालीस': 46,
    'saintalees': 47, 'saintalis': 47, 'सैंतालीस': 47,
    'adtalees': 48, 'adtalis': 48, 'अड़तालीस': 48,
    'unchaas': 49, 'unchas': 49, 'उनचास': 49,
    'pachaas': 50, 'pachas': 50, 'पचास': 50,
    'pachpan': 55, 'पचपन': 55,
    'saath': 60, 'sath': 60, 'साठ': 60,
    'painsath': 65, 'paintst': 65, 'पैंसठ': 65,
    'sattar': 70, 'सत्तर': 70,
    'pachhattar': 75, 'पचहत्तर': 75,
    'assi': 80, 'अस्सी': 80,
    'pachasi': 85, 'पचासी': 85,
    'nabbe': 90, 'nabbey': 90, 'नब्बे': 90,
    'pachanve': 95, 'पंचानवे': 95,
    'sau': 100, 'so': 100, 'सौ': 100,
  };

  /// Parses spoken Hindi/Hinglish words into double amount (e.g. "pandrah sau" -> 1500, "dhai sau" -> 250)
  static double parseHindiNumberWords(String text) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return 0.0;

    // 1. Direct compound expressions
    if (lower.contains('dedh hazaar') || lower.contains('dedh hazar') || lower.contains('डेढ़ हजार') || lower.contains('डेढ़ हज़ार')) {
      return 1500.0;
    }
    if (lower.contains('dhai hazaar') || lower.contains('dhai hazar') || lower.contains('ढाई हजार') || lower.contains('ढाई हज़ार')) {
      return 2500.0;
    }
    if (lower.contains('dedh sau') || lower.contains('डेढ़ सौ')) {
      return 150.0;
    }
    if (lower.contains('dhai sau') || lower.contains('ढाई सौ')) {
      return 250.0;
    }

    // 2. Parse sequential multiplier tokens
    final tokens = lower.replaceAll(RegExp(r'[^a-zA-Z\u0900-\u097F\s]'), ' ').split(RegExp(r'\s+'));
    double total = 0.0;
    double current = 0.0;
    bool foundAnyNumber = false;

    for (int i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      if (t == 'hazaar' || t == 'hazar' || t == 'हजार' || t == 'हज़ार' || t == 'thousand') {
        foundAnyNumber = true;
        if (current == 0.0) current = 1.0;
        total += current * 1000.0;
        current = 0.0;
      } else if (t == 'sau' || t == 'so' || t == 'सौ' || t == 'hundred') {
        foundAnyNumber = true;
        if (current == 0.0) current = 1.0;
        total += current * 100.0;
        current = 0.0;
      } else if (t == 'lakh' || t == 'laakh' || t == 'लाख') {
        foundAnyNumber = true;
        if (current == 0.0) current = 1.0;
        total += current * 100000.0;
        current = 0.0;
      } else if (_hindiWordToNumber.containsKey(t)) {
        foundAnyNumber = true;
        current += _hindiWordToNumber[t]!;
      }
    }
    total += current;

    return foundAnyNumber ? total : 0.0;
  }

  String _normalizeDevnagariNumbers(String input) {
    const devnagariDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    var result = input;
    for (int i = 0; i < devnagariDigits.length; i++) {
      result = result.replaceAll(devnagariDigits[i], i.toString());
    }
    return result;
  }

  /// Comprehensive NLP Voice Parser specifically tuned for Indian small businesses & Kirana shops.
  VoiceParseResult parseVoiceInstruction(String text) {
    final normalized = _normalizeDevnagariNumbers(text.trim());
    if (normalized.isEmpty) {
      return const VoiceParseResult(
        reply: 'Kripya naam aur amount saaf bolen.',
      );
    }

    final lower = normalized.toLowerCase();

    // ── 1. Help & Instructions ───────────────────────────────────────────────
    final helpRegex = RegExp(
      r'\b(hello|hi|help|kya kar|kaise|what can|namaste|start|kya hai)\b',
      caseSensitive: false,
    );
    if (helpRegex.hasMatch(lower) &&
        !lower.contains('udhar') &&
        !lower.contains('udhaar') &&
        !lower.contains('diya') &&
        !lower.contains('mile') &&
        !lower.contains('rupaye') &&
        !lower.contains('rupees')) {
      return const VoiceParseResult(
        isHelp: true,
        category: 'HELP',
        reply: 'Namaste! Aap simple bol sakte hain: "Rajesh ko 2000 rupay udhaar diya", ya "Sandipan se 500 rupay mile".',
      );
    }

    // ── 2. Purchase Orders (Khareed List) ────────────────────────────────────
    final purchaseKeywords = ['khatam', 'mangwana', 'mangana', 'order', 'stock', 'chahiye', 'le aana', 'lana hai'];
    if (purchaseKeywords.any((kw) => lower.contains(kw)) &&
        !lower.contains('udhar') &&
        !lower.contains('udhaar') &&
        !lower.contains('diya') &&
        !lower.contains('mile')) {
      final List<String> pItems = [];
      final parts = lower.split(RegExp(r',\s*|\s+\baur\b\s*|\s+\band\b\s*|\|'));
      for (final p in parts) {
        String cleanItem = p
            .replaceAll(RegExp(r'\b(khatam|mangwana|mangana|order|stock|chahiye|le aana|lana hai|ho gaya|hai|hain)\b'), '')
            .trim();
        if (cleanItem.isNotEmpty) {
          pItems.add(cleanItem[0].toUpperCase() + cleanItem.substring(1));
        }
      }
      if (pItems.isNotEmpty) {
        final replyText = 'Khareed list mein ${pItems.join(", ")} add ho gaya.';
        return VoiceParseResult(
          isPurchaseOrder: true,
          category: 'PURCHASE',
          purchaseItems: pItems,
          reply: replyText,
        );
      }
    }

    // ── 3. Balance Queries & Inquiries ───────────────────────────────────────
    final queryWords = [
      'kitna', 'balance', 'total', 'baki', 'baaki', 'hisab', 'hisaab', 'summary', 'paisa', 'paise', 'lene', 'kiska', 'kaun', 'how much'
    ];
    if (queryWords.any((word) => lower.contains(word)) &&
        !lower.contains('diya') &&
        !lower.contains('mile') &&
        !lower.contains('mila') &&
        !lower.contains('diye')) {
      String cleaned = lower
          .replaceAll(
            RegExp(r'\b(kitna|balance|total|baki|baaki|hisab|hisaab|summary|paisa|paise|lene|kiska|kaun|hai|hain|ka|ki|ke|ko|se|ne|what|is|my|amount|tell|me|how|much)\b'),
            '',
          )
          .trim();
      cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z\u0900-\u097F\s]'), ' ');
      final words = cleaned.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
      final matchedName = words.isEmpty
          ? ''
          : words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
      return VoiceParseResult(isQuery: true, name: matchedName, reply: '');
    }

    // ── 4. Itemized Voice Bill / Invoice ─────────────────────────────────────
    final List<VoiceBillItem> billItems = [];
    final itemMatches = RegExp(r'(\d+(?:\.\d+)?)\s*(kilo|kg|packet|soap|piece|pc|darjan|dozen|ltr|litre|g|gram|dabba|dhabba)?\s+([a-zA-Z\u0900-\u097F\s]+?)\s+(\d+(?:\.\d+)?)\s*(?:rupaye|rupees|rs|each|per)?', caseSensitive: false)
        .allMatches(lower);

    for (final m in itemMatches) {
      final qty = double.tryParse(m.group(1) ?? '1') ?? 1.0;
      final unit = m.group(2) ?? '';
      final title = m.group(3)?.trim() ?? 'Item';
      final unitPrice = double.tryParse(m.group(4) ?? '0') ?? 0.0;
      final total = qty * unitPrice;
      if (unitPrice > 0) {
        billItems.add(VoiceBillItem(
          title: title[0].toUpperCase() + title.substring(1),
          quantity: qty,
          unit: unit,
          unitPrice: unitPrice,
          totalPrice: total,
        ));
      }
    }

    // ── 5. Standard Transaction Amounts & Types ──────────────────────────────
    double amount = 0.0;
    if (billItems.isNotEmpty) {
      amount = billItems.fold<double>(0.0, (sum, i) => sum + i.totalPrice);
    } else {
      final amountMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(lower);
      if (amountMatch != null) {
        amount = double.tryParse(amountMatch.group(1)!) ?? 0.0;
      }
      if (amount <= 0) {
        amount = parseHindiNumberWords(lower);
      }
    }

    // Determine type: Given (Udhaar Diya) vs Received (Paise Mile)
    String type = 'Given';
    String category = 'UDHAR';

    if (lower.contains('mila') ||
        lower.contains('mile') ||
        lower.contains('jama') ||
        lower.contains('received') ||
        lower.contains('wapis') ||
        lower.contains('aaya') ||
        lower.contains('aaye') ||
        (lower.contains('paid') && !lower.contains('unpaid'))) {
      type = 'Received';
      category = 'COLLECTION';
    } else if (lower.contains('diya') ||
        lower.contains('diye') ||
        lower.contains('de') ||
        lower.contains('udhar') ||
        lower.contains('udhaar') ||
        lower.contains('unpaid') ||
        lower.contains('baaki') ||
        lower.contains('maal liya') ||
        lower.contains('given') ||
        lower.contains('gave')) {
      type = 'Given';
      category = 'UDHAR';
    }

    if (billItems.isNotEmpty) {
      category = 'BILL';
    }

    // Extract 10-digit Indian phone number if spoken
    String extractedPhone = '';
    final phoneMatch = RegExp(r'\b([6-9]\d{9})\b').firstMatch(text);
    if (phoneMatch != null) {
      extractedPhone = phoneMatch.group(1) ?? '';
    }

    // ── 6. Customer / Party Name Extraction ──────────────────────────────────
    String cleaned = lower
        .replaceAll(RegExp(r'\d+(?:\.\d+)?'), '')
        .replaceAll(
          RegExp(
            r'\b(rupaye|rupees|rupee|rs|inr|udhar|udhaar|ko|se|ne|ka|ki|ke|par|diya|diye|mila|mile|jama|liya|paid|unpaid|received|gave|given|hai|hain|aaya|aaye|de|maal|saman|each|kilo|kg|packet|soap|piece|pc|darjan|baki|baaki|hisab|khata|khate|me|mein|dalo|add|karo|kar|रुपये|रुपए|रु|उधार|जमा|मिले|दिए|दिया|लिया|को|से|ने|का|की|के|है|हैं|खाते|में|डालो|sau|so|सौ|hazaar|hazar|हजार|हज़ार|lakh|laakh|लाख|ek|do|teen|chaar|char|paanch|panch|che|chhe|saat|aath|ath|nau|das|gyarah|barah|terah|chaudah|pandrah|pandra|solah|satrah|atharah|unnees|bees|pachees|tees|chaalis|pachaas|pachas|saath|sattar|assi|nabbe|dedh|dhai)\b',
          ),
          '',
        )
        .trim();
    cleaned = stripHonorifics(cleaned);
    cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z\u0900-\u097F\s]'), ' ');
    final words = cleaned.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    final name = words.isEmpty
        ? 'Customer'
        : words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

    // Match with existing ledger contact (by phone first, or by name)
    final matchedCustomer = findMatchingCustomer(name, extractedPhone);

    String remarks = '';
    if (lower.contains('maal liya') || lower.contains('supplier')) {
      remarks = 'Supplier purchase / maal liya';
    } else if (billItems.isNotEmpty) {
      remarks = billItems.map((b) => '${b.quantity} ${b.unit} ${b.title}').join(', ');
    }

    if (amount > 0) {
      final displayName = matchedCustomer != null ? (matchedCustomer['name'] ?? name) : name;
      final friendlyReply = type == 'Given'
          ? '$displayName ko ${amount.toInt()} rupaye udhar safaltapoorvak add ho gaye.'
          : '$displayName se ${amount.toInt()} rupaye safaltapoorvak mil gaye.';

      return VoiceParseResult(
        name: displayName,
        phone: matchedCustomer?['phone']?.toString() ?? extractedPhone,
        amount: amount,
        type: type,
        category: category,
        items: billItems,
        matchedCustomer: matchedCustomer,
        remarks: remarks,
        reply: friendlyReply,
      );
    }

    return const VoiceParseResult(
      reply: 'Kripya amount aur party name saaf bolen, jaise: "Rajesh ko 2000 rupay udhaar diya".',
    );
  }

  /// Fuzzy and phonetic match against active merchant ledger customers
  Map<String, dynamic>? findMatchingCustomer(String name, [String phone = '']) {
    if (!Get.isRegistered<UdharController>()) return null;
    final users = Get.find<UdharController>().usersList;

    if (phone.isNotEmpty) {
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.isNotEmpty) {
        for (var u in users) {
          if (u is Map) {
            final uPhone =
                (u['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
            if (uPhone.isNotEmpty &&
                (uPhone.endsWith(cleanPhone) || cleanPhone.endsWith(uPhone))) {
              return Map<String, dynamic>.from(u);
            }
          }
        }
      }
    }

    final strippedQ = stripHonorifics(name);
    final q = strippedQ.trim().toLowerCase();
    if (q.isEmpty || q == 'customer') return null;

    // 1. Exact or substring match (checking raw customer name and stripped customer name)
    for (var u in users) {
      if (u is Map) {
        final rawCName = (u['name'] ?? u['customer_name'] ?? '').toString().toLowerCase();
        final cName = stripHonorifics(rawCName).toLowerCase();
        if (cName == q ||
            rawCName == q ||
            cName.startsWith(q) ||
            q.startsWith(cName) ||
            cName.contains(q) ||
            rawCName.contains(q)) {
          return Map<String, dynamic>.from(u);
        }
      }
    }

    // 2. Phonetic normalization match (e.g. Vikas <-> Bikash, Guddu <-> Guddoo)
    final normQ = _phoneticNormalize(q);
    for (var u in users) {
      if (u is Map) {
        final rawCName = (u['name'] ?? u['customer_name'] ?? '').toString().toLowerCase();
        final cName = stripHonorifics(rawCName).toLowerCase();
        final normC = _phoneticNormalize(cName);
        if (normC == normQ ||
            normC.contains(normQ) ||
            normQ.contains(normC)) {
          return Map<String, dynamic>.from(u);
        }
      }
    }

    // 3. Levenshtein edit-distance match for slight speech typos
    if (q.length >= 4) {
      for (var u in users) {
        if (u is Map) {
          final rawCName = (u['name'] ?? u['customer_name'] ?? '').toString().toLowerCase();
          final cName = stripHonorifics(rawCName).toLowerCase();
          final normC = _phoneticNormalize(cName);
          final dist = _levenshtein(normQ, normC);
          final maxAllowedDist = normQ.length >= 6 ? 2 : 1;
          if (dist <= maxAllowedDist) {
            return Map<String, dynamic>.from(u);
          }
        }
      }
    }

    return null;
  }

  String _phoneticNormalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('ee', 'i')
        .replaceAll('oo', 'u')
        .replaceAll('aa', 'a')
        .replaceAll('sh', 's')
        .replaceAll('ph', 'f')
        .replaceAll('w', 'v')
        .replaceAll('b', 'v');
  }

  int _levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost]
            .reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  /// 1-Tap Direct Save to Ledger via UdharController with full Backend & Udhar User App synchronization
  Future<void> saveParsedEntryDirectly() async {
    if (!hasQuickEntry) {
      Helpers.showSnackBar(
        msg: 'Say a phrase like “Rajesh ko 2000 rupay udhaar diya” first.',
      );
      return;
    }

    if (isSubmittingEntry) return;
    isSubmittingEntry = true;
    update();

    try {
      if (!Get.isRegistered<UdharController>()) {
        Get.put(UdharController());
      }
      final udharController = Get.find<UdharController>();

      // Apply voice prefill to populate amount & transaction type
      udharController.applyVoiceEntryPrefill(
        name: parsedName,
        amount: parsedAmount,
        type: parsedType.isEmpty ? 'Given' : parsedType,
      );

      // Set custom remarks
      if (parsedRemarks.isNotEmpty) {
        udharController.remarksCtrl.text = parsedRemarks;
      } else {
        udharController.remarksCtrl.text = 'Added via VoiceKhata';
      }

      final cleanName = stripHonorifics(parsedName);
      Map<String, dynamic>? targetCustomer = udharController.selectedUser ??
          findMatchingCustomer(cleanName, parsedPhone.isNotEmpty ? parsedPhone : (latestParsedResult?.phone ?? ''));
      if (targetCustomer != null) {
        udharController.selectedUser = targetCustomer;
      }

      // If customer not already in active ledger, try to resolve real phone from parsedPhone, speech or phonebook
      if (targetCustomer == null) {
        String phoneToUse = parsedPhone.isNotEmpty
            ? parsedPhone
            : (latestParsedResult?.phone ?? '');

        if (phoneToUse.isEmpty) {
          // Attempt smart match with device phonebook contacts
          try {
            if (await FlutterContacts.requestPermission(readonly: true)) {
              final contacts = await FlutterContacts.getContacts(withProperties: true);
              final q = cleanName.trim().toLowerCase();
              for (final c in contacts) {
                final cName = stripHonorifics(c.displayName).trim().toLowerCase();
                if (cName == q || cName.contains(q) || q.contains(cName)) {
                  if (c.phones.isNotEmpty) {
                    final raw = c.phones.first.number.replaceAll(RegExp(r'\D'), '');
                    if (raw.length >= 10) {
                      phoneToUse = raw.substring(raw.length - 10);
                      break;
                    }
                  }
                }
              }
            }
          } catch (e) {
            if (kDebugMode) print("Phonebook lookup error: $e");
          }
        }

        if (phoneToUse.isNotEmpty) {
          // Create new customer in backend with their real phone number so Udhar Users App syncs!
          udharController.nameCtrl.text = cleanName;
          udharController.phoneCtrl.text = phoneToUse;
          targetCustomer = await udharController.addCustomer(closeScreenOnSuccess: false);
          if (targetCustomer != null) {
            udharController.selectedUser = targetCustomer;
          }
        }
      }

      // If still no valid customer (no real phone number found):
      if (targetCustomer == null && udharController.selectedUser == null) {
        Helpers.showSnackBar(
          msg: '$cleanName ka mobile number dalein taki Udhar User app se hisab sync ho sake.',
          title: 'Mobile Number Required',
        );
        isSubmittingEntry = false;
        update();
        await openQuickAddEntry();
        return;
      }

      // Submit directly to backend API with idempotency protection
      final safeName = cleanName.replaceAll(RegExp(r'\s+'), '_');
      final txKey = "voice_${safeName}_${parsedAmount.toInt()}_${DateTime.now().millisecondsSinceEpoch ~/ 60000}";
      final bool success = await udharController.submitUdhar(
        popOnSuccess: false,
        billImagePath: attachedBillImage?.path,
        idempotencyKey: txKey,
      );

      if (success) {
        saveTransaction();
        _transcribedText = "";
        sandboxTextCtrl.clear();
        parsedPhone = "";
        clearAttachedBillImage();

        await speakReply(
          parsedType == 'Given'
              ? '$cleanName ko ${parsedAmount.toInt()} rupaye udhar ledger mein add ho gaye.'
              : '$cleanName se ${parsedAmount.toInt()} rupaye ledger mein jama ho gaye.',
        );
      }
    } catch (e) {
      if (kDebugMode) print("Error in saveParsedEntryDirectly: $e");
      Helpers.showSnackBar(
        msg: 'Transaction sync failed. Please try again.',
        title: 'Error',
      );
    } finally {
      isSubmittingEntry = false;
      update();
    }
  }

  Future<void> openQuickAddEntry() async {
    if (!hasQuickEntry) {
      Helpers.showSnackBar(
        msg: 'Say a phrase like “Rajesh ko 2000 rupay udhaar diya” first.',
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

  void saveTransaction() {
    if (parsedName.isEmpty || parsedName == "Unknown" || parsedAmount <= 0) {
      return;
    }

    Map<String, dynamic> newTx = {
      "name": parsedName,
      "amount": parsedAmount,
      "type": parsedType,
      "remarks": parsedRemarks,
      "date": DateTime.now().toString(),
      "image": attachedBillImage?.path,
    };

    if (parsedName.trim().isNotEmpty) {
      recentVoiceContacts.remove(parsedName.trim());
      recentVoiceContacts.insert(0, parsedName.trim());
      recentVoiceContacts = recentVoiceContacts.take(8).toList();
      HiveHelp.write('voice_recent_contacts', recentVoiceContacts);
    }

    voiceTransactions.insert(0, newTx);

    List<String> jsonList = voiceTransactions.map((tx) => jsonEncode(tx)).toList();
    HiveHelp.write('voice_transactions', jsonList);

    sandboxTextCtrl.clear();
    update();
  }

  void savePurchaseOrder(List<String> items) {
    if (items.isEmpty) return;

    final newOrder = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'items': items,
      'date': DateTime.now().toString(),
      'status': 'Pending',
    };

    purchaseOrders.insert(0, newOrder);
    final jsonList = purchaseOrders.map((p) => jsonEncode(p)).toList();
    HiveHelp.write('voice_purchase_orders', jsonList);
    update();
  }

  void loadPurchaseOrders() {
    dynamic savedData = HiveHelp.read('voice_purchase_orders');
    if (savedData != null && savedData is List) {
      purchaseOrders = savedData.map((e) {
        return Map<String, dynamic>.from(jsonDecode(e.toString()));
      }).toList();
    } else {
      purchaseOrders = [];
    }
    update();
  }

  void deletePurchaseOrder(int index) {
    if (index >= 0 && index < purchaseOrders.length) {
      purchaseOrders.removeAt(index);
      final jsonList = purchaseOrders.map((p) => jsonEncode(p)).toList();
      HiveHelp.write('voice_purchase_orders', jsonList);
      update();
    }
  }

  Future<void> sharePurchaseOrderOnWhatsApp(List<dynamic> items, [String? phone]) async {
    final String itemsText = items.map((item) => "• $item").join("\n");
    final String message = "🛒 *Purchase Order / सामान लिस्ट*\n\n$itemsText\n\n_Generated via VoiceKhata_";

    final Uri uri = phone != null && phone.trim().isNotEmpty
        ? Uri.parse("whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}")
        : Uri.parse("whatsapp://send?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(
          Uri.parse("https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}"),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      Helpers.showSnackBar(msg: "Could not launch WhatsApp.");
    }
  }

  Future<void> sharePaymentReminderOnWhatsApp(String customerName, String? phone, double amount) async {
    final String message =
        "Namaste $customerName ji,\nAapka kul udhar balance ₹${amount.toStringAsFixed(0)} baki hai. Kripya time par payment karein.\n\n_Sent via VoiceKhata_";

    final Uri uri = phone != null && phone.trim().isNotEmpty
        ? Uri.parse("whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}")
        : Uri.parse("whatsapp://send?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(
          Uri.parse("https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}"),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      Helpers.showSnackBar(msg: "Could not launch WhatsApp.");
    }
  }

  Future<void> talkBackTransaction(Map<String, dynamic> tx) async {
    final name = tx['name'] ?? 'Customer';
    final amount = (tx['amount'] as num?)?.toInt() ?? 0;
    final type = tx['type'] == 'Received' ? 'jama huye' : 'udhar diye';
    final phrase = _talkBackLanguage.startsWith('en')
        ? "$name, $amount rupees $type"
        : "$name ko $amount rupaye $type";
    await speakReply(phrase);
  }

  Future<void> sharePurchaseOrderWhatsApp(String? supplierPhone) async {
    final items = latestParsedResult?.purchaseItems ?? [];
    await sharePurchaseOrderOnWhatsApp(items, supplierPhone);
  }

  Future<void> shareReminderWhatsApp(String? phone, double amount, String name) async {
    await sharePaymentReminderOnWhatsApp(name, phone, amount);
  }

  String _calculateBalanceReply(String? targetName) {
    try {
      List<dynamic> users = [];
      if (Get.isRegistered<UdharController>()) {
        users = List<dynamic>.from(Get.find<UdharController>().usersList);
      }

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
              customerBalance = double.tryParse(
                    u['outstanding_balance']?.toString() ??
                        u['balance']?.toString() ??
                        '0',
                  ) ??
                  0.0;
              break;
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

      double totalBalance = 0.0;
      int count = 0;
      for (var u in users) {
        if (u is Map) {
          count++;
          totalBalance += double.tryParse(
                u['outstanding_balance']?.toString() ??
                    u['balance']?.toString() ??
                    '0',
              ) ??
              0.0;
        }
      }

      if (totalBalance > 0) {
        return "Aapka kul udhar balance ${totalBalance.toInt()} rupaye baki hai. Kul $count customers hain.";
      } else {
        return "Aapka koi udhar baki nahi hai. Sabhi hisab clear hain.";
      }
    } catch (e) {
      return "Balance check karne mein error aayi, kripya dobara try karein.";
    }
  }

  Future<void> speakReply(String text) async {
    if (!_isTalkBackEnabled || text.trim().isEmpty) {
      _changeState(VoiceAssistantState.idle);
      return;
    }
    _changeState(VoiceAssistantState.speaking);
    await _flutterTts.speak(text);
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
      voiceTransactions = savedData.map((e) {
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

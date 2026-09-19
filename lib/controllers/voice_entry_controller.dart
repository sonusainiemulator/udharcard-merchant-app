import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'udhar_controller.dart';
import '../utils/services/localstorage/hive.dart';
import '../utils/services/helpers.dart';
import '../routes/routes_name.dart';

enum VoiceAssistantState { idle, listening, thinking, speaking }

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
        unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
        totalPrice: (map['total_price'] as num?)?.toDouble() ?? 0.0,
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

  // Talk Back Feature Controls
  bool _isTalkBackEnabled = true;
  bool get isTalkBackEnabled => _isTalkBackEnabled;

  String _talkBackLanguage = "hi-IN";
  String get talkBackLanguage => _talkBackLanguage;

  String _transcribedText = "";
  String get transcribedText => _transcribedText;

  String _aiReply = "";
  String get aiReply => _aiReply;

  // Active Category Filter
  String activeCategory = 'ALL'; // 'ALL', 'UDHAR', 'COLLECTION', 'BILL', 'PURCHASE'

  // Parsed fields
  String parsedName = "";
  double parsedAmount = 0.0;
  String parsedType = "Given"; // "Given" or "Received"
  String parsedRemarks = "";
  VoiceParseResult? latestParsedResult;
  XFile? attachedBillImage;
  bool isSubmittingEntry = false;

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

  Future<void> toggleListening() async {
    if (isListening) {
      await stopListening();
    } else {
      await startListening();
    }
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
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
        ),
      );
    } else {
      Helpers.showSnackBar(msg: "Speech recognition unavailable. Check microphone permissions.");
    }
  }

  Future<void> stopListening() async {
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

  Future<void> _processSpeech() async {
    if (_transcribedText.trim().isEmpty) {
      _changeState(VoiceAssistantState.idle);
      return;
    }

    _changeState(VoiceAssistantState.thinking);

    final parsed = parseVoiceInstruction(_transcribedText);
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
      saveTransaction();
    } else {
      _aiReply = parsed.reply;
    }

    await speakReply(_aiReply);
  }

  /// Comprehensive NLP Voice Parser specifically tuned for Indian small businesses & Kirana shops.
  VoiceParseResult parseVoiceInstruction(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return const VoiceParseResult(
        reply: 'Kripya naam aur amount saaf bolen.',
      );
    }

    final lower = normalized.toLowerCase();

    // ── 1. Help & Instructions ───────────────────────────────────────────────
    final helpWords = [
      'hello', 'hi', 'help', 'kya kar', 'kaise', 'what can', 'namaste', 'start', 'kya hai'
    ];
    if (helpWords.any((word) => lower.contains(word))) {
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
      final parts = lower.split(RegExp(r'[,|aur|\band\b]'));
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
            RegExp(r'\b(kitna|balance|total|baki|baaki|hisab|hisaab|summary|paisa|paise|lene|kiska|kaun|hai|hain|ka|ki|ko|se|ne|what|is|my|amount|tell|me|how|much)\b'),
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
    final bool hasMultipleItems = lower.contains(',') || lower.contains('each') || lower.contains('kilo') || lower.contains('soap');
    final List<VoiceBillItem> billItems = [];
    if (hasMultipleItems) {
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

    // ── 6. Customer / Party Name Extraction ──────────────────────────────────
    String cleaned = lower
        .replaceAll(RegExp(r'\d+(?:\.\d+)?'), '')
        .replaceAll(
          RegExp(
            r'\b(rupaye|rupees|rs|udhar|udhaar|ko|se|ne|diya|diye|mila|mile|jama|liya|paid|unpaid|received|gave|given|hai|hain|aaya|aaye|de|maal|saman|each|kilo|kg|packet|soap|piece|pc|darjan)\b',
          ),
          '',
        )
        .trim();
    cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z\u0900-\u097F\s]'), ' ');
    final words = cleaned.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    final name = words.isEmpty
        ? 'Customer'
        : words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

    // Match with existing ledger contact
    final matchedCustomer = findMatchingCustomer(name);

    String remarks = '';
    if (lower.contains('maal liya') || lower.contains('supplier')) {
      remarks = 'Supplier purchase / maal liya';
    } else if (billItems.isNotEmpty) {
      remarks = billItems.map((b) => '${b.quantity} ${b.unit} ${b.title}').join(', ');
    }

    if (amount > 0) {
      final displayName = matchedCustomer != null ? matchedCustomer['name'] : name;
      final friendlyReply = type == 'Given'
          ? '$displayName ko ${amount.toInt()} rupaye udhar safaltapoorvak add ho gaye.'
          : '$displayName se ${amount.toInt()} rupaye safaltapoorvak mil gaye.';

      return VoiceParseResult(
        name: displayName,
        phone: matchedCustomer?['phone']?.toString() ?? '',
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

  /// Fuzzy match against active merchant ledger customers
  Map<String, dynamic>? findMatchingCustomer(String name) {
    if (!Get.isRegistered<UdharController>()) return null;
    final users = Get.find<UdharController>().usersList;
    final q = name.trim().toLowerCase();
    if (q.isEmpty || q == 'customer') return null;

    for (var u in users) {
      if (u is Map) {
        final cName = (u['name'] ?? '').toString().toLowerCase();
        if (cName == q || cName.startsWith(q) || q.startsWith(cName) || cName.contains(q)) {
          return Map<String, dynamic>.from(u);
        }
      }
    }
    return null;
  }

  /// 1-Tap Direct Save to Ledger via UdharController
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

      udharController.applyVoiceEntryPrefill(
        name: parsedName,
        amount: parsedAmount,
        type: parsedType.isEmpty ? 'Given' : parsedType,
      );

      if (udharController.selectedUser != null) {
        await udharController.submitUdhar();
      } else {
        udharController.nameCtrl.text = parsedName;
        udharController.phoneCtrl.text = latestParsedResult?.phone.isNotEmpty == true
            ? latestParsedResult!.phone
            : '9876543210';
        final newCustomer = await udharController.addCustomer();
        if (newCustomer != null) {
          udharController.selectedUser = newCustomer;
          await udharController.submitUdhar();
        }
      }

      Helpers.showSnackBar(
        msg: 'Voice entry saved directly to ledger!',
        title: 'Success',
      );

      await speakReply(
        parsedType == 'Given'
            ? '$parsedName ko ${parsedAmount.toInt()} rupaye udhar ledger mein add ho gaye.'
            : '$parsedName se ${parsedAmount.toInt()} rupaye ledger mein jama ho gaye.',
      );
    } catch (e) {
      if (kDebugMode) print("Error in saveParsedEntryDirectly: $e");
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

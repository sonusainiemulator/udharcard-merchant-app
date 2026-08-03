import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/repositories/udhar_repo.dart';
import '../routes/routes_name.dart';
import '../utils/services/helpers.dart';
import '../utils/services/localstorage/hive.dart';
import '../utils/services/localstorage/keys.dart';
import '../utils/services/subscription_gate_service.dart';
import '../config/app_colors.dart';

class UdharController extends GetxController {
  static UdharController get to => Get.find<UdharController>();

  CustomerLimitState get customerLimitState =>
      SubscriptionGateService.customerLimitState(currentCount: usersList.length);

  void showCustomerLimitNudgeIfNeeded() {
    final String? warning =
        SubscriptionGateService.customerAddSoftWarning(currentCount: usersList.length);
    if (warning != null && warning.isNotEmpty) {
      Helpers.showSnackBar(msg: warning, title: 'Plan Notice');
    }
  }

  Future<void> openVoiceEntryWithSoftGate() async {
    final String nudge = SubscriptionGateService.voiceEntrySoftNudge();
    if (!SubscriptionGateService.isVoiceEntryIncluded()) {
      Helpers.showSnackBar(msg: nudge, title: 'Plan Notice');
    }
    Get.toNamed(RoutesName.voiceEntryScreen);
  }

  bool isOffline = false;
  bool isSyncing = false;

  // QR Payment Status variables
  bool isQrLoading = false;
  String? generatedUpiUri;
  String? qrCodeSvg;
  String? txReference;
  bool isPaymentReceived = false;
  bool isListeningPayment = false;
  Timer? _paymentStatusTimer;

  // ── Form fields for transaction ──────────────────────────────────────────────
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController remarksCtrl = TextEditingController();

  /// The contact selected from the user picker
  Map<String, dynamic>? selectedUser;

  /// Transaction direction: "given" = udhar diya, "received" = payment wapas mila
  String transactionType = "given";
  String paymentMethod = "cash";
  bool isSubmitting = false;

  // ── Form fields for adding customer ──────────────────────────────────────────
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController limitCtrl = TextEditingController();
  final TextEditingController openingBalanceCtrl = TextEditingController();
  final TextEditingController editLimitCtrl = TextEditingController();
  bool isAddingCustomer = false;
  bool isUpdatingLimit = false;

  /// Selected date for new transactions
  DateTime? selectedDate;

  Future<void> pickDateAndTime(BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
      );
      if (time != null) {
        selectedDate = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        update();
      }
    }
  }

  // ── Contact list / search ─────────────────────────────────────
  bool isUsersLoading = false;
  List<dynamic> usersList = [];
  List<dynamic> filteredUsers = [];
  final TextEditingController searchCtrl = TextEditingController();

  // ── Ledger / Detailed transactions ─────────────────────────────
  bool isLedgerLoading = false;
  List<dynamic> ledgerTransactions = [];
  List<dynamic> filteredLedgerTransactions = [];
  DateTimeRange? ledgerDateRange;
  double currentOutstandingBalance = 0.0;
  double currentCreditLimit = 5000.0;
  bool isReportsLoading = false;
  bool isExportingReport = false;
  DateTimeRange? reportsDateRange;
  Map<String, dynamic> reportsSummary = {};
  List<dynamic> reportTransactions = [];
  List<dynamic> reportOutstandingCustomers = [];
  String? lastGeneratedReportPath;

  void setLedgerDateRange(DateTimeRange? range) {
    ledgerDateRange = range;
    _applyLedgerDateFilter();
  }

  void _applyLedgerDateFilter() {
    if (ledgerDateRange == null) {
      filteredLedgerTransactions = List.from(ledgerTransactions);
    } else {
      filteredLedgerTransactions = ledgerTransactions.where((tx) {
        if (tx['created_at'] == null) return true;
        try {
          final DateTime txDate = DateTime.parse(tx['created_at'].toString());
          final start = ledgerDateRange!.start;
          final end = ledgerDateRange!.end.add(const Duration(days: 1)); // Include the end day fully
          return txDate.isAfter(start) && txDate.isBefore(end);
        } catch (_) {
          return true;
        }
      }).toList();
    }
    update();
  }

  @override
  void onInit() {
    super.onInit();
    initConnectivityListener();
    fetchUsers();
  }

  Future<void> checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    isOffline = connectivityResult == ConnectivityResult.none;
    update();
  }

  void initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      isOffline = result == ConnectivityResult.none;
      update();
    });
  }

  // ─────────────────────────────────────────────────────────────
  // User / contact loading
  // ─────────────────────────────────────────────────────────────

  Future<void> fetchUsers() async {
    if (isUsersLoading) return;

    isUsersLoading = true;
    update();

    await checkConnection();

    if (isOffline) {
      Helpers.showSnackBar(msg: 'No internet. Unable to fetch latest customers.');
    } else {
      try {
        final response = await UdharRepo.getUsers();
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success') {
            if (data['data'] != null) {
              if (data['data'] is Map && data['data']['data'] != null) {
                usersList = List<dynamic>.from(data['data']['data']);
              } else if (data['data'] is Map && data['data']['contacts'] != null) {
                usersList = List<dynamic>.from(data['data']['contacts']);
              } else if (data['data'] is Map && data['data']['customers'] != null) {
                usersList = List<dynamic>.from(data['data']['customers']);
              } else if (data['data'] is List) {
                usersList = List<dynamic>.from(data['data']);
              } else {
                usersList = [];
              }
            } else {
              usersList = [];
            }
          } else {
            final msg = data['message']?.toString().trim();
            if (msg != null && msg.isNotEmpty) {
              Helpers.showSnackBar(msg: msg);
            }
          }
        } else {
          Helpers.showSnackBar(msg: 'Unable to fetch latest customers.');
        }
      } catch (_) {
        Helpers.showSnackBar(msg: 'Unable to fetch latest customers.');
      }
    }

    filteredUsers = List.from(usersList);
    isUsersLoading = false;
    update();
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      filteredUsers = List.from(usersList);
    } else {
      final q = query.toLowerCase();
      filteredUsers =
          usersList.where((u) {
            final name = (u['name'] ?? '').toString().toLowerCase();
            final email = (u['email'] ?? '').toString().toLowerCase();
            final phone = (u['phone'] ?? '').toString().toLowerCase();
            return name.contains(q) || email.contains(q) || phone.contains(q);
          }).toList();
    }
    update();
  }

  void selectUser(Map<String, dynamic> user) {
    selectedUser = user;
    update();
  }

  void clearSelectedUser() {
    selectedUser = null;
    update();
  }

  // ─────────────────────────────────────────────────────────────
  // Customer Add / Delete
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> addCustomer() async {
    final String name = nameCtrl.text.trim();
    final String phone =
      phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final String email = emailCtrl.text.trim();
    final String creditLimit =
        limitCtrl.text.trim().isEmpty ? "5000" : limitCtrl.text.trim();
    final String openingBalance =
        openingBalanceCtrl.text.trim().isEmpty
            ? "0"
            : openingBalanceCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      Helpers.showSnackBar(msg: 'Please fill in Name and Phone Number');
      return null;
    }

    if (phone.length < 10 || phone.length > 15) {
      Helpers.showSnackBar(msg: 'Please enter a valid phone number');
      return null;
    }

    final double? parsedLimit = double.tryParse(creditLimit);
    final double? parsedOpeningBalance = double.tryParse(openingBalance);
    if (parsedLimit == null ||
        parsedOpeningBalance == null ||
        parsedLimit < 0 ||
        parsedOpeningBalance < 0) {
      Helpers.showSnackBar(msg: 'Please enter valid numeric amounts');
      return null;
    }

    if (SubscriptionGateService.isHardLimitEnabled() &&
        customerLimitState.isAtOrOverLimit) {
      Helpers.showSnackBar(
        msg:
            'Customer limit reached for ${customerLimitState.planCode} plan. Please upgrade to continue.',
        title: 'Plan Limit',
      );
      return null;
    }

    // Soft-gating warning only: no hard block in current rollout.
    showCustomerLimitNudgeIfNeeded();

    isAddingCustomer = true;
    update();
    await checkConnection();

    Map<String, dynamic>? resultCustomer;

    if (isOffline) {
      Helpers.showSnackBar(msg: 'No internet. Customer add requires live sync.');
    } else {
      try {
        final response = await UdharRepo.addCustomer(
          name: name,
          phone: phone,
          email: email.isEmpty ? null : email,
          creditLimit: creditLimit,
          openingBalance: openingBalance,
        );

        final Map<String, dynamic>? data = _decodeJsonMap(response.body);
        final bool isSuccess = _isApiSuccess(response.statusCode, data);
        if (isSuccess) {
          _showEntitlementWarningIfAny(data);
          Helpers.showSnackBar(
            msg: data?['message'] ?? 'Customer added successfully',
          );
          if (data?['data'] != null) {
            resultCustomer = Map<String, dynamic>.from(data!['data']);
          }
          _resetCustomerForm();
          await fetchUsers();
          _closeAddCustomerScreen(resultCustomer);
        } else {
          final String apiMessage = _extractApiMessage(data, response.body);
          Helpers.showSnackBar(
            msg:
                apiMessage.isNotEmpty
                    ? apiMessage
                    : 'Unable to add customer. Please verify details and try again.',
          );
        }
      } catch (_) {
        Helpers.showSnackBar(
          msg: 'Unable to add customer. Please try again.',
        );
      }
    }

    isAddingCustomer = false;
    update();
    return resultCustomer;
  }

  bool _isApiSuccess(int statusCode, Map<String, dynamic>? data) {
    if (statusCode < 200 || statusCode >= 300) return false;
    final dynamic status = data?['status'];
    if (status == null) return true;
    if (status is bool) return status;
    return status.toString().toLowerCase() == 'success';
  }

  String _extractApiMessage(Map<String, dynamic>? data, String rawBody) {
    final String fromData = data?['message']?.toString().trim() ?? '';
    if (fromData.isNotEmpty) return fromData;

    final String plain = rawBody.trim();
    if (plain.isNotEmpty && !plain.startsWith('{') && !plain.startsWith('[')) {
      return plain;
    }
    return '';
  }

  void _closeAddCustomerScreen(Map<String, dynamic>? resultCustomer) {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back(result: resultCustomer);
    }
  }

  void _resetCustomerForm() {
    nameCtrl.clear();
    phoneCtrl.clear();
    emailCtrl.clear();
    limitCtrl.clear();
    openingBalanceCtrl.clear();
  }

  Future<void> deleteCustomer(String id) async {
    await checkConnection();
    if (isOffline) {
      Helpers.showSnackBar(
        msg: 'You are offline. Unable to delete this customer now.',
      );
      return;
    }

    try {
      final response = await UdharRepo.deleteCustomer(customerId: id);
      final data = _decodeJsonMap(response.body) ?? {};
      if (response.statusCode == 200 && data['status'] == 'success') {
        Helpers.showSnackBar(
          msg: data['message'] ?? 'Customer deleted successfully',
        );
        fetchUsers();
      } else {
        Helpers.showSnackBar(
          msg: data['message']?.toString() ?? 'Failed to delete customer',
        );
      }
    } catch (_) {
      Helpers.showSnackBar(msg: 'Failed to delete customer');
    }
  }

  Future<void> updateCustomerCreditLimit({
    required String customerId,
    required String creditLimit,
  }) async {
    final String value = creditLimit.trim();
    final double? parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) {
      Helpers.showSnackBar(msg: 'Please enter a valid credit limit amount');
      return;
    }

    isUpdatingLimit = true;
    update();

    await checkConnection();
    if (isOffline) {
      Helpers.showSnackBar(msg: 'No internet. Credit limit update requires live sync.');
      isUpdatingLimit = false;
      update();
      return;
    }

    try {
      final response = await UdharRepo.updateCustomerCreditLimit(
        customerId: customerId,
        creditLimit: parsed.toStringAsFixed(2),
      );
      final data = _decodeJsonMap(response.body) ?? {};
      final bool isSuccess =
          response.statusCode == 200 && data['status'] == 'success';

      if (isSuccess) {
        _applyCreditLimitToLocal(customerId: customerId, newLimit: parsed);
        Helpers.showSnackBar(
          msg: data['message']?.toString() ?? 'Credit limit updated.',
        );
      } else {
        final fallbackMsg = data['message']?.toString();
        Helpers.showSnackBar(
          msg:
              (fallbackMsg != null && fallbackMsg.isNotEmpty)
                  ? fallbackMsg
                  : 'Unable to update credit limit',
        );
      }
    } catch (_) {
      Helpers.showSnackBar(msg: 'Unable to update credit limit');
    }

    isUpdatingLimit = false;
    update();
  }

  void _applyCreditLimitToLocal({
    required String customerId,
    required double newLimit,
  }) {
    final idx = usersList.indexWhere((u) => u['id']?.toString() == customerId);
    if (idx != -1) {
      usersList[idx]['credit_limit'] = newLimit;
      filteredUsers = List<dynamic>.from(usersList);
      HiveHelp.write('cached_users', usersList);
    }

    final cachedLedger = HiveHelp.read('cached_ledger_$customerId');
    if (cachedLedger != null && cachedLedger is Map) {
      final updated = Map<String, dynamic>.from(cachedLedger);
      updated['credit_limit'] = newLimit;
      HiveHelp.write('cached_ledger_$customerId', updated);
    }

    if (selectedUser != null && selectedUser!['id']?.toString() == customerId) {
      selectedUser = {...selectedUser!, 'credit_limit': newLimit};
    }

    if (customerId ==
        (selectedUser != null ? selectedUser!['id']?.toString() : null)) {
      currentCreditLimit = newLimit;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Ledger Loading
  // ─────────────────────────────────────────────────────────────

  Future<void> fetchCustomerLedger(String customerId, {bool showLoading = true}) async {
    if (isLedgerLoading) return;

    if (showLoading) {
      isLedgerLoading = true;
      update();
    }
    await checkConnection();

    if (isOffline) {
      Helpers.showSnackBar(msg: 'No internet. Unable to fetch latest ledger.');
    } else {
      try {
        final response = await UdharRepo.getCustomerLedger(
          customerId: customerId,
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success') {
            final payload = data['message'] ?? data['data'] ?? {};
            if (payload['ledgers'] != null) {
              if (payload['ledgers'] is Map && payload['ledgers']['data'] != null) {
                ledgerTransactions = List<dynamic>.from(payload['ledgers']['data']);
              } else if (payload['ledgers'] is List) {
                ledgerTransactions = List<dynamic>.from(payload['ledgers']);
              }
            } else if (payload['transactions'] != null) {
              ledgerTransactions = List<dynamic>.from(payload['transactions']);
            } else {
              ledgerTransactions = [];
            }
            
            if (payload['customer'] != null && payload['customer'] is Map) {
              currentOutstandingBalance = double.tryParse(
                payload['customer']['outstanding_balance']?.toString() ?? '0'
              ) ?? 0.0;
              currentCreditLimit = double.tryParse(
                payload['customer']['credit_limit']?.toString() ?? '5000'
              ) ?? 5000.0;
            } else {
              currentOutstandingBalance = double.tryParse(
                payload['outstanding_balance']?.toString() ?? '0'
              ) ?? 0.0;
              currentCreditLimit = double.tryParse(
                payload['credit_limit']?.toString() ?? '5000'
              ) ?? 5000.0;
            }
          } else {
            final msg = data['message']?.toString().trim();
            if (msg != null && msg.isNotEmpty) {
              Helpers.showSnackBar(msg: msg);
            }
          }
        } else {
          Helpers.showSnackBar(msg: 'Unable to fetch latest ledger.');
        }
      } catch (_) {
        Helpers.showSnackBar(msg: 'Unable to fetch latest ledger.');
      }
    }

    _applyLedgerDateFilter();
    isLedgerLoading = false;
    update();
  }

  Map<String, dynamic>? _decodeJsonMap(String input) {
    try {
      final dynamic parsed = jsonDecode(input);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
    } catch (_) {}
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // Submit
  // ─────────────────────────────────────────────────────────────

  void setType(String type) {
    transactionType = type; // "given" or "received"
    update();
  }

  void setPaymentMethod(String method) {
    paymentMethod = method;
    update();
  }

  Future<void> submitUdhar() async {
    if (selectedUser == null) {
      Helpers.showSnackBar(msg: 'Please select a customer');
      return;
    }
    if (amountCtrl.text.trim().isEmpty) {
      Helpers.showSnackBar(msg: 'Please enter an amount');
      return;
    }
    final double? amt = double.tryParse(amountCtrl.text.trim());
    if (amt == null || amt <= 0) {
      Helpers.showSnackBar(msg: 'Please enter a valid amount');
      return;
    }

    isSubmitting = true;
    update();
    await checkConnection();

    final String selectedCustomerId = selectedUser!['id']?.toString() ?? '';
    final amountStr = amountCtrl.text.trim();
    final remarksStr = remarksCtrl.text.trim();
    final typeStr = transactionType;
    final paymentMethodStr = paymentMethod;

    if (isOffline) {
      Helpers.showSnackBar(msg: 'No internet. Transaction add requires live sync.');
    } else {
      try {
        final response = await UdharRepo.addUdhar(
          customerId: selectedCustomerId,
          amount: amountStr,
          type: typeStr == 'given' ? 'credit' : 'debit',
          remarks: remarksStr,
          paymentMethod: paymentMethodStr,
          createdAt: selectedDate?.toIso8601String(),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['status'] == 'success') {
          Helpers.showSnackBar(
            msg: data['message'] ?? 'Udhar transaction added successfully',
          );
          _resetForm();
          if (Get.context != null) Navigator.of(Get.context!).pop();
          await fetchUsers();
          if (selectedCustomerId.isNotEmpty) {
            await fetchCustomerLedger(selectedCustomerId);
          }
        } else {
          Helpers.showSnackBar(
            msg:
                data['message']?.toString() ??
                'Unable to add transaction. Please try again.',
          );
        }
      } catch (_) {
        Helpers.showSnackBar(
          msg: 'Unable to add transaction. Please try again.',
        );
      }
    }

    isSubmitting = false;
    update();
  }

  void _resetForm() {
    selectedUser = null;
    selectedDate = null;
    amountCtrl.clear();
    remarksCtrl.clear();
    transactionType = "given";
  }

  bool isSendingReminder = false;

  Future<void> sendPaymentReminder(String customerId) async {
    isSendingReminder = true;
    update();
    await checkConnection();

    if (isOffline) {
      Helpers.showSnackBar(
        msg: 'You are offline. Cannot send reminder.',
      );
      isSendingReminder = false;
      update();
      return;
    }

    try {
      final response = await UdharRepo.sendPaymentReminder(
        customerId: customerId,
      );
      final data = _decodeJsonMap(response.body) ?? {};
      if (response.statusCode == 200 && data['status'] == 'success') {
        _showEntitlementWarningIfAny(data);
        Helpers.showSnackBar(
          msg: data['message'] ?? 'Payment reminder sent successfully',
        );
      } else {
        Helpers.showSnackBar(
          msg: data['message']?.toString() ?? 'Failed to send reminder',
        );
      }
    } catch (_) {
      Helpers.showSnackBar(msg: 'Failed to send payment reminder');
    }

    isSendingReminder = false;
    update();
  }

  bool isGeneratingPdf = false;

  bool isCustomerOverdue28Days() {
    if (ledgerTransactions.isEmpty) return false;
    try {
      final oldestPendingTx = ledgerTransactions.lastWhere(
        (tx) => (tx['type'] == 'given' || tx['type'] == 'credit'),
        orElse: () => null,
      );
      if (oldestPendingTx != null && oldestPendingTx['created_at'] != null) {
        final DateTime txDate = DateTime.parse(oldestPendingTx['created_at'].toString());
        final int daysDiff = DateTime.now().difference(txDate).inDays;
        return daysDiff >= 28;
      }
    } catch (_) {}
    return false;
  }

  Future<void> generateAndSendPdfBill(
    String customerId, {
    String channel = 'both',
    String? month,
    String cycle = '28_days',
  }) async {
    isGeneratingPdf = true;
    update();
    await checkConnection();

    if (isOffline) {
      Helpers.showSnackBar(
        msg: 'You are offline. Cannot generate PDF bill.',
      );
      isGeneratingPdf = false;
      update();
      return;
    }

    try {
      final response = await UdharRepo.generatePdfBill(
        customerId: customerId,
        channel: channel,
        month: month,
        cycle: cycle,
      );
      final data = _decodeJsonMap(response.body) ?? {};
      if (response.statusCode == 200 && data['status'] == 'success') {
        _showEntitlementWarningIfAny(data);
        final String pdfUrl = data['data']?['pdf_url']?.toString() ?? '';
        if (pdfUrl.isNotEmpty) {
          try {
            final Uri url = Uri.parse(pdfUrl);
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } catch (_) {}
        }
        Helpers.showSnackBar(
          msg: data['message'] ?? '28-Day Due Bill PDF generated & sent successfully!',
        );
      } else {
        Helpers.showSnackBar(
          msg: data['message']?.toString() ?? 'Failed to generate PDF bill',
        );
      }
    } catch (_) {
      Helpers.showSnackBar(msg: 'Failed to generate 28-Day PDF bill');
    }

    isGeneratingPdf = false;
    update();
  }

  Future<void> generateDynamicQr(String customerId, String amount) async {
    isQrLoading = true;
    update();
    await checkConnection();

    try {
      final response = await UdharRepo.generateQr(
        customerId: customerId,
        amount: amount,
      );
      final data = jsonDecode(response.body);
      String merchantUpi = HiveHelp.read(Keys.merchantUpiId) ?? "paysecure@ybl";
      if (merchantUpi.trim().isEmpty) merchantUpi = "paysecure@ybl";
      if (response.statusCode == 200 && data['status'] == 'success') {
        generatedUpiUri = data['data']['upi_uri'];
        qrCodeSvg = data['data']['qr_code_svg'];
        txReference = data['data']['transaction_reference'];
        _showEntitlementWarningIfAny(data);
      } else {
        generatedUpiUri =
            "upi://pay?pa=$merchantUpi&pn=Merchant&am=$amount&tn=Udhar";
      }
    } catch (_) {
      String merchantUpi = HiveHelp.read(Keys.merchantUpiId) ?? "paysecure@ybl";
      if (merchantUpi.trim().isEmpty) merchantUpi = "paysecure@ybl";
      generatedUpiUri =
          "upi://pay?pa=$merchantUpi&pn=Merchant&am=$amount&tn=Udhar";
    }

    isQrLoading = false;
    update();
  }

  void _showEntitlementWarningIfAny(Map<String, dynamic>? data) {
    if (data == null) return;

    final String? warning =
        data['entitlement']?['warning']?.toString().trim();

    if (warning != null && warning.isNotEmpty) {
      Helpers.showSnackBar(msg: warning, title: 'Plan Notice');
    }
  }

  void startPaymentStatusListener(String customerId) {
    if (isListeningPayment) return;
    isListeningPayment = true;
    isPaymentReceived = false;
    update();

    int pollCount = 0;
    _paymentStatusTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      pollCount++;
      if (pollCount > 15 || isPaymentReceived || !isListeningPayment) {
        timer.cancel();
        isListeningPayment = false;
        update();
        return;
      }

      await checkConnection();
      if (!isOffline) {
        try {
          final response = await UdharRepo.getCustomerLedger(
            customerId: customerId,
          );
          final data = jsonDecode(response.body);
          if (response.statusCode == 200 && data['status'] == 'success') {
            double currentBal =
                double.tryParse(
                  data['data']['outstanding_balance']?.toString() ?? '0',
                ) ??
                0.0;
            if (currentBal < currentOutstandingBalance) {
              isPaymentReceived = true;
              currentOutstandingBalance = currentBal;
              timer.cancel();
              isListeningPayment = false;
              update();
              Helpers.showSnackBar(
                msg:
                    "Payment Received (Udhar Aaya)! Ledger updated successfully.",
                title: 'Success',
                bgColor: AppColors.greenColor,
              );
              if (Get.isDialogOpen == true) {
                Get.back();
              }
            }
          }
        } catch (_) {}
      }
    });
  }

  // ── WhatsApp Payment Reminder ────────────────────────────────────────────────
  Future<void> sendWhatsAppReminder(Map<String, dynamic> customer) async {
    final String phone = (customer['mobile'] ?? customer['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
    final String name = (customer['name'] ?? 'Customer').toString();
    final double balance = (customer['balance'] ?? currentOutstandingBalance).toDouble();
    
    final String merchantUpi = HiveHelp.read(Keys.merchantUpiId) ?? 'paysecure@upi';
    final String upiUrl = "upi://pay?pa=$merchantUpi&pn=Merchant&am=${balance.abs()}&cu=INR";
    
    final String message = "Namaste $name ji,\nUdharCard Merchant par aapka ₹${balance.abs().toStringAsFixed(0)} ka udhar balance pending hai.\nKripya is UPI link se payment karein:\n$upiUrl\n\nDhanyawad!";
    
    if (phone.isEmpty) {
      Helpers.showSnackBar(msg: "Customer phone number unavailable.");
      return;
    }
    
    final String formattedPhone = phone.length == 10 ? "91$phone" : phone;
    final Uri whatsappUri = Uri.parse("whatsapp://send?phone=$formattedPhone&text=${Uri.encodeComponent(message)}");
    final Uri webWhatsappUri = Uri.parse("https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}");
    
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webWhatsappUri)) {
        await launchUrl(webWhatsappUri, mode: LaunchMode.externalApplication);
      } else {
        Helpers.showSnackBar(msg: "Could not open WhatsApp.");
      }
    } catch (e) {
      Helpers.showSnackBar(msg: "Error opening WhatsApp: $e");
    }
  }

  Future<void> fetchReports({DateTimeRange? range}) async {
    reportsDateRange = range ?? reportsDateRange;
    isReportsLoading = true;
    update();

    await checkConnection();

    if (isOffline) {
      Helpers.showSnackBar(msg: 'No internet. Realtime reports sync is unavailable.');
      isReportsLoading = false;
      update();
      return;
    }

    try {
      final response = await UdharRepo.getReports(
        startDate:
            reportsDateRange == null
                ? null
                : DateFormat('yyyy-MM-dd').format(reportsDateRange!.start),
        endDate:
            reportsDateRange == null
                ? null
                : DateFormat('yyyy-MM-dd').format(reportsDateRange!.end),
      );
      final Map<String, dynamic> data = _decodeJsonMap(response.body) ?? {};
      final Map<String, dynamic> payload =
          (data['data'] is Map<String, dynamic>)
              ? Map<String, dynamic>.from(data['data'])
              : (data['data'] is Map)
              ? Map<String, dynamic>.from(data['data'])
              : {};

      if (response.statusCode == 200 && data['status'] == 'success' && payload.isNotEmpty) {
        reportsSummary = {
          'start_date': payload['start_date'],
          'end_date': payload['end_date'],
          'total_credit_given': _asDouble(payload['total_credit_given']),
          'total_debit_received': _asDouble(payload['total_debit_received']),
        };
        reportTransactions = List<dynamic>.from(payload['transactions'] ?? []);
        reportOutstandingCustomers = List<dynamic>.from(
          payload['outstanding_customers'] ?? [],
        );
      } else {
        Helpers.showSnackBar(
          msg: data['message']?.toString() ?? 'Unable to fetch realtime reports.',
        );
      }
    } catch (_) {
      Helpers.showSnackBar(msg: 'Unable to fetch realtime reports.');
    }

    isReportsLoading = false;
    update();
  }

  void clearReportsDateRange() {
    reportsDateRange = null;
    fetchReports();
  }

  Future<void> exportOutstandingCsv() async {
    await _generateReportFile(
      action: () async {
        if (reportOutstandingCustomers.isEmpty && !isReportsLoading) {
          await fetchReports();
        }

        final Directory? directory = await _getReportDirectory();
        if (directory == null) {
          throw Exception('Storage directory unavailable');
        }

        final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final File file = File('${directory.path}/udhar_outstanding_$timestamp.csv');
        final StringBuffer buffer = StringBuffer()
          ..writeln('Customer Name,Phone,Email,Outstanding Balance,Credit Limit');

        for (final dynamic customer in reportOutstandingCustomers) {
          final Map<String, dynamic> row = Map<String, dynamic>.from(customer as Map);
          buffer.writeln(
            '${_csvValue(row['name'])},${_csvValue(row['phone'])},${_csvValue(row['email'])},${_csvValue(_asDouble(row['outstanding_balance']).toStringAsFixed(2))},${_csvValue(_asDouble(row['credit_limit']).toStringAsFixed(2))}',
          );
        }

        await file.writeAsString(buffer.toString());
        lastGeneratedReportPath = file.path;
        await OpenFile.open(file.path);
        Helpers.showSnackBar(msg: 'Outstanding balances CSV generated successfully.');
      },
    );
  }

  Future<void> exportFullLedgerPdf() async {
    await _generateReportFile(
      action: () async {
        if (reportTransactions.isEmpty && !isReportsLoading) {
          await fetchReports();
        }

        final Directory? directory = await _getReportDirectory();
        if (directory == null) {
          throw Exception('Storage directory unavailable');
        }

        final pw.Document document = pw.Document();
        final NumberFormat currency = NumberFormat.currency(
          locale: 'en_IN',
          symbol: 'Rs. ',
          decimalDigits: 2,
        );
        final String generatedAt = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
        final String periodLabel =
            reportsSummary['start_date'] != null && reportsSummary['end_date'] != null
                ? '${reportsSummary['start_date']} to ${reportsSummary['end_date']}'
                : 'All time';

        document.addPage(
          pw.MultiPage(
            build: (context) => [
              pw.Text(
                'Udhar Ledger Statement',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Generated: $generatedAt'),
              pw.Text('Period: $periodLabel'),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Credit Given: ${currency.format(_asDouble(reportsSummary['total_credit_given']))}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Collections: ${currency.format(_asDouble(reportsSummary['total_debit_received']))}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                'Outstanding Customers',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: const ['Customer', 'Phone', 'Outstanding', 'Limit'],
                data: reportOutstandingCustomers.map((dynamic customer) {
                  final row = Map<String, dynamic>.from(customer as Map);
                  return [
                    row['name']?.toString() ?? 'Customer',
                    row['phone']?.toString() ?? '-',
                    currency.format(_asDouble(row['outstanding_balance'])),
                    currency.format(_asDouble(row['credit_limit'])),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                'Transactions',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: const ['Date', 'Customer', 'Type', 'Method', 'Amount', 'Remarks'],
                data: reportTransactions.map((dynamic tx) {
                  final row = Map<String, dynamic>.from(tx as Map);
                  final bool isCredit = _reportType(row['type']) == 'Credit';
                  return [
                    row['created_at']?.toString() ?? '-',
                    row['customer_name']?.toString() ?? row['customer']?['name']?.toString() ?? '-',
                    _reportType(row['type']),
                    row['payment_method']?.toString() ?? 'cash',
                    '${isCredit ? '+' : '-'}${currency.format(_asDouble(row['amount']))}',
                    row['remarks']?.toString() ?? row['notes']?.toString() ?? '-',
                  ];
                }).toList(),
              ),
            ],
          ),
        );

        final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final File file = File('${directory.path}/udhar_ledger_statement_$timestamp.pdf');
        await file.writeAsBytes(await document.save());
        lastGeneratedReportPath = file.path;
        await OpenFile.open(file.path);
        Helpers.showSnackBar(msg: 'Ledger statement PDF generated successfully.');
      },
    );
  }

  Future<void> _generateReportFile({required Future<void> Function() action}) async {
    isExportingReport = true;
    update();
    try {
      await action();
    } catch (e) {
      Helpers.showSnackBar(msg: 'Failed to generate report: $e');
    }
    isExportingReport = false;
    update();
  }

  Future<Directory?> _getReportDirectory() async {
    if (Platform.isAndroid) {
      return getExternalStorageDirectory();
    }
    if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    }
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return getDownloadsDirectory();
    }
    return getApplicationDocumentsDirectory();
  }

  Future<void> syncManual() async {
    if (isSyncing) return;
    isSyncing = true;
    update();
    await fetchUsers();
    isSyncing = false;
    update();
    if (!isOffline) {
      Helpers.showSnackBar(msg: 'Realtime sync completed.');
    }
  }

  double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  String _reportType(dynamic rawType) {
    final String type = rawType?.toString().toLowerCase() ?? '';
    return type == 'given' || type == 'credit' ? 'Credit' : 'Debit';
  }

  String _csvValue(dynamic value) {
    final String text = (value ?? '').toString().replaceAll('"', '""');
    return '"$text"';
  }

  // ── Phonebook Contact Import ────────────────────────────────────────────────
  Future<void> pickContactFromPhonebook() async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final Contact? contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          nameCtrl.text = contact.displayName;
          if (contact.phones.isNotEmpty) {
            String rawPhone = contact.phones.first.number.replaceAll(RegExp(r'\D'), '');
            if (rawPhone.length > 10) {
              rawPhone = rawPhone.substring(rawPhone.length - 10);
            }
            phoneCtrl.text = rawPhone;
          }
          update();
          Helpers.showSnackBar(msg: "Contact imported: ${contact.displayName}");
        }
      } else {
        Helpers.showSnackBar(msg: "Permission denied to access contacts.");
      }
    } catch (e) {
      Helpers.showSnackBar(msg: "Failed to pick contact: $e");
    }
  }

  // ── Local Ledger Backup & Restore ──────────────────────────────────────────
  Future<void> exportLedgerBackup() async {
    try {
      final List customers = HiveHelp.read(Keys.udharCustomers) ?? [];
      final List transactions = HiveHelp.read(Keys.udharTransactions) ?? [];
      
      final Map<String, dynamic> backupData = {
        "version": "1.0.16",
        "timestamp": DateTime.now().toIso8601String(),
        "merchant_upi": HiveHelp.read(Keys.merchantUpiId) ?? "",
        "customers": customers,
        "transactions": transactions,
      };

      final String jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);
      final Directory dir = await getApplicationDocumentsDirectory();
      final String filePath = "${dir.path}/udhar_backup_${DateTime.now().millisecondsSinceEpoch}.json";
      final File file = File(filePath);
      await file.writeAsString(jsonStr);

      await Share.shareXFiles([XFile(filePath)], text: "UdharCard Merchant Ledger Backup JSON");
    } catch (e) {
      Helpers.showSnackBar(msg: "Failed to export backup: $e");
    }
  }

  Future<void> importLedgerBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        final String content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);

        if (data.containsKey("customers")) {
          HiveHelp.write(Keys.udharCustomers, data["customers"]);
          if (data.containsKey("transactions")) {
            HiveHelp.write(Keys.udharTransactions, data["transactions"]);
          }
          if (data.containsKey("merchant_upi") && data["merchant_upi"].toString().isNotEmpty) {
            HiveHelp.write(Keys.merchantUpiId, data["merchant_upi"]);
          }
          fetchUsers();
          Helpers.showSnackBar(msg: "Backup restored successfully!");
        } else {
          Helpers.showSnackBar(msg: "Invalid backup file format.");
        }
      }
    } catch (e) {
      Helpers.showSnackBar(msg: "Error importing backup: $e");
    }
  }

  void stopPaymentStatusListener() {
    isListeningPayment = false;
    _paymentStatusTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      update();
    });
  }

  @override
  void onClose() {
    _paymentStatusTimer?.cancel();
    amountCtrl.dispose();
    remarksCtrl.dispose();
    searchCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    limitCtrl.dispose();
    editLimitCtrl.dispose();
    openingBalanceCtrl.dispose();
    super.onClose();
  }
}

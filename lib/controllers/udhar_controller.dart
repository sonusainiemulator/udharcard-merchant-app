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
import 'package:path_provider/path_provider.dart';
import '../data/repositories/udhar_repo.dart';
import '../data/source/network/api_client.dart';
import '../utils/services/helpers.dart';
import '../utils/services/localstorage/hive.dart';
import '../utils/services/localstorage/keys.dart';
import '../config/app_colors.dart';

class UdharController extends GetxController {
  static UdharController get to => Get.find<UdharController>();

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
      if (!isOffline) {
        ApiClient.syncQueuedRequests();
        syncOfflineTransactions();
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // User / contact loading
  // ─────────────────────────────────────────────────────────────

  Future<void> fetchUsers() async {
    isUsersLoading = true;
    update();
    await checkConnection();

    if (isOffline) {
      final cached = HiveHelp.read('cached_users');
      if (cached != null) {
        usersList = List<dynamic>.from(cached);
      } else {
        usersList = [];
        HiveHelp.write('cached_users', usersList);
      }
    } else {
      syncOfflineTransactions();
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
            HiveHelp.write('cached_users', usersList);
          } else {
            _setUsersFromCacheOrEmpty();
          }
        } else {
          _setUsersFromCacheOrEmpty();
        }
      } catch (_) {
        _setUsersFromCacheOrEmpty();
      }
    }

    filteredUsers = List.from(usersList);
    isUsersLoading = false;
    update();
  }

  void _setUsersFromCacheOrEmpty() {
    final cached = HiveHelp.read('cached_users');
    if (cached != null) {
      usersList = List<dynamic>.from(cached);
    } else {
      usersList = [];
      HiveHelp.write('cached_users', usersList);
    }
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
    final String phone = phoneCtrl.text.trim().replaceAll(' ', '');
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

    if (phone.length < 10) {
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

    isAddingCustomer = true;
    update();
    await checkConnection();

    Map<String, dynamic>? resultCustomer;

    if (isOffline) {
      resultCustomer = _queueOfflineCustomer(
        name: name,
        phone: phone,
        email: email,
        creditLimit: parsedLimit,
        openingBalance: parsedOpeningBalance,
      );
      _resetCustomerForm();
      Helpers.showSnackBar(
        msg: 'Customer saved offline. Will sync when internet is back.',
      );
      if (Get.context != null) Navigator.of(Get.context!).pop(resultCustomer);
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
        if (response.statusCode == 200 && data?['status'] == 'success') {
          Helpers.showSnackBar(
            msg: data?['message'] ?? 'Customer added successfully',
          );
          if (data?['data'] != null) {
            resultCustomer = Map<String, dynamic>.from(data!['data']);
          }
          _resetCustomerForm();
          await fetchUsers();
          if (Get.context != null) Navigator.of(Get.context!).pop(resultCustomer);
        } else {
          resultCustomer = _queueOfflineCustomer(
            name: name,
            phone: phone,
            email: email,
            creditLimit: parsedLimit,
            openingBalance: parsedOpeningBalance,
          );
          _resetCustomerForm();
          Helpers.showSnackBar(
            msg: 'Customer saved offline. Backend sync pending.',
          );
          if (Get.context != null) Navigator.of(Get.context!).pop(resultCustomer);
        }
      } catch (_) {
        resultCustomer = _queueOfflineCustomer(
          name: name,
          phone: phone,
          email: email,
          creditLimit: parsedLimit,
          openingBalance: parsedOpeningBalance,
        );
        _resetCustomerForm();
        Helpers.showSnackBar(
          msg: 'Customer saved offline. Backend sync pending.',
        );
        if (Get.context != null) Navigator.of(Get.context!).pop(resultCustomer);
      }
    }

    isAddingCustomer = false;
    update();
    return resultCustomer;
  }

  void _resetCustomerForm() {
    nameCtrl.clear();
    phoneCtrl.clear();
    emailCtrl.clear();
    limitCtrl.clear();
    openingBalanceCtrl.clear();
  }

  Map<String, dynamic> _queueOfflineCustomer({
    required String name,
    required String phone,
    required String email,
    required double creditLimit,
    required double openingBalance,
  }) {
    final localCustId = 'local_cust_${DateTime.now().millisecondsSinceEpoch}';
    final List<dynamic> queue = List<dynamic>.from(
      HiveHelp.read('offline_customers_queue') ?? [],
    );

    queue.add({
      'local_id': localCustId,
      'name': name,
      'phone': phone,
      'email': email,
      'credit_limit': creditLimit,
      'opening_balance': openingBalance,
      'created_at': DateTime.now().toIso8601String(),
    });
    HiveHelp.write('offline_customers_queue', queue);

    final customerMap = {
      "id": localCustId,
      "name": name,
      "email": email,
      "phone": phone,
      "outstanding_balance": openingBalance,
      "credit_limit": creditLimit,
    };

    usersList.insert(0, customerMap);
    filteredUsers = List.from(usersList);
    HiveHelp.write('cached_users', usersList);
    update();
    return customerMap;
  }

  Future<void> deleteCustomer(String id) async {
    if (id.startsWith('local_cust_')) {
      _deleteLocalQueuedCustomer(id);
      return;
    }

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

    // Local-only customer: update directly in cache and pending create queue.
    if (customerId.startsWith('local_cust_')) {
      _applyCreditLimitToLocal(customerId: customerId, newLimit: parsed);
      Helpers.showSnackBar(msg: 'Credit limit updated for offline customer.');
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
      final bool queued = data['queued'] == true;
      final bool isSuccess =
          response.statusCode == 200 &&
          (data['status'] == 'success' || queued == true);

      if (isSuccess) {
        _applyCreditLimitToLocal(customerId: customerId, newLimit: parsed);
        Helpers.showSnackBar(
          msg:
              queued
                  ? 'Credit limit updated offline. Backend sync pending.'
                  : (data['message']?.toString() ?? 'Credit limit updated.'),
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

    // Keep offline create queue in sync when editing a local-only customer.
    if (customerId.startsWith('local_cust_')) {
      final List<dynamic> queue = List<dynamic>.from(
        HiveHelp.read('offline_customers_queue') ?? [],
      );
      final qIndex = queue.indexWhere(
        (e) => e is Map && e['local_id']?.toString() == customerId,
      );
      if (qIndex != -1) {
        final item = Map<String, dynamic>.from(queue[qIndex]);
        item['credit_limit'] = newLimit;
        queue[qIndex] = item;
        HiveHelp.write('offline_customers_queue', queue);
      }
    }
  }

  void _deleteLocalQueuedCustomer(String id) {
    final List<dynamic> queue = List<dynamic>.from(
      HiveHelp.read('offline_customers_queue') ?? [],
    );
    queue.removeWhere((item) => item['local_id']?.toString() == id);
    HiveHelp.write('offline_customers_queue', queue);

    usersList.removeWhere((u) => u['id'].toString() == id);
    filteredUsers = List.from(usersList);
    HiveHelp.write('cached_users', usersList);
    Helpers.showSnackBar(msg: 'Customer deleted successfully');
    update();
  }

  // ─────────────────────────────────────────────────────────────
  // Ledger Loading
  // ─────────────────────────────────────────────────────────────

  Future<void> fetchCustomerLedger(String customerId, {bool showLoading = true}) async {
    if (showLoading) {
      isLedgerLoading = true;
      update();
    }
    await checkConnection();

    // Local/offline-created customers do not exist on server yet.
    if (customerId.startsWith('local_cust_')) {
      _loadLedgerFromLocalOrEmpty(customerId);
      _applyLedgerDateFilter();
      isLedgerLoading = false;
      update();
      return;
    }

    if (isOffline) {
      final cached = HiveHelp.read('cached_ledger_$customerId');
      if (cached != null) {
        ledgerTransactions = List<dynamic>.from(cached['transactions'] ?? []);
        currentOutstandingBalance =
            double.tryParse(cached['outstanding_balance']?.toString() ?? '0') ??
            0.0;
        currentCreditLimit =
            double.tryParse(cached['credit_limit']?.toString() ?? '5000') ??
            5000.0;
      } else {
        _loadLedgerFromLocalOrEmpty(customerId);
      }
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
            HiveHelp.write('cached_ledger_$customerId', {
              'transactions': ledgerTransactions,
              'outstanding_balance': currentOutstandingBalance,
              'credit_limit': currentCreditLimit,
            });
          } else {
            _loadLedgerFromLocalOrEmpty(customerId);
          }
        } else {
          _loadLedgerFromLocalOrEmpty(customerId);
        }
      } catch (_) {
        _loadLedgerFromLocalOrEmpty(customerId);
      }
    }

    _applyLedgerDateFilter();
    if (showLoading) {
      isLedgerLoading = false;
    }
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

  void _loadLedgerFromLocalOrEmpty(String customerId) {
    final cust = usersList.firstWhere(
      (u) => u['id'].toString() == customerId,
      orElse: () => null,
    );
    if (cust != null) {
      currentOutstandingBalance =
          double.tryParse(cust['outstanding_balance']?.toString() ?? '0') ??
          0.0;
      currentCreditLimit =
          double.tryParse(cust['credit_limit']?.toString() ?? '5000') ?? 5000.0;
    }

    final cached = HiveHelp.read('cached_ledger_$customerId');
    ledgerTransactions = List<dynamic>.from(cached?['transactions'] ?? []);
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

    final identifier =
        selectedUser!['phone']?.toString() ??
        selectedUser!['email']?.toString() ??
        selectedUser!['id']?.toString() ??
        '';
    final String selectedCustomerId = selectedUser!['id']?.toString() ?? '';
    final amountStr = amountCtrl.text.trim();
    final remarksStr = remarksCtrl.text.trim();
    final typeStr = transactionType;
    final paymentMethodStr = paymentMethod;

    if (isOffline) {
      _queueOfflineTransaction(
        customerId: selectedCustomerId,
        customerIdentifier: identifier,
        amount: amountStr,
        type: typeStr,
        remarks: remarksStr,
        paymentMethod: paymentMethodStr,
        createdAt: selectedDate?.toIso8601String(),
      );
      _updateLocalCustomerBalance(selectedCustomerId, identifier, amt, typeStr);
      _resetForm();
      if (Get.context != null) Navigator.of(Get.context!).pop();
      if (selectedCustomerId.isNotEmpty) {
        await fetchCustomerLedger(selectedCustomerId);
      }
      Helpers.showSnackBar(
        msg: 'Transaction saved offline. Will sync when internet is back.',
      );
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
          _updateLocalCustomerBalance(
            selectedCustomerId,
            identifier,
            amt,
            typeStr,
          );
          _resetForm();
          if (Get.context != null) Navigator.of(Get.context!).pop();
          if (selectedCustomerId.isNotEmpty) {
            await fetchCustomerLedger(selectedCustomerId);
          }
        } else {
          _queueOfflineTransaction(
            customerId: selectedCustomerId,
            customerIdentifier: identifier,
            amount: amountStr,
            type: typeStr,
            remarks: remarksStr,
            paymentMethod: paymentMethodStr,
            createdAt: selectedDate?.toIso8601String(),
          );
          _updateLocalCustomerBalance(
            selectedCustomerId,
            identifier,
            amt,
            typeStr,
          );
          _resetForm();
          if (Get.context != null) Navigator.of(Get.context!).pop();
          if (selectedCustomerId.isNotEmpty) {
            await fetchCustomerLedger(selectedCustomerId);
          }
          Helpers.showSnackBar(
            msg: 'Transaction saved offline. Backend sync pending.',
          );
        }
      } catch (_) {
        _queueOfflineTransaction(
          customerId: selectedCustomerId,
          customerIdentifier: identifier,
          amount: amountStr,
          type: typeStr,
          remarks: remarksStr,
          paymentMethod: paymentMethodStr,
          createdAt: selectedDate?.toIso8601String(),
        );
        _updateLocalCustomerBalance(
          selectedCustomerId,
          identifier,
          amt,
          typeStr,
        );
        _resetForm();
        if (Get.context != null) Navigator.of(Get.context!).pop();
        if (selectedCustomerId.isNotEmpty) {
          await fetchCustomerLedger(selectedCustomerId);
        }
        Helpers.showSnackBar(
          msg: 'Transaction saved offline. Backend sync pending.',
        );
      }
    }

    isSubmitting = false;
    update();
  }

  Future<void> syncOfflineTransactions() async {
    if (isSyncing) return;
    await checkConnection();
    if (isOffline) return;

    isSyncing = true;
    update();

    List<dynamic> customersQueue =
        HiveHelp.read('offline_customers_queue') ?? [];
    List<dynamic> txQueue = HiveHelp.read('offline_tx_queue') ?? [];

    if (customersQueue.isNotEmpty || txQueue.isNotEmpty) {
      try {
        final pushResponse = await UdharRepo.pushSync(
          customers: customersQueue,
          transactions: txQueue,
        );
        final pushData = jsonDecode(pushResponse.body);
        print('=== PUSH SYNC RESPONSE: ${pushResponse.statusCode} ===');
        print('=== PUSH SYNC BODY: ${pushResponse.body} ===');
        if (pushResponse.statusCode == 200 && pushData['status'] == 'success') {
          HiveHelp.write('offline_customers_queue', []);
          HiveHelp.write('offline_tx_queue', []);
        } else {
          print('Push Sync Failed: ${pushData['message']}');
        }
      } catch (e) {
        print('=== PUSH SYNC EXCEPTION: $e ===');
        // Keep queue to retry next time
      }
    }

    // Two-way synchronization pull:
    String lastSyncTime =
        HiveHelp.read('last_sync_time') ?? '1970-01-01 00:00:00';
    try {
      final pullResponse = await UdharRepo.pullSync(lastSyncTime: lastSyncTime);
      final pullData = jsonDecode(pullResponse.body);
      if (pullResponse.statusCode == 200 && pullData['status'] == 'success') {
        HiveHelp.write(
          'last_sync_time',
          DateTime.now().toString().substring(0, 19),
        );

        if (pullData['data'] != null) {
          final list = pullData['data']['customers'] ?? pullData['data']['contacts'];
          if (list != null) {
            usersList = List<dynamic>.from(list);
            HiveHelp.write('cached_users', usersList);
          }
        }
      }
    } catch (_) {}

    isSyncing = false;
    update();

    fetchUsers();
  }

  Future<void> syncManual() async {
    if (isSyncing) return;
    await checkConnection();
    if (isOffline) {
      Helpers.showSnackBar(msg: "You are offline. Cannot sync.");
      return;
    }
    
    isSyncing = true;
    update();
    
    bool hasPushed = false;
    bool hasPulled = false;

    List<dynamic> customersQueue = HiveHelp.read('offline_customers_queue') ?? [];
    List<dynamic> txQueue = HiveHelp.read('offline_tx_queue') ?? [];

    if (customersQueue.isNotEmpty || txQueue.isNotEmpty) {
      try {
        final pushResponse = await UdharRepo.pushSync(
          customers: customersQueue,
          transactions: txQueue,
        );
        final pushData = jsonDecode(pushResponse.body);
        if (pushResponse.statusCode == 200 && pushData['status'] == 'success') {
          HiveHelp.write('offline_customers_queue', []);
          HiveHelp.write('offline_tx_queue', []);
          hasPushed = true;
        } else {
          Helpers.showSnackBar(msg: "Sync Push Failed: ${pushData['message'] ?? 'Unknown error'}");
        }
      } catch (e) {
        Helpers.showSnackBar(msg: "Sync Push Error: $e");
      }
    }

    String lastSyncTime = HiveHelp.read('last_sync_time') ?? '1970-01-01 00:00:00';
    try {
      final pullResponse = await UdharRepo.pullSync(lastSyncTime: lastSyncTime);
      final pullData = jsonDecode(pullResponse.body);
      if (pullResponse.statusCode == 200 && pullData['status'] == 'success') {
        HiveHelp.write('last_sync_time', DateTime.now().toString().substring(0, 19));
        if (pullData['data'] != null) {
          final list = pullData['data']['customers'] ?? pullData['data']['contacts'];
          if (list != null) {
            usersList = List<dynamic>.from(list);
            HiveHelp.write('cached_users', usersList);
          }
        }
        hasPulled = true;
      }
    } catch (_) {}

    isSyncing = false;
    update();
    
    if (hasPushed || hasPulled || (customersQueue.isEmpty && txQueue.isEmpty)) {
      Helpers.showSnackBar(msg: "Sync Completed Successfully.");
    }
    fetchUsers();
  }

  void _queueOfflineTransaction({
    required String customerId,
    required String customerIdentifier,
    required String amount,
    required String type,
    required String remarks,
    required String paymentMethod,
    String? createdAt,
  }) {
    final List<dynamic> queue = List<dynamic>.from(
      HiveHelp.read('offline_tx_queue') ?? [],
    );

    queue.add({
      'local_id': 'local_tx_${DateTime.now().millisecondsSinceEpoch}',
      'customer_id': customerId,
      'user_identifier': customerIdentifier,
      'amount': amount,
      'type': type,
      'remarks': remarks,
      'payment_method': paymentMethod,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    });

    HiveHelp.write('offline_tx_queue', queue);
  }

  int _findCustomerIndex({
    required String customerId,
    required String fallback,
  }) {
    if (customerId.isNotEmpty) {
      final idIndex = usersList.indexWhere(
        (u) => u['id']?.toString() == customerId,
      );
      if (idIndex != -1) return idIndex;
    }

    final byPhone = usersList.indexWhere(
      (u) => u['phone']?.toString() == fallback,
    );
    if (byPhone != -1) return byPhone;

    return usersList.indexWhere((u) => u['email']?.toString() == fallback);
  }

  void _updateLocalCustomerBalance(
    String customerId,
    String fallbackIdentifier,
    double amt,
    String type,
  ) {
    final index = _findCustomerIndex(
      customerId: customerId,
      fallback: fallbackIdentifier,
    );
    if (index != -1) {
      double currentBal =
          double.tryParse(
            usersList[index]['outstanding_balance']?.toString() ?? '0',
          ) ??
          0.0;
      if (type == 'given') {
        currentBal += amt;
      } else {
        currentBal -= amt;
      }
      usersList[index]['outstanding_balance'] = currentBal;
      filteredUsers = List.from(usersList);
      HiveHelp.write('cached_users', usersList);
    }

    final resolvedCustomerId =
        customerId.isNotEmpty
            ? customerId
            : (index != -1
                ? usersList[index]['id'].toString()
                : fallbackIdentifier);

    // Append to cached ledger
    final cachedLedger =
        HiveHelp.read('cached_ledger_$resolvedCustomerId') ??
        {
          'transactions': [],
          'outstanding_balance': 0.0,
          'credit_limit': 5000.0,
        };
    final list = List<dynamic>.from(cachedLedger['transactions'] ?? []);
    list.insert(0, {
      'id': 'local_tx_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amt,
      'type': type,
      'remarks':
          remarksCtrl.text.trim().isNotEmpty
              ? remarksCtrl.text.trim()
              : (type == 'given' ? 'Udhar Given' : 'Payment Received'),
      'created_at': DateTime.now().toString().substring(0, 19),
      'due_date': null,
    });

    double newBal = 0.0;
    double limitVal = 5000.0;
    final match = usersList.firstWhere(
      (u) => u['id'].toString() == resolvedCustomerId,
      orElse: () => null,
    );
    if (match != null) {
      newBal =
          double.tryParse(match['outstanding_balance']?.toString() ?? '0.0') ??
          0.0;
      limitVal =
          double.tryParse(match['credit_limit']?.toString() ?? '5000.0') ??
          5000.0;
    }

    HiveHelp.write('cached_ledger_$resolvedCustomerId', {
      'transactions': list,
      'outstanding_balance': newBal,
      'credit_limit': limitVal,
    });
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

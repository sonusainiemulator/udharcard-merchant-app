import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/repositories/udhar_repo.dart';
import '../data/source/network/api_client.dart';
import '../utils/services/helpers.dart';
import '../utils/services/localstorage/hive.dart';
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

  // ── Contact list / search ─────────────────────────────────────
  bool isUsersLoading = false;
  List<dynamic> usersList = [];
  List<dynamic> filteredUsers = [];
  final TextEditingController searchCtrl = TextEditingController();

  // ── Ledger / Detailed transactions ─────────────────────────────
  bool isLedgerLoading = false;
  List<dynamic> ledgerTransactions = [];
  double currentOutstandingBalance = 0.0;
  double currentCreditLimit = 5000.0;

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

  Future<void> addCustomer() async {
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
      return;
    }

    if (phone.length < 10) {
      Helpers.showSnackBar(msg: 'Please enter a valid phone number');
      return;
    }

    final double? parsedLimit = double.tryParse(creditLimit);
    final double? parsedOpeningBalance = double.tryParse(openingBalance);
    if (parsedLimit == null ||
        parsedOpeningBalance == null ||
        parsedLimit < 0 ||
        parsedOpeningBalance < 0) {
      Helpers.showSnackBar(msg: 'Please enter valid numeric amounts');
      return;
    }

    isAddingCustomer = true;
    update();
    await checkConnection();

    if (isOffline) {
      _queueOfflineCustomer(
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
      if (Get.context != null) Navigator.of(Get.context!).pop();
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
          _resetCustomerForm();
          await fetchUsers();
          if (Get.context != null) Navigator.of(Get.context!).pop();
        } else {
          _queueOfflineCustomer(
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
          if (Get.context != null) Navigator.of(Get.context!).pop();
        }
      } catch (_) {
        _queueOfflineCustomer(
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
        if (Get.context != null) Navigator.of(Get.context!).pop();
      }
    }

    isAddingCustomer = false;
    update();
  }

  void _resetCustomerForm() {
    nameCtrl.clear();
    phoneCtrl.clear();
    emailCtrl.clear();
    limitCtrl.clear();
    openingBalanceCtrl.clear();
  }

  void _queueOfflineCustomer({
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

    usersList.insert(0, {
      "id": localCustId,
      "name": name,
      "email": email,
      "phone": phone,
      "outstanding_balance": openingBalance,
      "credit_limit": creditLimit,
    });
    filteredUsers = List.from(usersList);
    HiveHelp.write('cached_users', usersList);
    update();
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

  Future<void> fetchCustomerLedger(String customerId) async {
    isLedgerLoading = true;
    update();
    await checkConnection();

    // Local/offline-created customers do not exist on server yet.
    if (customerId.startsWith('local_cust_')) {
      _loadLedgerFromLocalOrEmpty(customerId);
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

    if (isOffline) {
      _queueOfflineTransaction(
        customerId: selectedCustomerId,
        customerIdentifier: identifier,
        amount: amountStr,
        type: typeStr,
        remarks: remarksStr,
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
          paymentMethod: 'cash',
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
        if (pushResponse.statusCode == 200 && pushData['status'] == 'success') {
          HiveHelp.write('offline_customers_queue', []);
          HiveHelp.write('offline_tx_queue', []);
        }
      } catch (_) {
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

  void _queueOfflineTransaction({
    required String customerId,
    required String customerIdentifier,
    required String amount,
    required String type,
    required String remarks,
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
      'created_at': DateTime.now().toIso8601String(),
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
    amountCtrl.clear();
    remarksCtrl.clear();
    transactionType = "given";
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
      if (response.statusCode == 200 && data['status'] == 'success') {
        generatedUpiUri = data['data']['upi_uri'];
        qrCodeSvg = data['data']['qr_code_svg'];
        txReference = data['data']['transaction_reference'];
      } else {
        generatedUpiUri =
            "upi://pay?pa=paysecure@ybl&pn=Merchant&am=$amount&tn=Udhar";
      }
    } catch (_) {
      generatedUpiUri =
          "upi://pay?pa=paysecure@ybl&pn=Merchant&am=$amount&tn=Udhar";
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

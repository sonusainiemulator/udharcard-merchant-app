import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../controllers/udhar_controller.dart';
import '../../data/repositories/udhar_repo.dart';
import 'helpers.dart';
import 'localstorage/hive.dart';

class OfflineSyncService extends GetxService {
  static OfflineSyncService get to => Get.find<OfflineSyncService>();

  static const String _offlineQueueKey = 'offline_pending_transactions';

  final RxInt pendingCount = 0.obs;
  final RxBool isSyncing = false.obs;
  StreamSubscription<ConnectivityResult>? _connectivitySub;

  @override
  void onInit() {
    super.onInit();
    _loadPendingCount();
    _initConnectivityListener();
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    super.onClose();
  }

  void _loadPendingCount() {
    final list = getPendingTransactions();
    pendingCount.value = list.length;
  }

  void _initConnectivityListener() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        // Automatically sync pending transactions when network reconnects
        if (pendingCount.value > 0 && !isSyncing.value) {
          syncPendingTransactions();
        }
      }
    });
  }

  /// Retrieve all locally queued transactions
  List<Map<String, dynamic>> getPendingTransactions() {
    try {
      final dynamic raw = HiveHelp.read(_offlineQueueKey);
      if (raw == null) return [];
      if (raw is List) {
        return raw.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          } else if (item is String) {
            return Map<String, dynamic>.from(jsonDecode(item));
          }
          return <String, dynamic>{};
        }).where((map) => map.isNotEmpty).toList();
      }
    } catch (e) {
      debugPrint("OfflineSyncService.getPendingTransactions error: $e");
    }
    return [];
  }

  /// Queue a new transaction when network fails or device is offline
  Future<void> queueTransaction({
    required String customerId,
    required String customerName,
    required String amount,
    required String type, // "credit" or "debit"
    required String remarks,
    String paymentMethod = "cash",
    String? billImagePath,
    String? createdAt,
    String? idempotencyKey,
  }) async {
    final List<Map<String, dynamic>> currentQueue = getPendingTransactions();

    final String localId =
        "local_tx_${DateTime.now().millisecondsSinceEpoch}_${customerId}_${amount.replaceAll('.', '_')}";
    final String key = idempotencyKey ?? localId;

    final Map<String, dynamic> newTx = {
      'local_id': localId,
      'customer_id': customerId,
      'customer_name': customerName,
      'amount': amount,
      'type': type,
      'remarks': remarks,
      'payment_method': paymentMethod,
      'bill_image_path': billImagePath,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'idempotency_key': key,
      'queued_at': DateTime.now().toIso8601String(),
      'sync_status': 'pending',
    };

    currentQueue.add(newTx);
    await _saveQueue(currentQueue);
    pendingCount.value = currentQueue.length;

    Helpers.showSnackBar(
      msg: 'Offline entry saved for $customerName. Will auto-sync once connected.',
      title: 'Saved Offline',
    );
  }

  /// Sync all pending items to backend API
  Future<int> syncPendingTransactions({bool showToast = true}) async {
    if (isSyncing.value) return 0;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      return 0;
    }

    final List<Map<String, dynamic>> queue = getPendingTransactions();
    if (queue.isEmpty) {
      pendingCount.value = 0;
      return 0;
    }

    isSyncing.value = true;
    int syncedCount = 0;
    final List<Map<String, dynamic>> remainingQueue = [];

    try {
      for (final tx in queue) {
        try {
          final response = await UdharRepo.addUdhar(
            customerId: tx['customer_id']?.toString() ?? '',
            amount: tx['amount']?.toString() ?? '0',
            type: tx['type']?.toString() ?? 'credit',
            remarks: tx['remarks']?.toString() ?? '',
            paymentMethod: tx['payment_method']?.toString() ?? 'cash',
            createdAt: tx['created_at']?.toString(),
            idempotencyKey: tx['idempotency_key']?.toString(),
            billImagePath: tx['bill_image_path']?.toString(),
          );

          if (response.statusCode == 200 ||
              response.statusCode == 201 ||
              response.statusCode == 409) {
            // Success or already processed (idempotent duplicate)
            syncedCount++;
          } else {
            // Keep in queue to retry next time
            remainingQueue.add(tx);
          }
        } catch (e) {
          debugPrint("Failed to sync individual offline tx: $e");
          remainingQueue.add(tx);
        }
      }

      await _saveQueue(remainingQueue);
      pendingCount.value = remainingQueue.length;

      if (syncedCount > 0) {
        if (Get.isRegistered<UdharController>()) {
          Get.find<UdharController>().fetchUsers();
        }
        if (showToast) {
          Helpers.showSnackBar(
            msg: 'Successfully synced $syncedCount offline transaction${syncedCount > 1 ? 's' : ''} to server.',
            title: 'Sync Complete',
          );
        }
      }
    } finally {
      isSyncing.value = false;
    }

    return syncedCount;
  }

  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    try {
      final List<String> encoded = queue.map((e) => jsonEncode(e)).toList();
      HiveHelp.write(_offlineQueueKey, encoded);
    } catch (e) {
      debugPrint("OfflineSyncService._saveQueue error: $e");
    }
  }

  /// Clear queue manually if needed
  Future<void> clearQueue() async {
    await HiveHelp.remove(_offlineQueueKey);
    pendingCount.value = 0;
  }
}

import 'package:http/http.dart' as http;
import '../../utils/app_constants.dart';
import '../source/network/api_client.dart';

class UdharRepo {
  /// POST /api/merchant/udhar/ledger — add a new udhar transaction (Credit/Debit)
  static Future<http.Response> addUdhar({
    required String customerId,
    required String amount,
    required String type, // "credit" or "debit"
    required String remarks,
    String paymentMethod = "cash",
  }) async {
    return await ApiClient.post(
      ENDPOINT_URL: AppConstants.addUdharUrl,
      fields: {
        "customer_id": customerId,
        "amount": amount,
        "type": type,
        "payment_method": paymentMethod,
        "notes": remarks,
      },
    );
  }

  /// GET /api/merchant/udhar/contacts — reuse existing contacts endpoint
  static Future<http.Response> getUsers() async {
    return await ApiClient.get(ENDPOINT_URL: AppConstants.getContactsUrl);
  }

  /// POST /api/merchant/udhar/customers - Add new customer
  static Future<http.Response> addCustomer({
    required String name,
    required String phone,
    String? email,
    required String creditLimit,
    required String openingBalance,
  }) async {
    final Map<String, dynamic> payload = {
      "name": name,
      "phone": phone,
      "credit_limit": creditLimit,
      "opening_balance": openingBalance,
    };
    if (email != null && email.trim().isNotEmpty) {
      payload["email"] = email.trim();
    }

    return await ApiClient.post(
      ENDPOINT_URL: AppConstants.addCustomerUrl,
      fields: payload,
    );
  }

  /// PUT /api/merchant/udhar/customers/{id}/credit-limit - Update customer credit limit
  static Future<http.Response> updateCustomerCreditLimit({
    required String customerId,
    required String creditLimit,
  }) async {
    return await ApiClient.put(
      ENDPOINT_URL: "${AppConstants.updateCustomerUrl}/$customerId/credit-limit",
      fields: {"credit_limit": creditLimit},
    );
  }

  /// DELETE /api/merchant/udhar/customers/{id} - Delete customer
  static Future<http.Response> deleteCustomer({
    required String customerId,
  }) async {
    return await ApiClient.delete(
      ENDPOINT_URL: "${AppConstants.deleteCustomerUrl}/$customerId",
    );
  }

  /// GET /api/merchant/udhar/customers/{id}/ledger - Get customer ledger history
  static Future<http.Response> getCustomerLedger({
    required String customerId,
  }) async {
    return await ApiClient.get(
      ENDPOINT_URL: "${AppConstants.customerLedgerUrl}/$customerId/ledger",
    );
  }

  /// GET /api/merchant/udhar/sync - pull sync updates since last_sync_time
  static Future<http.Response> pullSync({required String lastSyncTime}) async {
    return await ApiClient.get(
      ENDPOINT_URL: "${AppConstants.udharSyncUrl}?last_sync_time=$lastSyncTime",
    );
  }

  /// POST /api/merchant/udhar/sync - push batch sync updates
  static Future<http.Response> pushSync({
    required List<dynamic> customers,
    required List<dynamic> transactions,
  }) async {
    // Transform transactions to backend 'ledgers' format
    final List<Map<String, dynamic>> ledgers = [];
    for (var tx in transactions) {
      if (tx is Map) {
        final txMap = Map<String, dynamic>.from(tx);
        final String origCustId = txMap['customer_id']?.toString() ?? '';
        
        final Map<String, dynamic> ledgerItem = {
          'local_id': txMap['local_id']?.toString() ?? 'local_tx_${DateTime.now().millisecondsSinceEpoch}',
          'amount': txMap['amount']?.toString() ?? '0.00',
          'type': txMap['type'] == 'given' ? 'credit' : 'debit',
          'payment_method': 'cash',
          'notes': txMap['remarks'] ?? '',
          'due_date': txMap['due_date'],
        };
        
        if (origCustId.startsWith('local_cust_')) {
          ledgerItem['customer_local_id'] = origCustId;
          ledgerItem['customer_id'] = null;
        } else {
          ledgerItem['customer_local_id'] = null;
          ledgerItem['customer_id'] = int.tryParse(origCustId);
        }
        
        ledgers.add(ledgerItem);
      }
    }

    return await ApiClient.post(
      ENDPOINT_URL: AppConstants.udharSyncUrl,
      fields: {
        "customers": customers,
        "ledgers": ledgers,
      },
    );
  }

  /// POST /merchant/qr/generate - Generate dynamic payment QR
  static Future<http.Response> generateQr({
    required String customerId,
    required String amount,
  }) async {
    return await ApiClient.post(
      ENDPOINT_URL: AppConstants.customerQrUrl,
      fields: {"customer_id": customerId, "amount": amount},
    );
  }
}

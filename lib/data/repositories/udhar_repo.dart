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
    String? createdAt,
  }) async {
    final Map<String, dynamic> legacyFields = {
      "customer_id": customerId,
      "amount": amount,
      "type": type,
      "payment_method": paymentMethod,
      "notes": remarks,
    };
    if (createdAt != null && createdAt.isNotEmpty) {
      legacyFields["created_at"] = createdAt;
    }

    final legacyResponse = await ApiClient.post(
      ENDPOINT_URL: "${AppConstants.addUdharUrl}/$customerId/entry",
      fields: legacyFields,
    );

    if (legacyResponse.statusCode != 404 && legacyResponse.statusCode != 405) {
      return legacyResponse;
    }

    // Compatibility fallback for backends using /merchant/udhar/ledger payload.
    final Map<String, dynamic> modernFields = {
      "customer_id": customerId,
      "email_or_phone": customerId,
      "amount": amount,
      "type": type == "credit" ? "given" : "received",
      "payment_method": paymentMethod,
      "remarks": remarks,
    };
    if (createdAt != null && createdAt.isNotEmpty) {
      modernFields["created_at"] = createdAt;
    }

    return await ApiClient.post(
      ENDPOINT_URL: AppConstants.addUdharUrl,
      fields: modernFields,
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
    String address = '',
    String note = '',
    String type = 'Customer',
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
    if (address.trim().isNotEmpty) {
      payload["address"] = address.trim();
    }
    if (note.trim().isNotEmpty) {
      payload["note"] = note.trim();
    }
    if (type.trim().isNotEmpty) {
      payload["type"] = type.trim();
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
    final putResponse = await ApiClient.put(
      ENDPOINT_URL:
          "${AppConstants.updateCustomerUrl}/$customerId/credit-limit",
      fields: {"credit_limit": creditLimit},
    );

    if (putResponse.statusCode != 404 && putResponse.statusCode != 405) {
      return putResponse;
    }

    // Legacy fallback for older backend route style.
    return await ApiClient.post(
      ENDPOINT_URL: "${AppConstants.updateCustomerUrl}/$customerId",
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
    final response = await ApiClient.get(
      ENDPOINT_URL: "${AppConstants.addCustomerUrl}/$customerId/ledger",
    );

    if (response.statusCode != 404 && response.statusCode != 405) {
      return response;
    }

    return await ApiClient.get(
      ENDPOINT_URL: "${AppConstants.customerLedgerUrl}/$customerId",
    );
  }

  /// GET /api/merchant/udhar/reports - Get report summary, outstanding balances and ledger rows
  static Future<http.Response> getReports({
    String? startDate,
    String? endDate,
  }) async {
    String endpoint = AppConstants.udharReportsUrl;
    final List<String> query = [];
    if (startDate != null && startDate.isNotEmpty) {
      query.add("start_date=$startDate");
    }
    if (endDate != null && endDate.isNotEmpty) {
      query.add("end_date=$endDate");
    }
    if (query.isNotEmpty) {
      endpoint = "$endpoint?${query.join('&')}";
    }

    return await ApiClient.get(ENDPOINT_URL: endpoint);
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
          'local_id':
              txMap['local_id']?.toString() ??
              'local_tx_${DateTime.now().millisecondsSinceEpoch}',
          'amount': txMap['amount']?.toString() ?? '0.00',
          'type': txMap['type'] == 'given' ? 'credit' : 'debit',
          'payment_method': 'cash',
          'notes': txMap['remarks'] ?? '',
          'due_date': txMap['due_date'],
          'user_identifier': txMap['user_identifier'],
          'created_at': txMap['created_at'],
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
      fields: {"customers": customers, "ledgers": ledgers},
    );
  }

  /// POST /merchant/qr/generate - Generate dynamic payment QR
  static Future<http.Response> generateQr({
    required String customerId,
    required String amount,
  }) async {
    final response = await ApiClient.post(
      ENDPOINT_URL: "${AppConstants.customerQrUrl}/generate",
      fields: {"customer_id": customerId, "amount": amount},
    );

    if (response.statusCode != 404 && response.statusCode != 405) {
      return response;
    }

    return await ApiClient.get(
      ENDPOINT_URL: "${AppConstants.customerQrUrl}/$customerId?amount=$amount",
    );
  }

  /// POST /merchant/udhar/customers/{id}/remind - Send payment reminder push notification
  static Future<http.Response> sendPaymentReminder({
    required String customerId,
  }) async {
    final response = await ApiClient.post(
      ENDPOINT_URL: "${AppConstants.addCustomerUrl}/$customerId/remind",
    );

    if (response.statusCode != 404 && response.statusCode != 405) {
      return response;
    }

    // Legacy fallback.
    return await ApiClient.post(
      ENDPOINT_URL: AppConstants.sendReminderUrl,
      fields: {"customer_id": customerId},
    );
  }

  /// POST /merchant/udhar/customers/{id}/generate-pdf-bill - Request 28-day / monthly PDF bill generation & dispatch
  static Future<http.Response> generatePdfBill({
    required String customerId,
    required String channel,
    String? month,
    String cycle = "28_days",
  }) async {
    final List<String> query = ["channel=$channel", "cycle=$cycle"];
    if (month != null && month.isNotEmpty) {
      query.add("month=$month");
    }
    return await ApiClient.get(
      ENDPOINT_URL:
          "${AppConstants.generatePdfBillUrl}/$customerId?${query.join('&')}",
    );
  }
}

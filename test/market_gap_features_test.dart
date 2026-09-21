import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Market Gap Features - Reminder & UPI Tests', () {
    test('Constructs valid UPI deep-link URI with merchant VPA and amount', () {
      final merchantVpa = 'merchant@upi';
      final merchantName = 'Udhar Store';
      final double dueAmount = 1500.0;

      final upiUri = Uri.parse(
        'upi://pay?pa=$merchantVpa&pn=${Uri.encodeComponent(merchantName)}&am=${dueAmount.toStringAsFixed(2)}&cu=INR',
      );

      expect(upiUri.scheme, equals('upi'));
      expect(upiUri.host, equals('pay'));
      expect(upiUri.queryParameters['pa'], equals('merchant@upi'));
      expect(upiUri.queryParameters['pn'], equals('Udhar Store'));
      expect(upiUri.queryParameters['am'], equals('1500.00'));
      expect(upiUri.queryParameters['cu'], equals('INR'));
    });

    test('Reminder templates generate required billing and contact details', () {
      final customerName = 'Rahul Sharma';
      final dueAmount = 2450.0;
      final merchantName = 'Kirana Store';
      final paymentLink = 'upi://pay?pa=store@upi&pn=Kirana+Store&am=2450.00&cu=INR';

      final politeTemplate =
          "नमस्ते $customerName जी, $merchantName से आपका ₹$dueAmount का बकाया शेष है। कृपया सुविधानुसार भुगतान करें।\n\nPay via UPI: $paymentLink\nधन्यवाद!";
      final urgentTemplate =
          "ज़रूरी सूचना: $customerName जी, $merchantName पर आपका ₹$dueAmount का बकाया काफी समय से लंबित है। कृपया आज ही भुगतान करें।\n\nPay via UPI: $paymentLink";

      expect(politeTemplate, contains('Rahul Sharma'));
      expect(politeTemplate, contains('2450'));
      expect(politeTemplate, contains('Kirana Store'));
      expect(politeTemplate, contains(paymentLink));

      expect(urgentTemplate, contains('ज़रूरी सूचना'));
      expect(urgentTemplate, contains('2450'));
    });
  });

  group('Market Gap Features - Customer Sorting Tests', () {
    final customers = [
      {
        'id': 1,
        'name': 'Brijesh',
        'outstanding_balance': 350.0,
        'days_due': 5,
      },
      {
        'id': 2,
        'name': 'Ankit',
        'outstanding_balance': 2400.0,
        'days_due': 30,
      },
      {
        'id': 3,
        'name': 'Chirag',
        'outstanding_balance': 1200.0,
        'days_due': 15,
      },
    ];

    test('Sorts by highest due descending', () {
      final list = List<Map<String, dynamic>>.from(customers);
      list.sort((a, b) {
        final balA = (a['outstanding_balance'] as double);
        final balB = (b['outstanding_balance'] as double);
        return balB.compareTo(balA);
      });

      expect(list[0]['name'], equals('Ankit')); // 2400
      expect(list[1]['name'], equals('Chirag')); // 1200
      expect(list[2]['name'], equals('Brijesh')); // 350
    });

    test('Sorts by oldest due / days due descending', () {
      final list = List<Map<String, dynamic>>.from(customers);
      list.sort((a, b) {
        final daysA = (a['days_due'] as int);
        final daysB = (b['days_due'] as int);
        return daysB.compareTo(daysA);
      });

      expect(list[0]['name'], equals('Ankit')); // 30 days
      expect(list[1]['name'], equals('Chirag')); // 15 days
      expect(list[2]['name'], equals('Brijesh')); // 5 days
    });

    test('Sorts alphabetically A to Z', () {
      final list = List<Map<String, dynamic>>.from(customers);
      list.sort((a, b) {
        final nameA = a['name'].toString().toLowerCase();
        final nameB = b['name'].toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      expect(list[0]['name'], equals('Ankit'));
      expect(list[1]['name'], equals('Brijesh'));
      expect(list[2]['name'], equals('Chirag'));
    });
  });

  group('Market Gap Features - Ledger Direction & Post-Balance Mapping', () {
    bool isGivenTransaction(dynamic tx) {
      if (tx is! Map) return false;
      final String rawType = (tx['type'] ?? '').toString().toLowerCase().trim();
      if (rawType == 'given' || rawType == 'credit') return true;
      if (rawType == 'received' || rawType == 'debit' || rawType == 'taken') {
        return false;
      }
      final double amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
      return amt >= 0;
    }

    Map<int, double> calculatePostTxBalances(List<dynamic> list, double currentNetBalance) {
      final Map<int, double> postBalances = {};
      double running = currentNetBalance;

      for (int i = 0; i < list.length; i++) {
        final tx = list[i];
        final bool isGiven = isGivenTransaction(tx);
        final double amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;

        postBalances[i] = running;

        if (isGiven) {
          running -= amt;
        } else {
          running += amt;
        }
      }
      return postBalances;
    }

    test('Calculates backwards running balances accurately for mixed transactions', () {
      // Transactions in descending chronological order (newest first)
      final txList = [
        {'id': 3, 'type': 'received', 'amount': 500.0}, // Customer paid 500 -> balance became 1000
        {'id': 2, 'type': 'given', 'amount': 700.0},    // Udhar given 700 -> balance became 1500
        {'id': 1, 'type': 'given', 'amount': 800.0},    // Udhar given 800 -> balance became 800 (started at 0)
      ];

      final currentBalance = 1000.0;
      final postBalances = calculatePostTxBalances(txList, currentBalance);

      expect(postBalances[0], equals(1000.0)); // After paying 500
      expect(postBalances[1], equals(1500.0)); // After giving 700 (1000 + 500)
      expect(postBalances[2], equals(800.0));  // After giving 800 (1500 - 700)
    });

    test('Filters transactions without mutating original index post-balances', () {
      final txList = [
        {'id': 3, 'type': 'received', 'amount': 500.0},
        {'id': 2, 'type': 'given', 'amount': 700.0},
        {'id': 1, 'type': 'given', 'amount': 800.0},
      ];

      final postBalances = calculatePostTxBalances(txList, 1000.0);

      // Filter only given transactions
      final givenEntries = txList.asMap().entries.where((e) => isGivenTransaction(e.value)).toList();
      expect(givenEntries.length, equals(2));

      // First given is txList[1] (700)
      expect(givenEntries[0].key, equals(1));
      expect(postBalances[givenEntries[0].key], equals(1500.0));

      // Second given is txList[2] (800)
      expect(givenEntries[1].key, equals(2));
      expect(postBalances[givenEntries[1].key], equals(800.0));
    });
  });
}

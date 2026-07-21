class TransactionModel {
  Message? message;

  TransactionModel({this.message});

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        message:
            json["message"] == null ? null : Message.fromJson(json["message"]),
      );
}

class Message {
  Transactions? transactions;

  Message({this.transactions});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    transactions:
        json["transactions"] == null
            ? null
            : Transactions.fromJson(json["transactions"]),
  );
}

class Transactions {
  List<Datum>? data;

  Transactions({this.data});

  factory Transactions.fromJson(Map<String, dynamic> json) => Transactions(
    data:
        json["data"] == null
            ? []
            : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
  );
}

class Datum {
  dynamic charge;
  dynamic remarks;
  dynamic transactionId;
  dynamic amount;
  dynamic currency;
  dynamic type;
  dynamic status;
  dynamic createdTime;

  Datum({
    this.charge,
    this.remarks,
    this.transactionId,
    this.amount,
    this.currency,
    this.type,
    this.status,
    this.createdTime,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    remarks: json["remarks"],
    transactionId: json["trx_id"],
    amount: json["amount"].toString(),
    charge: json["charge"].toString(),
    currency: json["currency"],
    type: json["trx_type"],
    status: json["status"],
    createdTime: json["created_at"].toString(),
  );
}

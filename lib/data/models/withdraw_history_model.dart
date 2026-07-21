class WithdrawHistoryModel {
  Message? message;

  WithdrawHistoryModel({
    this.message,
  });

  factory WithdrawHistoryModel.fromJson(Map<String, dynamic> json) =>
      WithdrawHistoryModel(
        message:
            json["message"] == null ? null : Message.fromJson(json["message"]),
      );
}

class Message {
  Payouts? payouts;

  Message({
    this.payouts,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        payouts:
            json["payouts"] == null ? null : Payouts.fromJson(json["payouts"]),
      );
}

class Payouts {
  List<Datum>? data;

  Payouts({
    this.data,
  });

  factory Payouts.fromJson(Map<String, dynamic> json) => Payouts(
        data: json["data"] == null
            ? []
            : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
      );
}

class Datum {
  dynamic amount;
  dynamic currency;
  dynamic transactionId;
  dynamic gateway;
  dynamic status;
  dynamic createdTime;

  Datum({
    this.amount,
    this.currency,
    this.transactionId,
    this.gateway,
    this.status,
    this.createdTime,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        amount: json["amount"],
        currency: json["currency"],
        transactionId: json["transactionId"],
        gateway: json["gateway"],
        status: json["status"],
        createdTime: json["createdTime"] == null
            ? null
            : DateTime.parse(json["createdTime"]),
      );
}

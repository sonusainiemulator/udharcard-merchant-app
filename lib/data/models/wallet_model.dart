class WalletModel {
  final Message? message;

  WalletModel({this.message});

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
    message: json["message"] == null ? null : Message.fromJson(json["message"]),
  );
}

class Message {
  final List<Wallet>? wallets;

  Message({this.wallets});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    wallets:
        json["wallets"] == null
            ? []
            : List<Wallet>.from(
              json["wallets"]!.map((x) => Wallet.fromJson(x)),
            ),
  );
}

class Wallet {
  final dynamic id;
  final dynamic totalBalance;
  final dynamic userId;
  final dynamic currencyId;
  final Currency? currency;

  Wallet({
    this.id,
    this.totalBalance,
    this.userId,
    this.currencyId,
    this.currency,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    id: json["id"],
    totalBalance: json["totalBalance"] ?? "0.00",
    userId: json["user_id"],
    currencyId: json["currency_id"],
    currency:
        json["currency"] == null ? null : Currency.fromJson(json["currency"]),
  );
}

class Currency {
  final dynamic id;
  final dynamic name;
  final dynamic code;
  final dynamic symbol;
  final dynamic image;

  Currency({this.id, this.name, this.code, this.symbol, this.image});

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
    id: json["id"],
    name: json["name"],
    code: json["code"],
    symbol: json["symbol"],
    image: json["imageUrl"],
  );
}

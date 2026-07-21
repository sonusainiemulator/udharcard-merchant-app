class DashboardModel {
  Message? message;

  DashboardModel({
    this.message,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
        message:
            json["message"] == null ? null : Message.fromJson(json["message"]),
      );
}

class Message {
  dynamic baseCurrency;
  dynamic baseCurrencySymbol;
  List<Wallet>? wallets;
  List<Recipient>? recipients;
  List<Currency>? currency;

  Message({
    this.baseCurrency,
    this.baseCurrencySymbol,
    this.wallets,
    this.recipients,
    this.currency,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        baseCurrency: json["baseCurrency"],
        baseCurrencySymbol: json["baseCurrencySymbol"],
        wallets: json["wallets"] == null
            ? []
            : List<Wallet>.from(
                json["wallets"]!.map((x) => Wallet.fromJson(x))),
        recipients: json["recipients"] == null
            ? []
            : List<Recipient>.from(
                json["recipients"]!.map((x) => Recipient.fromJson(x))),
        currency: json["currency"] == null
            ? []
            : List<Currency>.from(
                json["currency"]!.map((x) => Currency.fromJson(x))),
      );
}

class Currency {
  dynamic name;
  dynamic code;
  dynamic countryId;
  Country? country;

  Currency({
    this.name,
    this.code,
    this.countryId,
    this.country,
  });

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        name: json["name"],
        code: json["code"],
        countryId: json["country_id"],
        country:
            json["country"] == null ? null : Country.fromJson(json["country"]),
      );
}

class Country {
  dynamic id;
  dynamic name;
  dynamic image;
  dynamic imageDriver;

  Country({
    this.id,
    this.name,
    this.image,
    this.imageDriver,
  });

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        id: json["id"],
        name: json["name"],
        image: json["image"],
        imageDriver: json["image_driver"],
      );
}

class CurrencyRate {
  dynamic id;
  dynamic code;
  dynamic rate;

  CurrencyRate({
    this.id,
    this.code,
    this.rate,
  });

  factory CurrencyRate.fromJson(Map<String, dynamic> json) => CurrencyRate(
        id: json["id"],
        code: json["code"],
        rate: json["rate"],
      );
}

class Wallet {
  dynamic id;
  dynamic uuid;
  dynamic currencyCode;
  dynamic balance;
  dynamic status;
  dynamic walletDefault;
  CurrencyRate? currencyRate;

  Wallet({
    this.id,
    this.uuid,
    this.currencyCode,
    this.balance,
    this.status,
    this.walletDefault,
    this.currencyRate,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        id: json["id"],
        uuid: json["uuid"],
        currencyCode: json["currency_code"],
        balance: json["balance"],
        status: json["status"],
        walletDefault: json["default"],
        currencyRate: json["currency"] == null
            ? null
            : CurrencyRate.fromJson(json["currency"]),
      );
}

class Recipient {
  dynamic id;
  dynamic username;
  dynamic imgUrl;

  Recipient({
    this.id,
    this.username,
    this.imgUrl,
  });

  factory Recipient.fromJson(Map<String, dynamic> json) => Recipient(
        id: json["id"],
        username: json["username"],
        imgUrl: json["imgUrl"],
      );
}

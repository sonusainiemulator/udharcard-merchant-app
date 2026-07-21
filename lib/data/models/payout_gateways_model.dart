class PayoutModel {
  Message? message;

  PayoutModel({this.message});

  factory PayoutModel.fromJson(Map<String, dynamic> json) => PayoutModel(
        message:
            json["message"] == null ? null : Message.fromJson(json["message"]),
      );
}

class Message {
  List<Gateway>? gateways;

  Message({this.gateways});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        gateways: json["gateways"] == null
            ? []
            : List<Gateway>.from(
                json["gateways"]!.map((x) => Gateway.fromJson(x))),
      );
}

class Gateway {
  dynamic id;
  dynamic name;
  dynamic image;
  dynamic description;
  List<dynamic>? supportedCurrency;
  List<PayoutCurrency>? payoutCurrencies;
  dynamic isAutomatic;
  dynamic currencyType;

  Gateway({
    this.id,
    this.name,
    this.image,
    this.description,
    this.supportedCurrency,
    this.payoutCurrencies,
    this.isAutomatic,
    this.currencyType,
  });

  factory Gateway.fromJson(Map<String, dynamic> json) => Gateway(
        id: json["id"],
        name: json["name"],
        image: json["image"],
        description: json["description"],
        supportedCurrency: json["supported_currency"] == null
            ? []
            : List<String>.from(json["supported_currency"]!.map((x) => x)),
        payoutCurrencies: json["payout_currencies"] == null
            ? []
            : List<PayoutCurrency>.from(json["payout_currencies"]!
                .map((x) => PayoutCurrency.fromJson(x))),
        isAutomatic: json["isAutomatic"],
        currencyType: json["currency_type"],
      );
}

class PayoutCurrency {
  dynamic currencySymbol;
  dynamic conversionRate;
  dynamic minLimit;
  dynamic maxLimit;
  dynamic percentageCharge;
  dynamic fixedCharge;
  dynamic name;

  PayoutCurrency({
    this.currencySymbol,
    this.conversionRate,
    this.minLimit,
    this.maxLimit,
    this.percentageCharge,
    this.fixedCharge,
    this.name,
  });

  factory PayoutCurrency.fromJson(Map<String, dynamic> json) => PayoutCurrency(
        currencySymbol: json["currency_symbol"],
        conversionRate: json["conversion_rate"],
        minLimit: json["min_limit"],
        maxLimit: json["max_limit"],
        percentageCharge: json["percentage_charge"],
        fixedCharge: json["fixed_charge"],
        name: json["name"],
      );
}

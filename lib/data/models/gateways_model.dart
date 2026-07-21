

class GatewayModel {
    Message? message;

    GatewayModel({
        this.message,
    });

    factory GatewayModel.fromJson(Map<String, dynamic> json) => GatewayModel(
        message: json["message"] == null ? null : Message.fromJson(json["message"]),
    );

}

class Message {
    List<Currency>? currencies;
    List<Method>? methods;

    Message({
        this.currencies,
        this.methods,
    });

    factory Message.fromJson(Map<String, dynamic> json) => Message(
        currencies: json["currencies"] == null ? [] : List<Currency>.from(json["currencies"]!.map((x) => Currency.fromJson(x))),
        methods: json["methods"] == null ? [] : List<Method>.from(json["methods"]!.map((x) => Method.fromJson(x))),
    );

}

class Currency {
    dynamic id;
    dynamic code;
    dynamic name;
    dynamic isActive;

    Currency({
        this.id,
        this.code,
        this.name,
        this.isActive,
    });

    factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        id: json["id"],
        code: json["code"],
        name: json["name"],
        isActive: json["is_active"],
    );

}

class Method {
    dynamic id;
    dynamic code;
    dynamic name;
    dynamic sortBy;
    dynamic image;
    dynamic driver;
    dynamic status;
    List<dynamic>? supportedCurrency;
    List<ReceivableCurrency>? receivableCurrencies;
    dynamic description;
    dynamic currencyType;
    dynamic isSandbox;
    dynamic environment;
    dynamic isManual;
    dynamic note;
    dynamic createdAt;
    dynamic updatedAt;
    dynamic imagePath;

    Method({
        this.id,
        this.code,
        this.name,
        this.sortBy,
        this.image,
        this.driver,
        this.status,
        this.supportedCurrency,
        this.receivableCurrencies,
        this.description,
        this.currencyType,
        this.isSandbox,
        this.environment,
        this.isManual,
        this.note,
        this.createdAt,
        this.updatedAt,
        this.imagePath,
    });

    factory Method.fromJson(Map<String, dynamic> json) => Method(
        id: json["id"],
        code: json["code"],
        name: json["name"],
        sortBy: json["sort_by"],
        image: json["image"],
        driver: json["driver"],
        status: json["status"],
        supportedCurrency: json["supported_currency"] == null ? [] : List<String>.from(json["supported_currency"]!.map((x) => x)),
        receivableCurrencies: json["receivable_currencies"] == null ? [] : List<ReceivableCurrency>.from(json["receivable_currencies"]!.map((x) => ReceivableCurrency.fromJson(x))),
        description: json["description"],
        currencyType: json["currency_type"],
        isSandbox: json["is_sandbox"],
        environment: json["environment"],
        isManual: json["is_manual"],
        note: json["note"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        imagePath: json["imagePath"],
    );

 
}

class ReceivableCurrency {
    dynamic name;
    dynamic currencySymbol;
    dynamic currency;
    dynamic conversionRate;
    dynamic minLimit;
    dynamic maxLimit;
    dynamic percentageCharge;
    dynamic fixedCharge;

    ReceivableCurrency({
        this.name,
        this.currencySymbol,
        this.currency,
        this.conversionRate,
        this.minLimit,
        this.maxLimit,
        this.percentageCharge,
        this.fixedCharge,
    });

    factory ReceivableCurrency.fromJson(Map<String, dynamic> json) => ReceivableCurrency(
        name: json["name"],
        currencySymbol: json["currency_symbol"],
        currency: json["currency"],
        conversionRate: json["conversion_rate"],
        minLimit: json["min_limit"],
        maxLimit: json["max_limit"],
        percentageCharge: json["percentage_charge"],
        fixedCharge: json["fixed_charge"],
    );

}

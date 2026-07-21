class GetRedeemCodeModel {
  Message? message;

  GetRedeemCodeModel({
    this.message,
  });

  factory GetRedeemCodeModel.fromJson(Map<String, dynamic> json) =>
      GetRedeemCodeModel(
        message:
            json["message"] == null ? null : Message.fromJson(json["message"]),
      );
}

class Message {
  dynamic transactionTypeId;
  List<Currency>? currencies;
  Template? template;

  Message({
    this.transactionTypeId,
    this.currencies,
    this.template,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        transactionTypeId: json["transactionTypeId"],
        currencies: json["currencies"] == null
            ? []
            : List<Currency>.from(
                json["currencies"]!.map((x) => Currency.fromJson(x))),
        template: json["template"] == null
            ? null
            : Template.fromJson(json["template"]),
      );
}

class Currency {
  dynamic id;
  dynamic code;
  dynamic name;
  dynamic currencyType;

  Currency({
    this.id,
    this.code,
    this.name,
    this.currencyType,
  });

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        id: json["id"],
        code: json["code"],
        name: json["name"],
        currencyType: json["currency_type"],
      );
}

class Template {
  dynamic id;
  dynamic languageId;
  dynamic sectionName;
  Description? description;
  dynamic createdAt;
  dynamic updatedAt;

  Template({
    this.id,
    this.languageId,
    this.sectionName,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory Template.fromJson(Map<String, dynamic> json) => Template(
        id: json["id"],
        languageId: json["language_id"],
        sectionName: json["section_name"],
        description: json["description"] == null
            ? null
            : Description.fromJson(json["description"]),
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );
}

class Description {
  dynamic shortDescription;

  Description({
    this.shortDescription,
  });

  factory Description.fromJson(Map<String, dynamic> json) => Description(
        shortDescription: json["short_description"],
      );
}

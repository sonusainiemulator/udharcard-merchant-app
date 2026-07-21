class BankFromCurrencyModel {
  Message? message;

  BankFromCurrencyModel({this.message});

  BankFromCurrencyModel.fromJson(Map<String, dynamic> json) {
    message =
        json['message'] != null ? new Message.fromJson(json['message']) : null;
  }


}

class Message {
  List<Data>? data;

  Message({this.data});

  Message.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }


}

class Data {
  dynamic id;
  dynamic name;
  dynamic slug;
  dynamic code;
  dynamic longcode;
  dynamic gateway;
  dynamic payWithBank;
  dynamic supportsTransfer;
  dynamic active;
  dynamic country;
  dynamic currency;
  dynamic type;
  dynamic isDeleted;
  dynamic createdAt;
  dynamic updatedAt;

  Data(
      {this.id,
      this.name,
      this.slug,
      this.code,
      this.longcode,
      this.gateway,
      this.payWithBank,
      this.supportsTransfer,
      this.active,
      this.country,
      this.currency,
      this.type,
      this.isDeleted,
      this.createdAt,
      this.updatedAt});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    slug = json['slug'];
    code = json['code'];
    longcode = json['longcode'];
    gateway = json['gateway'];
    payWithBank = json['pay_with_bank'];
    supportsTransfer = json['supports_transfer'];
    active = json['active'];
    country = json['country'];
    currency = json['currency'];
    type = json['type'];
    isDeleted = json['is_deleted'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

}

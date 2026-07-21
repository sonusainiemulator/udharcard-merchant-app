class BankFromBankModel {
  Message? message;

  BankFromBankModel({this.message});

  BankFromBankModel.fromJson(Map<String, dynamic> json) {
    message =
        json['message'] != null ? new Message.fromJson(json['message']) : null;
  }

}

class Message {
  Bank? bank;

  Message({this.bank});

  Message.fromJson(Map<String, dynamic> json) {
    bank = json['bank'] != null ? new Bank.fromJson(json['bank']) : null;
  }

}

class Bank {
  List<Data>? data;

  Bank({this.data});

  Bank.fromJson(Map<String, dynamic> json) {
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
  dynamic code;
  dynamic name;

  Data({this.id, this.code, this.name});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id']?? "";
    code = json['code']?? "";
    name = json['name']?? "";
  }

}

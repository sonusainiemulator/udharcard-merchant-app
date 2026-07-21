class BasicCtrlModel {
  Message? message;

  BasicCtrlModel({ this.message});

  BasicCtrlModel.fromJson(Map<String, dynamic> json) {
    message =
        json['message'] != null ? new Message.fromJson(json['message']) : null;
  }


}

class Message {
  Service? service;

  Message({this.service});

  Message.fromJson(Map<String, dynamic> json) {
    service =
        json['service'] != null ? new Service.fromJson(json['service']) : null;
  }
}

class Service {
  dynamic transfer;
  dynamic request;
  dynamic exchange;
  dynamic redeem;
  dynamic escrow;
  dynamic voucher;
  dynamic deposit;
  dynamic payout;
  dynamic invoice;
  dynamic store;
  dynamic qrPayment;
  dynamic virtualCard;
  dynamic billPayment;
  dynamic cash_in;

  Service(
      {this.transfer,
      this.request,
      this.exchange,
      this.redeem,
      this.escrow,
      this.voucher,
      this.deposit,
      this.payout,
      this.invoice,
      this.store,
      this.qrPayment,
      this.virtualCard,
      this.cash_in,
      this.billPayment});

  Service.fromJson(Map<String, dynamic> json) {
    transfer = json['transfer'];
    request = json['request'];
    exchange = json['exchange'];
    redeem = json['redeem'];
    escrow = json['escrow'];
    voucher = json['voucher'];
    deposit = json['deposit'];
    payout = json['payout'];
    invoice = json['invoice'];
    store = json['store'];
    qrPayment = json['qr_payment'];
    cash_in = json['cash_in'];
    virtualCard = json['virtual_card'];
    billPayment = json['bill_payment'];
  }
}

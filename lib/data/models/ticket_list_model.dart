

class TicketListModel {
    Message? message;

    TicketListModel({
        this.message,
    });

    factory TicketListModel.fromJson(Map<String, dynamic> json) => TicketListModel(
        message: json["message"] == null ? null : Message.fromJson(json["message"]),
    );

}

class Message {
    List<Datum>? data;

    Message({
        this.data,
    });

    factory Message.fromJson(Map<String, dynamic> json) => Message(
        data: json["data"] == null ? [] : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
    );

}

class Datum {
    dynamic ticket;
    dynamic subject;
    dynamic status;
    dynamic lastReply;

    Datum({
        this.ticket,
        this.subject,
        this.status,
        this.lastReply,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        ticket: json["ticket"],
        subject: json["subject"],
        status: json["status"],
        lastReply: json["lastReply"],
    );


}



class TicketListModel {
    TicketListModelMessage? message;

    TicketListModel({
        this.message,
    });

    factory TicketListModel.fromJson(Map<String, dynamic> json) => TicketListModel(
        message: json["message"] == null ? null : TicketListModelMessage.fromJson(json["message"]),
    );
}

class TicketListModelMessage {
    dynamic id;
    dynamic pageTitle;
    dynamic userImage;
    dynamic userUsername;
    dynamic status;
    List<MessageElement>? messages;

    TicketListModelMessage({
        this.id,
        this.pageTitle,
        this.userImage,
        this.userUsername,
        this.status,
        this.messages,
    });

    factory TicketListModelMessage.fromJson(Map<String, dynamic> json) => TicketListModelMessage(
        id: json["id"],
        pageTitle: json["page_title"],
        userImage: json["userImage"],
        userUsername: json["userUsername"],
        status: json["status"],
        messages: json["messages"] == null ? [] : List<MessageElement>.from(json["messages"]!.map((x) => MessageElement.fromJson(x))),
    );

}

class MessageElement {
    dynamic id;
    dynamic ticketId;
    dynamic adminId;
    dynamic message;
    dynamic createdAt;
    dynamic updatedAt;
    dynamic adminImage;
    List<Attachment>? attachments;

    MessageElement({
        this.id,
        this.ticketId,
        this.adminId,
        this.message,
        this.createdAt,
        this.updatedAt,
        this.adminImage,
        this.attachments,
    });

    factory MessageElement.fromJson(Map<String, dynamic> json) => MessageElement(
        id: json["id"],
        ticketId: json["ticket_id"],
        adminId: json["admin_id"],
        message: json["message"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        adminImage: json["adminImage"],
        attachments: json["attachments"] == null ? [] : List<Attachment>.from(json["attachments"]!.map((x) => Attachment.fromJson(x))),
    );


}

class Attachment {
    dynamic id;
    dynamic ticketMessageId;
    dynamic image;
    DateTime? createdAt;
    DateTime? updatedAt;
    dynamic attachmentPath;
    dynamic attachmentName;

    Attachment({
        this.id,
        this.ticketMessageId,
        this.image,
        this.createdAt,
        this.updatedAt,
        this.attachmentPath,
        this.attachmentName,
    });

    factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: json["id"],
        ticketMessageId: json["ticket_message_id"],
        image: json["image"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        attachmentPath: json["attachment_path"],
        attachmentName: json["attachment_name"],
    );
}

const Object _workListUnset = Object();

class WorkListItem {
  static const String statusPending = 'pending';
  static const String statusCompleted = 'completed';

  final String id;
  final String title;
  final String note;
  final DateTime dueDate;
  final String status;
  final String priority;
  final String? customerId;
  final String? customerName;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkListItem({
    required this.id,
    required this.title,
    required this.note,
    required this.dueDate,
    required this.status,
    required this.priority,
    required this.customerId,
    required this.customerName,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == statusCompleted;

  WorkListItem copyWith({
    String? id,
    String? title,
    String? note,
    DateTime? dueDate,
    String? status,
    String? priority,
    Object? customerId = _workListUnset,
    Object? customerName = _workListUnset,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkListItem(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      customerId: identical(customerId, _workListUnset)
          ? this.customerId
          : customerId as String?,
      customerName: identical(customerName, _workListUnset)
          ? this.customerName
          : customerName as String?,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'priority': priority,
      'customer_id': customerId,
      'customer_name': customerName,
      'is_synced': isSynced,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WorkListItem.fromJson(Map<String, dynamic> json) {
    return WorkListItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      dueDate:
          DateTime.tryParse((json['due_date'] ?? '').toString()) ?? DateTime.now(),
      status: (json['status'] ?? statusPending).toString(),
      priority: (json['priority'] ?? 'medium').toString(),
      customerId: json['customer_id']?.toString(),
      customerName: json['customer_name']?.toString(),
      isSynced: json['is_synced'] == true,
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse((json['updated_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
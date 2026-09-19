enum FeeStatus { paid, partiallyPaid, pending, overdue }

class FeeModel {
  final String id;
  final String studentId;
  final double totalAmount;
  final double paidAmount;
  final DateTime dueDate;
  final FeeStatus status;
  final String description; // e.g. "Fall 2026 Hostel Fee"

  FeeModel({
    required this.id,
    required this.studentId,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.dueDate,
    required this.status,
    required this.description,
  });

  double get remainingAmount => totalAmount - paidAmount;

  factory FeeModel.fromJson(Map<String, dynamic> json) {
    return FeeModel(
      id: json['id'],
      studentId: json['studentId'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate']),
      status: FeeStatus.values.firstWhere((e) => e.name == json['status']),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'description': description,
    };
  }
}

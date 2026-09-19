enum LeaveStatus { pending, approved, rejected }

class LeaveRequestModel {
  final String id;
  final String studentId;
  final String leaveType;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final String destinationContact;
  final LeaveStatus status;
  final String? adminRemarks;
  final DateTime submittedAt;

  LeaveRequestModel({
    required this.id,
    required this.studentId,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.destinationContact,
    this.status = LeaveStatus.pending,
    this.adminRemarks,
    required this.submittedAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'],
      studentId: json['studentId'],
      leaveType: json['leaveType'],
      fromDate: DateTime.parse(json['fromDate']),
      toDate: DateTime.parse(json['toDate']),
      reason: json['reason'],
      destinationContact: json['destinationContact'],
      status: LeaveStatus.values.firstWhere((e) => e.name == json['status']),
      adminRemarks: json['adminRemarks'],
      submittedAt: DateTime.parse(json['submittedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'leaveType': leaveType,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'reason': reason,
      'destinationContact': destinationContact,
      'status': status.name,
      'adminRemarks': adminRemarks,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }
}

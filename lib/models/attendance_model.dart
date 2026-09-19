enum AttendanceStatus { present, absent, onLeave }

class AttendanceModel {
  final String id;
  final String studentId;
  final DateTime date;
  final AttendanceStatus status;
  final String markedByAdminId; // ID of the admin who marked it

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
    required this.markedByAdminId,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      studentId: json['studentId'],
      date: DateTime.parse(json['date']),
      status: AttendanceStatus.values.firstWhere((e) => e.name == json['status']),
      markedByAdminId: json['markedByAdminId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'date': date.toIso8601String(),
      'status': status.name,
      'markedByAdminId': markedByAdminId,
    };
  }
}

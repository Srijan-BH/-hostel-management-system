enum ComplaintStatus { submitted, inProgress, resolved, rejected }
enum ComplaintPriority { low, medium, high }

class ComplaintModel {
  final String id;
  final String studentId;
  final String category; // e.g. Room Maintenance, Electricity, Food
  final String description;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final String? adminRemarks;
  final DateTime submittedAt;
  final String? imageUrl;

  ComplaintModel({
    required this.id,
    required this.studentId,
    required this.category,
    required this.description,
    this.status = ComplaintStatus.submitted,
    this.priority = ComplaintPriority.medium,
    this.adminRemarks,
    required this.submittedAt,
    this.imageUrl,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'],
      studentId: json['studentId'],
      category: json['category'],
      description: json['description'],
      status: ComplaintStatus.values.firstWhere((e) => e.name == json['status']),
      priority: ComplaintPriority.values.firstWhere((e) => e.name == json['priority']),
      adminRemarks: json['adminRemarks'],
      submittedAt: DateTime.parse(json['submittedAt']),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'category': category,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'adminRemarks': adminRemarks,
      'submittedAt': submittedAt.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }
}

enum ServiceRequestStatus { requested, assigned, inProgress, completed }

class ServiceRequestModel {
  final String id;
  final String studentId;
  final String serviceType; // e.g. Room Cleaning, Plumbing, Electrical
  final String description;
  final ServiceRequestStatus status;
  final String? assignedTo;
  final DateTime requestedAt;

  ServiceRequestModel({
    required this.id,
    required this.studentId,
    required this.serviceType,
    required this.description,
    this.status = ServiceRequestStatus.requested,
    this.assignedTo,
    required this.requestedAt,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id: json['id'],
      studentId: json['studentId'],
      serviceType: json['serviceType'],
      description: json['description'],
      status: ServiceRequestStatus.values.firstWhere((e) => e.name == json['status']),
      assignedTo: json['assignedTo'],
      requestedAt: DateTime.parse(json['requestedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'serviceType': serviceType,
      'description': description,
      'status': status.name,
      'assignedTo': assignedTo,
      'requestedAt': requestedAt.toIso8601String(),
    };
  }
}

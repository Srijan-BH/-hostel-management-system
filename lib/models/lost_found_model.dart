enum LostFoundType { lost, found }
enum LostFoundStatus { open, resolved, removed }

class LostFoundModel {
  final String id;
  final String reportedByUserId; // Student who reported
  final LostFoundType type;
  final String itemName;
  final String description;
  final String location;
  final DateTime dateReported;
  final String contactInformation;
  final LostFoundStatus status;

  LostFoundModel({
    required this.id,
    required this.reportedByUserId,
    required this.type,
    required this.itemName,
    required this.description,
    required this.location,
    required this.dateReported,
    required this.contactInformation,
    this.status = LostFoundStatus.open,
  });

  factory LostFoundModel.fromJson(Map<String, dynamic> json) {
    return LostFoundModel(
      id: json['id'],
      reportedByUserId: json['reportedByUserId'],
      type: LostFoundType.values.firstWhere((e) => e.name == json['type']),
      itemName: json['itemName'],
      description: json['description'],
      location: json['location'],
      dateReported: DateTime.parse(json['dateReported']),
      contactInformation: json['contactInformation'],
      status: LostFoundStatus.values.firstWhere((e) => e.name == json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportedByUserId': reportedByUserId,
      'type': type.name,
      'itemName': itemName,
      'description': description,
      'location': location,
      'dateReported': dateReported.toIso8601String(),
      'contactInformation': contactInformation,
      'status': status.name,
    };
  }
}

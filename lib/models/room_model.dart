class RoomModel {
  final String id;
  final String roomNumber;
  final String hostelBlock;
  final int capacity;
  final List<String> occupantStudentIds;
  final List<String> facilities;
  final String status; // e.g., Available, Full, Maintenance

  RoomModel({
    required this.id,
    required this.roomNumber,
    required this.hostelBlock,
    required this.capacity,
    required this.occupantStudentIds,
    required this.facilities,
    required this.status,
  });

  bool get isFull => occupantStudentIds.length >= capacity;
  int get availableBeds => capacity - occupantStudentIds.length;

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'],
      roomNumber: json['roomNumber'],
      hostelBlock: json['hostelBlock'],
      capacity: json['capacity'],
      occupantStudentIds: List<String>.from(json['occupantStudentIds']),
      facilities: List<String>.from(json['facilities']),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      'hostelBlock': hostelBlock,
      'capacity': capacity,
      'occupantStudentIds': occupantStudentIds,
      'facilities': facilities,
      'status': status,
    };
  }
}

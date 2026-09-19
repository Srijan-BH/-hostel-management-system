import 'package:hostel_management_system/models/user_model.dart';

class StudentModel extends UserModel {
  final String phoneNumber;
  final String course;
  final String yearSemester;
  final String? roomNumber;
  final String? bedNumber;
  final String? hostelBlock;
  final DateTime joiningDate;
  final String guardianName;
  final String guardianContact;
  final String? profilePhotoUrl;

  StudentModel({
    required super.id,
    required super.email,
    required super.name,
    super.role = UserRole.student,
    required this.phoneNumber,
    required this.course,
    required this.yearSemester,
    this.roomNumber,
    this.bedNumber,
    this.hostelBlock,
    required this.joiningDate,
    required this.guardianName,
    required this.guardianContact,
    this.profilePhotoUrl,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      course: json['course'],
      yearSemester: json['yearSemester'],
      roomNumber: json['roomNumber'],
      bedNumber: json['bedNumber'],
      hostelBlock: json['hostelBlock'],
      joiningDate: DateTime.parse(json['joiningDate']),
      guardianName: json['guardianName'],
      guardianContact: json['guardianContact'],
      profilePhotoUrl: json['profilePhotoUrl'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({
      'phoneNumber': phoneNumber,
      'course': course,
      'yearSemester': yearSemester,
      'roomNumber': roomNumber,
      'bedNumber': bedNumber,
      'hostelBlock': hostelBlock,
      'joiningDate': joiningDate.toIso8601String(),
      'guardianName': guardianName,
      'guardianContact': guardianContact,
      'profilePhotoUrl': profilePhotoUrl,
    });
    return map;
  }
}

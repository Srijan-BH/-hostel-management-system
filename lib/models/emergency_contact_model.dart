class EmergencyContactModel {
  final String id;
  final String roleName; // e.g. "Warden", "Security"
  final String personName;
  final String phoneNumber;
  final String? email;

  EmergencyContactModel({
    required this.id,
    required this.roleName,
    required this.personName,
    required this.phoneNumber,
    this.email,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'],
      roleName: json['roleName'],
      personName: json['personName'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roleName': roleName,
      'personName': personName,
      'phoneNumber': phoneNumber,
      'email': email,
    };
  }
}

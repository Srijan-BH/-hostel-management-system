class StaffModel {
  final String id;
  final String name;
  final String role; // e.g., 'Security Guard', 'Cleaner', 'Cook', 'Manager'
  final String phone;
  final String shift; // e.g., 'Morning', 'Night', 'Full Day'
  final double salary;
  final DateTime joinedDate;

  StaffModel({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.shift,
    required this.salary,
    required this.joinedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'phone': phone,
      'shift': shift,
      'salary': salary,
      'joinedDate': joinedDate.toIso8601String(),
    };
  }

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unknown',
      role: json['role'] as String? ?? 'Unknown',
      phone: json['phone'] as String? ?? '',
      shift: json['shift'] as String? ?? 'Unknown',
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      joinedDate: json['joinedDate'] != null 
          ? DateTime.parse(json['joinedDate']) 
          : DateTime.now(),
    );
  }
}

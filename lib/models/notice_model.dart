enum NoticePriority { low, medium, high }

class NoticeModel {
  final String id;
  final String title;
  final String description;
  final NoticePriority priority;
  final DateTime date;
  final DateTime expiryDate;
  final String postedByAdminId;

  NoticeModel({
    required this.id,
    required this.title,
    required this.description,
    this.priority = NoticePriority.medium,
    required this.date,
    required this.expiryDate,
    required this.postedByAdminId,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    return NoticeModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: NoticePriority.values.firstWhere((e) => e.name == json['priority']),
      date: DateTime.parse(json['date']),
      expiryDate: DateTime.parse(json['expiryDate']),
      postedByAdminId: json['postedByAdminId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.name,
      'date': date.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'postedByAdminId': postedByAdminId,
    };
  }
}

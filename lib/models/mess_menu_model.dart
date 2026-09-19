class MessMenuModel {
  final String id;
  final String dayOfWeek; // e.g. Monday, Tuesday
  final String breakfast;
  final String lunch;
  final String snacks;
  final String dinner;

  MessMenuModel({
    required this.id,
    required this.dayOfWeek,
    required this.breakfast,
    required this.lunch,
    required this.snacks,
    required this.dinner,
  });

  factory MessMenuModel.fromJson(Map<String, dynamic> json) {
    return MessMenuModel(
      id: json['id'],
      dayOfWeek: json['dayOfWeek'],
      breakfast: json['breakfast'],
      lunch: json['lunch'],
      snacks: json['snacks'],
      dinner: json['dinner'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek,
      'breakfast': breakfast,
      'lunch': lunch,
      'snacks': snacks,
      'dinner': dinner,
    };
  }
}

class MessFeedbackModel {
  final String id;
  final String studentId;
  final String mealType; // Breakfast, Lunch, Snacks, Dinner
  final double rating; // 1 to 5
  final String comments;
  final DateTime submittedAt;

  MessFeedbackModel({
    required this.id,
    required this.studentId,
    required this.mealType,
    required this.rating,
    required this.comments,
    required this.submittedAt,
  });

  factory MessFeedbackModel.fromJson(Map<String, dynamic> json) {
    return MessFeedbackModel(
      id: json['id'],
      studentId: json['studentId'],
      mealType: json['mealType'],
      rating: (json['rating'] as num).toDouble(),
      comments: json['comments'],
      submittedAt: DateTime.parse(json['submittedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'mealType': mealType,
      'rating': rating,
      'comments': comments,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }
}

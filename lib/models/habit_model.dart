class Habit {
  final String id;
  final String? userId;
  final String title;
  final String reminderTime;
  final DateTime? createdAt;

  Habit({
    required this.id,
    this.userId,
    required this.title,
    required this.reminderTime,
    this.createdAt,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      title: json['title'] as String,
      reminderTime: json['reminder_time'] != null
          ? (json['reminder_time'] as String).substring(0, 5)
          : '07:00',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'title': title,
      'reminder_time': reminderTime,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Habit copyWith({
    String? id,
    String? userId,
    String? title,
    String? reminderTime,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
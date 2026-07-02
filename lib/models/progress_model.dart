class ProgressModel {
  final int? id;
  final String habitId;
  final DateTime date; // Menggunakan DateTime agar mudah dimanipulasi dengan komponen Kalender
  final bool isCompleted;

  ProgressModel({
    this.id,
    required this.habitId,
    required this.date,
    required this.isCompleted,
  });

  // 1. Mengubah data JSON dari database Supabase menjadi Objek ProgressModel di Flutter
  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      id: json['id'] as int?,
      habitId: json['habit_id'] as String,
      // Membaca format string DATE (YYYY-MM-DD) dari PostgreSQL menjadi objek DateTime
      date: DateTime.parse(json['date'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  // 2. Mengubah Objek ProgressModel menjadi JSON format DATE (YYYY-MM-DD) sebelum dikirim ke Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'habit_id': habitId,
      // Memastikan format yang dikirim ke kolom DATE Supabase hanya "YYYY-MM-DD" tanpa komponen waktu jam
      'date': "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'is_completed': isCompleted,
    };
  }

  // 3. Helper Method: Kloning objek untuk mengubah status centang (is_completed) secara instan di UI
  ProgressModel copyWith({
    int? id,
    String? habitId,
    DateTime? date,
    bool? isCompleted,
  }) {
    return ProgressModel(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
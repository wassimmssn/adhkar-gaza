class DayCompletion {
  final String dateKey; // Format 'YYYY-MM-DD'
  bool morning;
  bool evening;
  List<String> prayers;
  int totalDhikrCount;

  DayCompletion({
    required this.dateKey,
    this.morning = false,
    this.evening = false,
    List<String>? prayers,
    this.totalDhikrCount = 0,
  }) : prayers = prayers ?? [];

  bool get hasAnyActivity => morning || evening || prayers.isNotEmpty;

  int get totalCompletedItems {
    int count = 0;
    if (morning) count++;
    if (evening) count++;
    count += prayers.length;
    return count;
  }

  // Max 7 possible: Morning + Evening + 5 Prayers
  double get completionRatio {
    const maxItems = 7;
    return (totalCompletedItems / maxItems).clamp(0.0, 1.0);
  }

  bool get isPerfectDay => morning && evening && prayers.length >= 5;

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'morning': morning,
      'evening': evening,
      'prayers': prayers,
      'totalDhikrCount': totalDhikrCount,
    };
  }

  factory DayCompletion.fromJson(Map<String, dynamic> json) {
    return DayCompletion(
      dateKey: json['dateKey'] ?? '',
      morning: json['morning'] ?? false,
      evening: json['evening'] ?? false,
      prayers: (json['prayers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      totalDhikrCount: json['totalDhikrCount'] ?? 0,
    );
  }
}

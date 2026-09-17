class Dhikr {
  final String category;
  final int count;
  final String text;
  final String reference;
  final String bienfaits;
  final bool isPriority;

  const Dhikr({
    required this.category,
    required this.count,
    required this.text,
    required this.reference,
    this.bienfaits = '',
    this.isPriority = false,
  });

  factory Dhikr.fromJson(Map<String, dynamic> json) {
    return Dhikr(
      category: json['category'] as String,
      count: json['count'] as int,
      text: json['text'] as String,
      reference: json['reference'] as String,
      bienfaits: (json['bienfaits'] as String?) ?? '',
      isPriority: (json['isPriority'] as bool?) ?? false,
    );
  }
}

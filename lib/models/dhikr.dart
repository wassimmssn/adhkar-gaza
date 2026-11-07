class Dhikr {
  final String category;
  final int count;
  final String text;
  final String reference;
  final String bienfaits;
  final bool isPriority;
  final String phonetic;
  final String translation;
  final String? audioUrl;

  const Dhikr({
    required this.category,
    required this.count,
    required this.text,
    required this.reference,
    this.bienfaits = '',
    this.isPriority = false,
    this.phonetic = '',
    this.translation = '',
    this.audioUrl,
  });

  factory Dhikr.fromJson(Map<String, dynamic> json) {
    return Dhikr(
      category: json['category'] as String,
      count: json['count'] as int,
      text: json['text'] as String,
      reference: json['reference'] as String,
      bienfaits: (json['bienfaits'] as String?) ?? '',
      isPriority: (json['isPriority'] as bool?) ?? false,
      phonetic: (json['phonetic'] as String?) ?? '',
      translation: (json['translation'] as String?) ?? '',
      audioUrl: json['audioUrl'] as String?,
    );
  }
}

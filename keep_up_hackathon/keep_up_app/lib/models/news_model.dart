class NewsCard {
  final String id;
  final String topic;
  final String contentLine;
  final List<String> keywords;

  NewsCard({
    required this.id,
    required this.topic,
    required this.contentLine,
    required this.keywords,
  });

  // This factory converts the JSON from your Java Backend into a Dart Object
  factory NewsCard.fromJson(Map<String, dynamic> json) {
    return NewsCard(
      id: json['id'] ?? '',
      topic: json['topic'] ?? 'General',
      contentLine: json['contentLine'] ?? '',
      // handle the list safely
      keywords: List<String>.from(json['keywords'] ?? []),
    );
  }
}

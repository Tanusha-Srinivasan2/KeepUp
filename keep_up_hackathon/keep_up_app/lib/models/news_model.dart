class NewsCard {
  final String id;
  final String title; // New field
  final String description; // New field
  final String imageUrl; // New field
  final String time; // New field
  final String topic;
  final List<String> keywords;

  NewsCard({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.time,
    required this.topic,
    required this.keywords,
  });

  // Factory to convert JSON from Java Backend -> Flutter Object
  factory NewsCard.fromJson(Map<String, dynamic> json) {
    return NewsCard(
      id: json['id'] ?? '',
      // Map 'title' from JSON. Fallback to 'News' if missing.
      title: json['title'] ?? 'News Update',
      // Map 'description'. If null, try 'contentLine' (backward compatibility).
      description:
          json['description'] ?? json['contentLine'] ?? 'No details available.',
      // Map 'imageUrl'. Provide a default placeholder if missing.
      imageUrl:
          json['imageUrl'] ??
          'https://images.unsplash.com/photo-1504711434969-e33886168f5c',
      time: json['time'] ?? 'Just now',
      topic: json['topic'] ?? 'General',
      keywords: List<String>.from(json['keywords'] ?? []),
    );
  }
}

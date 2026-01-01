class NewsCard {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String time;
  final String topic;
  final List<String> keywords;

  // ✅ NEW FIELD: To store the date stamp (e.g. "2026-01-01")
  final String publishedDate;

  NewsCard({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.time,
    required this.topic,
    required this.keywords,
    this.publishedDate = '', // Default empty if missing
  });

  factory NewsCard.fromJson(Map<String, dynamic> json) {
    return NewsCard(
      id: json['id'] ?? '',
      title: json['title'] ?? 'News Update',
      // Fallback for description logic
      description:
          json['description'] ?? json['contentLine'] ?? 'No details available.',
      imageUrl:
          json['imageUrl'] ??
          'https://images.unsplash.com/photo-1504711434969-e33886168f5c',
      time: json['time'] ?? 'Just now',
      topic: json['topic'] ?? 'General',
      keywords: List<String>.from(json['keywords'] ?? []),

      // ✅ PARSE DATE
      publishedDate: json['publishedDate'] ?? '',
    );
  }
}

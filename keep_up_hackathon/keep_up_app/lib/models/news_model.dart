class NewsCard {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String time;
  final String topic;
  final List<String> keywords;
  final String publishedDate;
  final String sourceUrl; // ✅ NEW FIELD

  NewsCard({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.time,
    required this.topic,
    required this.keywords,
    this.publishedDate = '',
    this.sourceUrl = '', // Default empty
  });

  factory NewsCard.fromJson(Map<String, dynamic> json) {
    return NewsCard(
      id: json['id'] ?? '',
      title: json['title'] ?? 'News Update',
      description: json['description'] ?? 'No details available.',
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/400',
      time: json['time'] ?? 'Just now',
      topic: json['topic'] ?? 'General',
      keywords: List<String>.from(json['keywords'] ?? []),
      publishedDate: json['publishedDate'] ?? '',

      // ✅ Parse URL or fallback to Google Search
      sourceUrl:
          json['sourceUrl'] ??
          'https://google.com/search?q=${Uri.encodeComponent(json['title'] ?? "")}',
    );
  }
}

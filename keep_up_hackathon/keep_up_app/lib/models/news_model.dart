class NewsCard {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String time;
  final String topic;
  final List<String> keywords;
  final String publishedDate;
  final String sourceUrl;

  NewsCard({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.time,
    required this.topic,
    required this.keywords,
    this.publishedDate = '',
    this.sourceUrl = '',
  });

  factory NewsCard.fromJson(Map<String, dynamic> json) {
    // 1. Get the raw title for fallback
    String title = json['title'] ?? 'News Update';

    // 2. Create a safe fallback URL (Google Search)
    String fallbackUrl =
        'https://google.com/search?q=${Uri.encodeComponent(title)}';

    // 3. Validate the incoming URL
    String rawUrl = json['sourceUrl'] ?? '';
    String finalUrl = fallbackUrl;

    if (rawUrl.isNotEmpty && rawUrl.startsWith('http')) {
      // 🚨 SAFETY CHECK: If it's a broken internal Google link, USE FALLBACK
      if (rawUrl.contains('grounding-api') ||
          rawUrl.contains('google.com/url')) {
        finalUrl = fallbackUrl;
      } else {
        finalUrl = rawUrl; // It's a real link (cnn.com, etc.)
      }
    }

    return NewsCard(
      id: json['id'] ?? '',
      title: title,
      description: json['description'] ?? 'No details available.',
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/400',
      time: json['time'] ?? 'Just now',
      topic: json['topic'] ?? 'General',
      keywords: List<String>.from(json['keywords'] ?? []),
      publishedDate: json['publishedDate'] ?? '',
      sourceUrl: finalUrl, // ✅ Always safe
    );
  }
}

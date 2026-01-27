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
  final String
  sourceName; // 📰 Publisher name for display (e.g., "Reuters", "BBC")
  final String disclaimer; // 🏥 Medical/informational disclaimer

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
    this.sourceName = '',
    this.disclaimer =
        'This is for informational purposes only. Consult a healthcare professional for medical advice.',
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

    // 4. 📰 Extract source name for attribution display
    String sourceName = json['sourceName'] ?? '';
    if (sourceName.isEmpty && finalUrl.isNotEmpty) {
      // Try to extract publisher name from URL if not provided
      try {
        Uri uri = Uri.parse(finalUrl);
        String host = uri.host.replaceAll('www.', '');
        // Clean up common domain patterns
        if (host.contains('.')) {
          sourceName = host.split('.').first;
          // Capitalize first letter
          sourceName = sourceName[0].toUpperCase() + sourceName.substring(1);
        }
      } catch (e) {
        sourceName = 'News Source';
      }
    }

    // 5. 🏥 Get disclaimer (with default fallback)
    String disclaimer =
        json['disclaimer'] ??
        'This is for informational purposes only. Consult a healthcare professional for medical advice.';

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
      sourceName: sourceName, // ✅ Publisher name for display
      disclaimer: disclaimer, // 🏥 Medical disclaimer
    );
  }
}

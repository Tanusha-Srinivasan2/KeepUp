class CatchUpItem {
  final String topic;
  final String headline;
  final String summary;
  final String date;
  final String sourceUrl; // 📰 New: Link to original article
  final String sourceName; // 📰 New: Publisher name for display

  CatchUpItem({
    required this.topic,
    required this.headline,
    required this.summary,
    required this.date,
    this.sourceUrl = '',
    this.sourceName = '',
  });

  factory CatchUpItem.fromJson(Map<String, dynamic> json) {
    // 1. Topic & Headline Parsing
    String fullTitle = json['title'] ?? json['headline'] ?? 'News Update';
    String topic = 'News';
    String headline = fullTitle;

    if (fullTitle.contains(':')) {
      final parts = fullTitle.split(':');
      topic = parts[0].trim();
      headline = parts.sublist(1).join(':').trim();
    } else if (json['topic'] != null) {
      topic = json['topic'];
    }

    // 2. Date Formatting
    String rawTime = json['time'] ?? json['timeAgo'] ?? '';
    String formattedDate = "{Dec 21}";
    if (rawTime.contains('d ago')) {
      int days = int.tryParse(rawTime.split(' ')[0]) ?? 0;
      final date = DateTime.now().subtract(Duration(days: days));
      final month = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][date.month];
      formattedDate = "{$month ${date.day}}";
    }

    // 3. 📰 Source Attribution
    String sourceUrl = json['sourceUrl'] ?? '';
    String sourceName = json['sourceName'] ?? '';

    // Try to extract source name from URL if not provided
    if (sourceName.isEmpty && sourceUrl.isNotEmpty) {
      try {
        Uri uri = Uri.parse(sourceUrl);
        String host = uri.host.replaceAll('www.', '');
        if (host.contains('.')) {
          sourceName = host.split('.').first;
          sourceName = sourceName[0].toUpperCase() + sourceName.substring(1);
        }
      } catch (e) {
        sourceName = 'News Source';
      }
    }

    return CatchUpItem(
      topic: topic,
      headline: headline,
      summary:
          json['description'] ?? json['summary'] ?? 'No details available.',
      date: formattedDate,
      sourceUrl: sourceUrl,
      sourceName: sourceName,
    );
  }
}

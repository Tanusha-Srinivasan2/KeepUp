class CatchUpItem {
  final String topic;
  final String headline;
  final String summary;
  final String date;

  CatchUpItem({
    required this.topic,
    required this.headline,
    required this.summary,
    required this.date,
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

    return CatchUpItem(
      topic: topic,
      headline: headline,
      summary:
          json['description'] ?? json['summary'] ?? 'No details available.',
      date: formattedDate,
    );
  }
}

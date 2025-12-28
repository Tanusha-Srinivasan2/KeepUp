class CatchUpItem {
  final String headline;
  final String summary;
  final String timeAgo;

  CatchUpItem({
    required this.headline,
    required this.summary,
    required this.timeAgo,
  });

  factory CatchUpItem.fromJson(Map<String, dynamic> json) {
    return CatchUpItem(
      headline: json['headline'] ?? "News Update",
      summary: json['summary'] ?? "No summary available.",
      timeAgo: json['timeAgo'] ?? "Recent",
    );
  }
}

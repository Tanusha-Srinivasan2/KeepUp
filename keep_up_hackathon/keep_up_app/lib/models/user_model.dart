class UserStats {
  final String id;
  final String name;
  final int xp;
  final int streak; // ✅ NEW: Added Streak field

  UserStats({
    required this.id,
    required this.name,
    required this.xp,
    required this.streak,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      // Ensure ID is a String for reliable 'isMe' comparison
      id:
          json['userId']?.toString() ??
          '', // Make sure your Backend sends "id" in the map!

      name: json['name'] ?? 'Unknown',

      // Safely handle XP whether it comes as an int or a String
      xp: json['xp'] is int
          ? json['xp']
          : int.tryParse(json['xp']?.toString() ?? '0') ?? 0,

      // ✅ NEW: Safely handle Streak
      streak: json['streak'] is int
          ? json['streak']
          : int.tryParse(json['streak']?.toString() ?? '0') ?? 0,
    );
  }
}

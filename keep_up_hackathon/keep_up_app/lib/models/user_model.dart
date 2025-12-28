class UserStats {
  final String id;
  final String name;
  final int xp;

  UserStats({required this.id, required this.name, required this.xp});

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      // Ensure ID is a String for reliable 'isMe' comparison
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      // Safely handle XP whether it comes as an int or a String
      xp: json['xp'] is int
          ? json['xp']
          : int.tryParse(json['xp']?.toString() ?? '0') ?? 0,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../main.dart'; // For KeepUpApp colors

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> leaderboardData = [];
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('user_id');

    try {
      final url = Uri.parse(
        'https://amalia-trancelike-beulah.ngrok-free.dev/api/news/leaderboard',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            leaderboardData = json.decode(response.body);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching leaderboard: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFCE0), // Cream background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Leader Board",
          style: GoogleFonts.poppins(
            color: const Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildLeagueHeader(),

          const SizedBox(height: 15),

          // LIST SECTION
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  )
                : Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      // ✅ UPDATED: Matches Cream Background
                      color: Color(0xFFFEFCE0),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(40),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(40),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 24,
                        ),
                        itemCount: leaderboardData.length,
                        // ✅ UPDATED: Divider between every user
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.grey.withOpacity(0.3),
                          thickness: 1,
                          height: 24, // Adds spacing around the line
                        ),
                        itemBuilder: (context, index) {
                          final user = leaderboardData[index];
                          return _buildUserRow(user, index + 1);
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueHeader() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Opacity(
              opacity: 0.6,
              child: Image.asset('assets/diamond1.png', width: 35),
            ),
            const SizedBox(width: 15),
            Transform.translate(
              offset: const Offset(0, -8),
              child: Image.asset('assets/diamond2.png', width: 80),
            ),
            const SizedBox(width: 15),
            Opacity(
              opacity: 0.6,
              child: Image.asset('assets/diamond3.png', width: 35),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          "Ruby League",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Next Tournament in 5 hrs",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user, int rank) {
    bool isMe = user['userId'] == currentUserId;
    String name = isMe ? "You" : (user['name'] ?? "Unknown");
    int xp = user['xp'] ?? 0;

    // AESTHETIC HIGHLIGHT
    // ✅ "You" gets a slightly darker cream/yellow tint to stand out subtly
    Color bgColor = isMe ? const Color(0xFFFFF9C4) : Colors.transparent;
    Color nameColor = isMe ? Colors.orange[800]! : const Color(0xFF2D2D2D);
    FontWeight fontWeight = isMe ? FontWeight.bold : FontWeight.w600;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          // 1. RANK
          SizedBox(width: 40, child: Center(child: _buildRankDisplay(rank))),

          const SizedBox(width: 15),

          // 2. NAME
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: fontWeight,
                color: nameColor,
              ),
            ),
          ),

          // 3. XP SCORE
          Text(
            "$xp XP",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.orange[900] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankDisplay(int rank) {
    if (rank == 1) {
      return const Icon(
        Icons.emoji_events_rounded,
        color: Color(0xFFFFD700),
        size: 28,
      ); // Gold
    } else if (rank == 2) {
      return const Icon(
        Icons.emoji_events_rounded,
        color: Color(0xFFC0C0C0),
        size: 28,
      ); // Silver
    } else if (rank == 3) {
      return const Icon(
        Icons.emoji_events_rounded,
        color: Color(0xFFCD7F32),
        size: 28,
      ); // Bronze
    } else {
      return Text(
        rank.toString(),
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2D2D2D),
        ),
      );
    }
  }
}

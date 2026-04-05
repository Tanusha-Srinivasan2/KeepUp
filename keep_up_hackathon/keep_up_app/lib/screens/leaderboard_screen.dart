import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> leaderboardData = [];
  bool isLoading = true;
  String? currentUserId;
  String? _errorMessage;

  // Use 10.0.2.2 for Android Emulator, localhost for iOS
  final String baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        _errorMessage = null;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('user_id');

    try {
      final url = Uri.parse('$baseUrl/api/news/user/leaderboard');

      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (mounted) {
          setState(() {
            leaderboardData = decoded is List ? decoded : [];
            isLoading = false;
          });
        }
      } else {
        print("Failed to load leaderboard: ${response.statusCode} - ${response.body}");
        if (mounted) {
          setState(() {
            _errorMessage = "Server error (${response.statusCode}). Tap retry.";
            isLoading = false;
          });
        }
      }
    } on TimeoutException {
      print("Leaderboard request timed out");
      if (mounted) {
        setState(() {
          _errorMessage = "Request timed out. Check your connection and retry.";
          isLoading = false;
        });
      }
    } on FormatException catch (e) {
      print("Invalid leaderboard response format: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Received an invalid response from the server.";
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching leaderboard: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Could not connect to server. Check your connection.";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFCE0),
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
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchLeaderboard,
                    color: Colors.orange,
                    child: (_errorMessage != null || leaderboardData.isEmpty)
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [_buildEmptyOrErrorState()],
                          )
                        : Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
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
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 24,
                                ),
                                itemCount: leaderboardData.length,
                                separatorBuilder: (context, index) => Divider(
                                  color: Colors.grey.withOpacity(0.3),
                                  thickness: 1,
                                  height: 24,
                                ),
                                itemBuilder: (context, index) {
                                  final user = leaderboardData[index];
                                  return _buildUserRow(user, index + 1);
                                },
                              ),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _errorMessage != null ? Icons.cloud_off : Icons.leaderboard_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage != null
                  ? "Couldn't load leaderboard"
                  : "No players yet",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? "Play the Daily Challenge to be the first on the board!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _fetchLeaderboard,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                "Retry",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
            ),
          ],
        ),
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
      ],
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user, int rank) {
    String uId = (user['userId'] ?? '').toString();
    bool isMe = uId == currentUserId;
    String name = isMe ? "You" : (user['name'] ?? "Unknown");
    int xp = int.tryParse(user['xp']?.toString() ?? '0') ?? 0;
    int streak = int.tryParse(user['streak']?.toString() ?? '0') ?? 0;

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
          SizedBox(width: 40, child: Center(child: _buildRankDisplay(rank))),
          const SizedBox(width: 15),
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
          if (streak > 0) ...[
            Image.asset('assets/fire.png', width: 18, height: 18),
            const SizedBox(width: 4),
            Text(
              "$streak",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(width: 12),
          ],
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
    if (rank == 1)
      return const Icon(
        Icons.emoji_events_rounded,
        color: Color(0xFFFFD700),
        size: 28,
      );
    if (rank == 2)
      return const Icon(
        Icons.emoji_events_rounded,
        color: Color(0xFFC0C0C0),
        size: 28,
      );
    if (rank == 3)
      return const Icon(
        Icons.emoji_events_rounded,
        color: Color(0xFFCD7F32),
        size: 28,
      );
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

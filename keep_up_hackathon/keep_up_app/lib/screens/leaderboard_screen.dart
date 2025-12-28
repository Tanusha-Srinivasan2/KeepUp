import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/user_model.dart';
import '../main.dart'; // To access KeepUpApp.primaryYellow, bgPurple, etc.

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<UserStats> users = [];
  bool isLoading = true;
  String myUserId = "";

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        myUserId = prefs.getString('user_id') ?? "";
      });
    }
    await fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    try {
      final url = Uri.parse('http://10.0.2.2:8080/api/news/leaderboard');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            users = data.map((e) => UserStats.fromJson(e)).toList();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching leaderboard: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Light Yellow background from your theme
      backgroundColor: const Color(0xFFFEFCE0),
      appBar: AppBar(
        title: Text(
          "Global Rankings",
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: KeepUpApp.bgPurple,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: KeepUpApp.bgPurple),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: KeepUpApp.bgPurple),
            )
          : users.isEmpty
          ? Center(
              child: Text("No rankings found.", style: GoogleFonts.nunito()),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                // Correct comparison logic using unique ID
                final bool isMe = user.id == myUserId;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    // Highlight: Solid Yellow for YOU, White for OTHERS
                    color: isMe ? KeepUpApp.primaryYellow : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: isMe
                        ? Border.all(color: KeepUpApp.bgPurple, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: _getRankColor(index),
                      child: Text(
                        "${index + 1}",
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          color: index < 3 ? Colors.white : KeepUpApp.bgPurple,
                        ),
                      ),
                    ),
                    title: Text(
                      isMe ? "${user.name} (You)" : user.name,
                      style: GoogleFonts.nunito(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                        fontSize: 18,
                        color: KeepUpApp.bgPurple,
                      ),
                    ),
                    trailing: Text(
                      "${user.xp} XP",
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isMe
                            ? KeepUpApp.bgPurple
                            : const Color(0xFF00E676),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getRankColor(int index) {
    if (index == 0) return const Color(0xFFFFD700); // Gold
    if (index == 1) return const Color(0xFFC0C0C0); // Silver
    if (index == 2) return const Color(0xFFCD7F32); // Bronze
    return Colors.transparent;
  }
}

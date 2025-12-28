import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../widgets/voice_button.dart';
import '../models/user_model.dart'; // Ensure this model exists in lib/models/

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
    _loadMyId();
    fetchLeaderboard();
  }

  // 1. Get the ID stored on this phone
  Future<void> _loadMyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Default to empty if not found
      myUserId = prefs.getString('user_id') ?? "";
    });
  }

  // 2. Fetch the Top 10 from Java Backend
  Future<void> fetchLeaderboard() async {
    try {
      // NOTE: Use 10.0.2.2 for Android Emulator
      final url = Uri.parse('http://10.0.2.2:8080/api/news/leaderboard');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          users = data.map((e) => UserStats.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load");
      }
    } catch (e) {
      print("Error fetching leaderboard: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: const VoiceAssistantButton(),
      appBar: AppBar(
        title: Text(
          "Global Rankings",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            )
          : users.isEmpty
          ? Center(
              child: Text(
                "No users found.",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            )
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];

                // CHECK: Is this row ME?
                final isMe = user.id == myUserId;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    // Highlight background if it's me
                    color: isMe
                        ? const Color(0xFF00E676).withOpacity(0.2)
                        : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(15),
                    // Highlight border if it's me
                    border: isMe
                        ? Border.all(color: const Color(0xFF00E676))
                        : null,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      // Rank Colors: 1=Gold, 2=Silver, 3=Bronze, Others=Grey
                      backgroundColor: index == 0
                          ? const Color(0xFFFFD700) // Gold
                          : (index == 1
                                ? const Color(0xFFC0C0C0) // Silver
                                : (index == 2
                                      ? const Color(0xFFCD7F32)
                                      : Colors.grey[800])), // Bronze
                      foregroundColor: Colors.black,
                      child: Text(
                        "${index + 1}",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      isMe ? "${user.name} (You)" : user.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                        fontSize: 18,
                      ),
                    ),
                    trailing: Text(
                      "${user.xp} XP",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF00E676),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

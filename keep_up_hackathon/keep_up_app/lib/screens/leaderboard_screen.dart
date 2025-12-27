import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/voice_button.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: const VoiceAssistantButton(),
      appBar: AppBar(
        title: Text(
          "Leaderboard",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          // HACK: Let's pretend YOU are Rank #4
          bool isMe = index == 3;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFF00E676).withOpacity(0.2)
                  : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(15),
              border: isMe ? Border.all(color: const Color(0xFF00E676)) : null,
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: index == 0
                    ? Colors.amber
                    : (isMe ? const Color(0xFF00E676) : Colors.grey[800]),
                foregroundColor: isMe ? Colors.black : Colors.white,
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                isMe ? "You (Hacker)" : "User ${index + 240}", // Fake names
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: Text(
                "${2500 - (index * 150)} XP", // Fake scores
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00E676),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

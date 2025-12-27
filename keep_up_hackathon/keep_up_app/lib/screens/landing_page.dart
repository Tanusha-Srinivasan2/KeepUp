import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Navigation Imports
import 'category_screen.dart';
import 'leaderboard_screen.dart';
import 'quiz_screen.dart';
import '../models/quiz_model.dart';

// Widget Imports
import '../widgets/voice_button.dart'; // <--- NEW IMPORT

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  Future<void> _startQuiz(BuildContext context) async {
    // Show loading indicator
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Loading Daily Challenge...")));

    try {
      // NOTE: Using 10.0.2.2 for Android Emulator
      final url = Uri.parse('http://10.0.2.2:8080/api/news/quiz');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> quizData = json.decode(response.body);
        final List<QuizQuestion> questions = quizData
            .map((q) => QuizQuestion.fromJson(q))
            .toList();

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(questions: questions),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not load quiz. Try generating on backend."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // GLOBAL VOICE ASSISTANT BUTTON
      floatingActionButton: const VoiceAssistantButton(),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header & Stats
              Text(
                "Welcome back,",
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
              ),
              Text(
                "Hacker!",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Stats Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00E676).withOpacity(0.2),
                      Colors.black,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00E676)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat("XP", "1,250"),
                    _buildStat("Streak", "5 Days"),
                    _buildStat("Rank", "#12"),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 2. Main Actions
              Text(
                "Explore",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              _buildMenuButton(
                context,
                "Daily Challenge",
                Icons.videogame_asset,
                Colors.purpleAccent,
                () => _startQuiz(context),
              ),
              _buildMenuButton(
                context,
                "Read News",
                Icons.article,
                const Color(0xFF00E676),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryScreen(),
                  ),
                ),
              ),
              _buildMenuButton(
                context,
                "Leaderboard",
                Icons.leaderboard,
                Colors.orangeAccent,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaderboardScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 20),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // To get ID
import 'dart:convert';

// Navigation Imports
import 'category_screen.dart';
import 'leaderboard_screen.dart';
import 'quiz_screen.dart';
import 'catchup_screen.dart'; // Make sure this exists from previous step
import '../models/quiz_model.dart';
import '../widgets/voice_button.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // Default values until data loads
  String username = "Hacker";
  String xp = "...";
  String rank = "...";
  String streak = "3 Days";
  bool isLoadingQuiz = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // 1. Fetch User Stats (XP, Rank)
  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    String? storedName = prefs.getString('user_name');

    if (userId == null) return;

    setState(() => username = storedName ?? "Hacker");

    try {
      // NOTE: Using 10.0.2.2 for Android Emulator
      final url = Uri.parse('http://10.0.2.2:8080/api/news/user/$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            xp = data['xp'].toString();
            rank = "#${data['rank']}";
            streak = "${data['streak']} Days";
          });
        }
      }
    } catch (e) {
      print("Error loading stats: $e");
    }
  }

  // 2. Start Quiz Logic
  Future<void> _startQuiz() async {
    setState(() => isLoadingQuiz = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Generating Daily Challenge...")),
    );

    try {
      final url = Uri.parse('http://10.0.2.2:8080/api/news/quiz');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> quizData = json.decode(response.body);
        final List<QuizQuestion> questions = quizData
            .map((q) => QuizQuestion.fromJson(q))
            .toList();

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(questions: questions),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Could not load quiz.")));
      }
    } finally {
      if (mounted) setState(() => isLoadingQuiz = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: const VoiceAssistantButton(),

      body: SafeArea(
        child: SingleChildScrollView(
          // Added scroll in case screen is small
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
                  "$username!",
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
                      _buildStat("XP", xp),
                      _buildStat("Streak", streak),
                      _buildStat("Rank", rank),
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
                  isLoadingQuiz ? null : _startQuiz, // Disable click if loading
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
                  "Catch Up",
                  Icons.history,
                  Colors.blueAccent,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CatchUpScreen(),
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
    VoidCallback? onTap,
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
              if (onTap == null) // Show loading spinner if tapped
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

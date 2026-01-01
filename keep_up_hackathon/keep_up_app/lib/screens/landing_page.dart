import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../main.dart'; // Colors
import '../models/quiz_model.dart';

// Screens
import 'category_screen.dart';
import 'leaderboard_screen.dart';
import 'quiz_screen.dart';
import 'catchup_screen.dart';
import 'bookmarks_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String username = "Hacker";
  String xp = "...";
  String rank = "...";
  String streak = "...";
  bool isLoadingQuiz = false;
  int _selectedIndex = 0;

  // ✅ 1. VOICE ASSISTANT VARIABLES
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    flutterTts.stop();
    _speech.cancel();
    super.dispose();
  }

  // ✅ 2. CHAT MODAL LOGIC (The Fox's Brain)
  void _showChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChatSheet(),
    );
  }

  Widget _buildChatSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: 400,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/fox.png', width: 40, height: 40),
                      const SizedBox(width: 10),
                      Text(
                        "How can I help?",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),

              // Status Text
              Expanded(
                child: Center(
                  child: _isThinking
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Checking the news...",
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          ],
                        )
                      : Text(
                          "Tap the mic to ask about the latest news, stats, or general questions.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                ),
              ),

              // Mic Button
              GestureDetector(
                onTapDown: (_) async {
                  bool available = await _speech.initialize();
                  if (available) {
                    setModalState(() => _isListening = true);
                    _speech.listen(
                      onResult: (val) async {
                        if (val.hasConfidenceRating && val.confidence > 0) {
                          if (val.finalResult) {
                            setModalState(() {
                              _isListening = false;
                              _isThinking = true;
                            });
                            await _askAI(val.recognizedWords);
                            if (mounted)
                              Navigator.pop(context); // Close after asking
                          }
                        }
                      },
                    );
                  }
                },
                onTapUp: (_) {
                  setModalState(() => _isListening = false);
                  _speech.stop();
                },
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: _isListening ? Colors.red : Colors.orange,
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isListening ? "Listening..." : "Hold to Speak",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _askAI(String question) async {
    // Calls your General Chat Endpoint (which searches all news)
    final url = Uri.parse(
      'http://10.0.2.2:8080/api/news/chat?question=$question',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        await flutterTts.speak(response.body);
      }
    } catch (e) {
      print("AI Error: $e");
      await flutterTts.speak("Sorry, I'm having trouble connecting.");
    }
  }

  // --- EXISTING LOGIC ---

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    String? storedName = prefs.getString('user_name');
    if (userId == null) return;

    setState(() => username = storedName ?? "Hacker");

    try {
      final url = Uri.parse('http://10.0.2.2:8080/api/news/user/$userId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            xp = data['xp'].toString();
            rank = data['rank'].toString();
            streak = data['streak'].toString();
          });
        }
      }
    } catch (e) {
      print("Error loading stats: $e");
    }
  }

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

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CategoryScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ 3. REMOVED floatingActionButton (Green Mic)
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTopStat('assets/lightning.png', xp),
            _buildTopStat('assets/fire.png', streak),
            _buildTopStat(
              'assets/gem.png',
              rank,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaderboardScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome Section
            Row(
              children: [
                // ✅ 4. WRAPPED FOX IN GESTURE DETECTOR
                GestureDetector(
                  onTap: _showChatModal, // Clicking Fox opens Chat
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/fox.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome,",
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        username,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: KeepUpApp.primaryYellow,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 2. Main Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildMainCard(
                    context,
                    title: "Daily Challenge",
                    subtitle: "3 Questions",
                    bgColor: KeepUpApp.bgYellow,
                    textColor: KeepUpApp.textColor,
                    btnColor: KeepUpApp.primaryYellow,
                    onTap: isLoadingQuiz ? null : _startQuiz,
                    isLoading: isLoadingQuiz,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildMainCard(
                    context,
                    title: "Catch me Up",
                    subtitle: "15 Minutes",
                    bgColor: KeepUpApp.bgPurple,
                    textColor: Colors.white,
                    btnColor: Colors.white.withOpacity(0.2),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CatchUpScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 3. Full Width Cards
            _buildFullWidthCard(
              context,
              title: "Explore today's top news",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryScreen()),
              ),
            ),
            const SizedBox(height: 20),

            _buildFullWidthCard(
              context,
              title: "Your Bookmarks",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookmarksScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: KeepUpApp.textColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // ... (Helper widgets remain unchanged)
  Widget _buildTopStat(String imagePath, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Image.asset(imagePath, width: 24, height: 24),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color textColor,
    required Color btnColor,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 200,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: textColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: textColor,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      "Start",
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthCard(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: KeepUpApp.bgYellow,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: KeepUpApp.textColor,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: KeepUpApp.textColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

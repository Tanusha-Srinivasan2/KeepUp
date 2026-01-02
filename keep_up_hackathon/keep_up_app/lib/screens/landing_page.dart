import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_sign_in/google_sign_in.dart';

import '../main.dart';
import '../models/quiz_model.dart';

import 'category_screen.dart';
import 'leaderboard_screen.dart';
import 'quiz_screen.dart';
import 'catchup_screen.dart';
import 'bookmarks_screen.dart';
import 'auth_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String username = "Reader";
  String xp = "...";
  String rank = "...";
  String streak = "...";
  bool isLoadingQuiz = false;
  int _selectedIndex = 0;

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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await GoogleSignIn().signOut();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    String? storedName = prefs.getString('user_name');

    if (userId == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
      return;
    }

    setState(() => username = storedName ?? "Reader");

    try {
      final url = Uri.parse('http://10.0.2.2:8080/api/news/user/$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            xp = (data['xp'] ?? 0).toString();
            rank = (data['rank'] ?? 0).toString();
            streak = (data['streak'] ?? 1).toString();
          });
        }
      }
    } catch (e) {
      print("Error loading stats: $e");
    }
  }

  void _showEditNameDialog() {
    TextEditingController nameController = TextEditingController(
      text: username,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Change Username",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "New Username",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KeepUpApp.primaryYellow,
              ),
              onPressed: () async {
                String newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  await _updateNameInBackend(newName);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Save", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateNameInBackend(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId == null) return;

    setState(() => username = newName);
    await prefs.setString('user_name', newName);

    try {
      final url = Uri.parse(
        'http://10.0.2.2:8080/api/news/user/updateName?userId=$userId&newName=$newName',
      );
      await http.post(url);
    } catch (e) {
      print("Error updating name: $e");
    }
  }

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
                            if (mounted) Navigator.pop(context);
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
    final url = Uri.parse(
      'http://10.0.2.2:8080/api/news/chat?question=$question',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) await flutterTts.speak(response.body);
    } catch (e) {
      print("AI Error: $e");
      await flutterTts.speak("Sorry, I'm having trouble connecting.");
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
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(questions: questions),
            ),
          );
          _fetchUserData();
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Could not load quiz.")));
    } finally {
      if (mounted) setState(() => isLoadingQuiz = false);
    }
  }

  void _onItemTapped(int index) async {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CategoryScreen()),
      );
    } else if (index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
      );
      _fetchUserData();
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.brown),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTopStat('assets/lightning.png', xp),
            _buildTopStat('assets/fire.png', streak),
            _buildTopStat(
              'assets/gem.png',
              rank,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaderboardScreen(),
                  ),
                );
                _fetchUserData();
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUserData,
        color: KeepUpApp.primaryYellow,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _showChatModal,
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                username,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.nunito(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: KeepUpApp.primaryYellow,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _showEditNameDialog,
                              child: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
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
              _buildFullWidthCard(
                context,
                title: "Explore today's top news",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildFullWidthCard(
                context,
                title: "Your Bookmarks",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookmarksScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // ✅ NAV BAR WITH NO SHADOW
      bottomNavigationBar: Container(
        height: 90,
        decoration: const BoxDecoration(
          color: Color(0xFFFFF9E5), // Matches Scaffold Background
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
          // NO SHADOW HERE
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_outlined, "Home", 0),
            _buildNavItem(Icons.explore_outlined, "Explore", 1),
            _buildNavItem(Icons.leaderboard_outlined, "Rank", 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: isSelected
                ? BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(20),
                  )
                : null,
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 26,
            ),
          ),
          if (!isSelected) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

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

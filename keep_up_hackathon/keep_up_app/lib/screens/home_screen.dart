import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';

// IMPORTS for Quiz Feature
import '../models/news_model.dart';
import '../models/quiz_model.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<NewsCard> cards = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  // --- FEATURE 1: NEWS FEED ---
  Future<void> fetchNews() async {
    final url = Uri.parse('http://10.0.2.2:8080/api/news/feed');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          cards = data.map((json) => NewsCard.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load news");
      }
    } catch (e) {
      print("Error fetching news: $e");
      setState(() => isLoading = false);
    }
  }

  // --- FEATURE 2: DAILY QUIZ ---
  Future<void> startQuiz() async {
    // 1. Fetch the Quiz from Backend
    final url = Uri.parse('http://10.0.2.2:8080/api/news/quiz');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // 2. Parse the JSON List
        final List<dynamic> quizData = json.decode(response.body);

        final List<QuizQuestion> questions = quizData
            .map((q) => QuizQuestion.fromJson(q))
            .toList();

        // 3. Navigate to Quiz Screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(questions: questions),
            ),
          );
        }
      } else {
        print("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching quiz: $e");
      // Show a little popup if it fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No quiz found! Generate one on the backend first."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Keep Up",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // --- NEW: PLAY QUIZ BUTTON ---
          IconButton(
            onPressed: startQuiz,
            icon: const Icon(
              Icons.videogame_asset,
              color: Color(0xFF00E676),
              size: 30,
            ),
            tooltip: "Play Daily Challenge",
          ),
          const SizedBox(width: 10),
          // Refresh Button
          IconButton(
            onPressed: fetchNews,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            )
          : cards.isEmpty
          ? const Center(
              child: Text(
                "No News Found. Try Generating on Backend!",
                style: TextStyle(color: Colors.white),
              ),
            )
          : CardSwiper(
              cardsCount: cards.length,
              cardBuilder:
                  (context, index, percentThresholdX, percentThresholdY) {
                    final card = cards[index];
                    return _buildNewsCard(card);
                  },
            ),
    );
  }

  Widget _buildNewsCard(NewsCard card) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E676), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                card.topic.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00E676),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              card.contentLine,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

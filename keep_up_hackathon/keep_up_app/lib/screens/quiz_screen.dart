import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http; // Request to backend
import 'package:shared_preferences/shared_preferences.dart'; // To get User ID

import '../models/quiz_model.dart';
import '../widgets/voice_button.dart';

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  const QuizScreen({super.key, required this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  bool answered = false;
  bool showExplanation = false;
  int score = 0;
  bool isSubmitting = false; // To show loading at the end
  final FlutterTts flutterTts = FlutterTts();

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  void handleAnswer(int selectedIndex) {
    if (answered) return;
    bool isCorrect =
        selectedIndex == widget.questions[currentIndex].correctIndex;
    if (isCorrect) score++;

    setState(() {
      answered = true;
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => showExplanation = true);
          _speak(widget.questions[currentIndex].explanation);
        }
      });
    });
  }

  // --- NEW: LOGIC TO SUBMIT SCORE ---
  Future<void> finishQuiz() async {
    setState(() => isSubmitting = true);
    flutterTts.stop();

    // 1. Calculate XP
    int earnedXp = score * 20;

    // 2. Get User ID
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId != null && earnedXp > 0) {
      try {
        // 3. Send to Backend
        final url = Uri.parse(
          'http://10.0.2.2:8080/api/news/user/xp?userId=$userId&points=$earnedXp',
        );
        await http.post(url);
        print("XP Updated!");
      } catch (e) {
        print("Error updating XP: $e");
      }
    }

    // 4. Show Success Message & Close
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Quiz Complete! You earned $earnedXp XP!"),
          backgroundColor: const Color(0xFF00E676),
        ),
      );
      Navigator.pop(context); // Go back to Home
    }
  }

  void nextQuestion() {
    flutterTts.stop();
    if (currentIndex < widget.questions.length - 1) {
      setState(() {
        currentIndex++;
        answered = false;
        showExplanation = false;
      });
    } else {
      // Quiz is Over -> Submit Score
      finishQuiz();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If submitting, show loading screen
    if (isSubmitting) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00E676)),
        ),
      );
    }

    final question = widget.questions[currentIndex];

    // --- VIEW 1: EXPLANATION ---
    if (showExplanation) {
      return Scaffold(
        backgroundColor: Colors.black,
        floatingActionButton: const VoiceAssistantButton(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "DID YOU KNOW?",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00E676),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: Center(
                    child: Text(
                      question.explanation,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                    ),
                    child: Text(
                      currentIndex < widget.questions.length - 1
                          ? "NEXT QUESTION"
                          : "FINISH QUIZ",
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- VIEW 2: QUESTION ---
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Challenge ${currentIndex + 1}/3"),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: const VoiceAssistantButton(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              question.question,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),
            ...List.generate(question.options.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton(
                    onPressed: () => handleAnswer(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: answered
                          ? (index == question.correctIndex
                                ? Colors.green
                                : Colors.grey[900])
                          : const Color(0xFF1E1E1E),
                      side: BorderSide(
                        color: answered && index == question.correctIndex
                            ? Colors.green
                            : Colors.grey[800]!,
                      ),
                    ),
                    child: Text(
                      question.options[index],
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

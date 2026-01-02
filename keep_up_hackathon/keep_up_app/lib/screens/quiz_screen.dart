import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/quiz_model.dart';
import '../main.dart'; // KeepUpApp colors
import 'quiz_result_screen.dart'; // ✅ Import Result Screen

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  const QuizScreen({super.key, required this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  int? selectedIndex;
  bool isAnswerLocked = false;
  bool showExplanation = false;
  int score = 0;
  bool isSubmitting = false;

  final FlutterTts flutterTts = FlutterTts();

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.1);
    await flutterTts.speak(text);
  }

  void onOptionSelected(int index) {
    if (isAnswerLocked) return;
    setState(() => selectedIndex = index);
  }

  void onMainButtonClick() {
    if (selectedIndex == null) return;

    if (!isAnswerLocked) {
      // 1. Validate Answer
      bool isCorrect =
          selectedIndex == widget.questions[currentIndex].correctIndex;
      if (isCorrect) score++;
      setState(() => isAnswerLocked = true);
    } else if (!showExplanation) {
      // 2. Show Explanation (Bottom Sheet)
      _showResultBottomSheet(
        selectedIndex == widget.questions[currentIndex].correctIndex,
        widget.questions[currentIndex],
      );
    } else {
      // 3. Next Question (Handled by closing the sheet)
      _nextQuestion();
    }
  }

  void _nextQuestion() {
    if (currentIndex < widget.questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedIndex = null;
        isAnswerLocked = false;
        showExplanation = false;
      });
    } else {
      _finishQuiz();
    }
  }

  // Result Sheet with Topic Image & Short Layout
  void _showResultBottomSheet(bool isCorrect, QuizQuestion question) {
    setState(() => showExplanation = true);
    _speak(question.explanation); // Auto-speak

    // Map topics to images
    Map<String, String> topicImages = {
      "Technology":
          "https://images.unsplash.com/photo-1518770660439-4636190af475?w=400",
      "Sports":
          "https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=400",
      "Business":
          "https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400",
      "Science":
          "https://images.unsplash.com/photo-1507413245164-6160d8298b31?w=400",
      "Politics":
          "https://images.unsplash.com/photo-1529101091760-6149d4c81f22?w=400",
      "General":
          "https://images.unsplash.com/photo-1493612276216-ee3925520721?w=400",
    };

    String imageUrl = topicImages[question.topic] ?? topicImages["General"]!;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF9E5), // Cream
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Takes minimal height
            children: [
              Text(
                isCorrect ? "Correct!" : "Did You Know?",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.green : const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 15),

              // Topic Image
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Image.asset('assets/fox.png', height: 150),
                ),
              ),
              const SizedBox(height: 15),

              // Explanation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  question.explanation,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    flutterTts.stop();
                    Navigator.pop(context); // Close sheet
                    _nextQuestion();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D2D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    currentIndex < widget.questions.length - 1
                        ? "Next Question"
                        : "Finish Quiz",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ UPDATED: Navigates to Result Screen
  Future<void> _finishQuiz() async {
    setState(() => isSubmitting = true);

    int earnedXp = score * 20;
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    // 1. Send XP to Backend
    if (userId != null && earnedXp > 0) {
      try {
        final url = Uri.parse(
          'http://10.0.2.2:8080/api/news/user/xp?userId=$userId&points=$earnedXp',
        );
        await http.post(url);
      } catch (e) {
        print("Error sending XP: $e");
      }
    }

    if (mounted) {
      // 2. Navigate to Result Screen (Replace QuizScreen so back button goes home)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            score: score,
            totalQuestions: widget.questions.length,
            xpEarned: earnedXp,
            onContinue: () {
              Navigator.pop(context); // Closes ResultScreen -> Back to Home
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isSubmitting) {
      return const Scaffold(
        backgroundColor: Color(0xFFFEFCE0),
        body: Center(
          child: CircularProgressIndicator(color: KeepUpApp.bgPurple),
        ),
      );
    }

    final question = widget.questions[currentIndex];
    double progress = (currentIndex + 1) / widget.questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFCE0),
      // Fox Helper
      floatingActionButton: GestureDetector(
        onTap: () => _speak(question.question),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Image.asset('assets/fox.png', height: 80),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header & Progress
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: KeepUpApp.bgPurple),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: KeepUpApp.bgPurple.withOpacity(0.1),
                        color: KeepUpApp.bgPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Question Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8B8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Question ${currentIndex + 1}/${widget.questions.length}",
                      style: GoogleFonts.nunito(
                        color: KeepUpApp.bgPurple.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      question.question,
                      style: GoogleFonts.nunito(
                        color: KeepUpApp.bgPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Options List
              Expanded(
                child: ListView.separated(
                  itemCount: question.options.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    bool isSelected = selectedIndex == index;
                    bool isCorrect = index == question.correctIndex;

                    Color bgColor = Colors.transparent;
                    Color borderColor = const Color(0xFFFFE082);

                    if (isAnswerLocked) {
                      if (isCorrect) {
                        bgColor = Colors.green;
                        borderColor = Colors.green;
                      } else if (isSelected && !isCorrect) {
                        bgColor = Colors.redAccent;
                        borderColor = Colors.redAccent;
                      }
                    } else if (isSelected) {
                      bgColor = const Color(0xFFFFE082);
                      borderColor = const Color(0xFFFFE082);
                    }

                    return GestureDetector(
                      onTap: () => onOptionSelected(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Text(
                          question.options[index],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isAnswerLocked && (isCorrect || isSelected)
                                ? Colors.white
                                : KeepUpApp.bgPurple,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Main Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedIndex == null ? null : onMainButtonClick,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KeepUpApp.bgPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    isAnswerLocked ? "Check" : "Submit",
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
}

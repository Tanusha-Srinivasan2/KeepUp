import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart'; // KeepUpApp colors
import 'quiz_result_screen.dart';
import 'landing_page.dart';
import '../models/quiz_model.dart';

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String quizId;

  const QuizScreen({super.key, required this.questions, required this.quizId});

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

  // Randomized State Variables
  List<String> currentShuffledOptions = [];
  int currentCorrectIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  void _loadQuestion() {
    final question = widget.questions[currentIndex];

    // Create indices [0, 1, 2, 3]
    List<int> originalIndices = List.generate(
      question.options.length,
      (index) => index,
    );

    // Shuffle them
    originalIndices.shuffle();

    setState(() {
      currentShuffledOptions = originalIndices
          .map((index) => question.options[index])
          .toList();
      currentCorrectIndex = originalIndices.indexOf(question.correctIndex);
      selectedIndex = null;
      isAnswerLocked = false;
      showExplanation = false;
    });
  }

  void onOptionSelected(int index) {
    if (isAnswerLocked) return;
    setState(() => selectedIndex = index);
  }

  void onMainButtonClick() {
    if (selectedIndex == null) return;

    if (!isAnswerLocked) {
      bool isCorrect = selectedIndex == currentCorrectIndex;
      if (isCorrect) score++;
      setState(() => isAnswerLocked = true);
      _showResultBottomSheet(isCorrect, widget.questions[currentIndex]);
    } else {
      _nextQuestion();
    }
  }

  void _nextQuestion() {
    if (currentIndex < widget.questions.length - 1) {
      setState(() {
        currentIndex++;
      });
      _loadQuestion();
    } else {
      _finishQuiz();
    }
  }

  void _showResultBottomSheet(bool isCorrect, QuizQuestion question) {
    setState(() => showExplanation = true);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF9E5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
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
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _finishQuiz() async {
    setState(() => isSubmitting = true);
    int earnedXp = score * 20;

    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    // Lock the quiz locally
    String today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('last_played_${widget.quizId}', today);

    // ✅ SEND XP TO BACKEND WITH CORRECT URL FORMAT
    if (userId != null && earnedXp > 0) {
      try {
        // Matches Backend: @PostMapping("/{userId}/xp")
        final url = Uri.parse(
          'http://10.0.2.2:8080/api/news/user/$userId/xp?points=$earnedXp&category=${widget.quizId}',
        );

        final response = await http.post(url);

        if (response.statusCode == 200) {
          print("✅ XP Updated Successfully: $earnedXp points");
        } else {
          print("❌ Server Error (${response.statusCode}): ${response.body}");
        }
      } catch (e) {
        print("❌ Connection Error sending XP: $e");
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            score: score,
            totalQuestions: widget.questions.length,
            xpEarned: earnedXp,
            onContinue: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LandingPage()),
                (route) => false,
              );
            },
          ),
        ),
      );
    }
  }

  String _cleanOptionText(String text) {
    return text.replaceAll(RegExp(r'^[A-D1-4a-d][\.\)]\s*'), '');
  }

  @override
  Widget build(BuildContext context) {
    if (isSubmitting) {
      return const Scaffold(
        backgroundColor: Color(0xFFFEFCE0),
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    final question = widget.questions[currentIndex];
    double progress = (currentIndex + 1) / widget.questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFCE0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header with Progress Bar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF2D2D2D)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: const Color(
                          0xFF2D2D2D,
                        ).withOpacity(0.1),
                        color: const Color(0xFF2D2D2D),
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
                        color: const Color(0xFF2D2D2D).withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      question.question,
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF2D2D2D),
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
                  itemCount: currentShuffledOptions.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    bool isSelected = selectedIndex == index;
                    bool isCorrect = index == currentCorrectIndex;
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
                          _cleanOptionText(currentShuffledOptions[index]),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isAnswerLocked && (isCorrect || isSelected)
                                ? Colors.white
                                : const Color(0xFF2D2D2D),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedIndex == null ? null : onMainButtonClick,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D2D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    isAnswerLocked ? "Next" : "Submit",
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

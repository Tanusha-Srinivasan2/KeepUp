import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quiz_model.dart';

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

  void handleAnswer(int selectedIndex) {
    if (answered) return;

    bool isCorrect =
        selectedIndex == widget.questions[currentIndex].correctIndex;
    if (isCorrect) score++;

    setState(() {
      answered = true;
      // Wait 1 second, then show the explanation card
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          showExplanation = true;
        });
      });
    });
  }

  void nextQuestion() {
    if (currentIndex < widget.questions.length - 1) {
      setState(() {
        currentIndex++;
        answered = false;
        showExplanation = false;
      });
    } else {
      // Quiz Over - Go back
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentIndex];

    // If showing explanation, show the "Learn More" card
    if (showExplanation) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E676), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "DID YOU KNOW?",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  question.explanation,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                  ),
                  child: Text(
                    "Next",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Otherwise, show the Question
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Daily Challenge ${currentIndex + 1}/3"),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              question.question,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ...List.generate(question.options.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => handleAnswer(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: answered
                          ? (index == question.correctIndex
                                ? Colors.green
                                : (Colors.grey[800]))
                          : const Color(0xFF2C2C2C),
                    ),
                    child: Text(
                      question.options[index],
                      style: GoogleFonts.poppins(color: Colors.white),
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

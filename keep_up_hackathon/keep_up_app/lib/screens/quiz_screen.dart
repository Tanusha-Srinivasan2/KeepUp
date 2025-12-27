import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/quiz_model.dart';
import '../widgets/voice_button.dart'; // Import your new button

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
          _speak(widget.questions[currentIndex].explanation); // Auto-speak
        }
      });
    });
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
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentIndex];

    // --- FULL SCREEN EXPLANATION (No Card Margins) ---
    if (showExplanation) {
      return Scaffold(
        backgroundColor: Colors.black,
        // Also has the Voice Button!
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
                      "NEXT QUESTION",
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

    // --- QUESTION SCREEN ---
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Challenge ${currentIndex + 1}/3"),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton:
          const VoiceAssistantButton(), // <--- VOICE BUTTON HERE
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

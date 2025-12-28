import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Import TTS

import '../models/quiz_model.dart';
import '../main.dart'; // Import to use KeepUpApp colors

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

  // TTS Engine
  final FlutterTts flutterTts = FlutterTts();

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  // Helper to make the Fox Speak
  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.1); // Slightly higher pitch for a "Fox" voice
    await flutterTts.speak(text);
  }

  void onOptionSelected(int index) {
    if (isAnswerLocked) return;
    setState(() {
      selectedIndex = index;
    });
  }

  void onMainButtonClick() {
    if (selectedIndex == null) return;

    if (!isAnswerLocked) {
      // Stage 2: Validate
      bool isCorrect =
          selectedIndex == widget.questions[currentIndex].correctIndex;
      if (isCorrect) score++;

      setState(() {
        isAnswerLocked = true;
      });
    } else if (!showExplanation) {
      // Stage 3: Explain
      setState(() {
        showExplanation = true;
      });
      // Auto-speak the fun fact when it appears
      _speak(widget.questions[currentIndex].explanation);
    } else {
      // Next Question
      flutterTts.stop(); // Stop speaking when moving on
      if (currentIndex < widget.questions.length - 1) {
        setState(() {
          currentIndex++;
          selectedIndex = null;
          isAnswerLocked = false;
          showExplanation = false;
        });
      } else {
        finishQuiz();
      }
    }
  }

  Future<void> finishQuiz() async {
    setState(() => isSubmitting = true);

    int earnedXp = score * 20;
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId != null && earnedXp > 0) {
      try {
        final url = Uri.parse(
          'http://10.0.2.2:8080/api/news/user/xp?userId=$userId&points=$earnedXp',
        );
        await http.post(url);
      } catch (e) {
        print("Error: $e");
      }
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Quiz Complete! +$earnedXp XP"),
          backgroundColor: KeepUpApp.primaryYellow,
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

    // --- VIEW 3: "DID YOU KNOW" EXPLANATION CARD ---
    if (showExplanation) {
      return Scaffold(
        backgroundColor: const Color(0xFFFEFCE0),
        appBar: AppBar(
          title: Text(
            "Did You Know?",
            style: GoogleFonts.nunito(color: Colors.grey, fontSize: 16),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(),
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Image.asset('assets/fox.png', height: 120),
                ),
              ),
              const SizedBox(height: 30),

              Text(
                "Interesting Fact",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: KeepUpApp.bgPurple,
                ),
              ),
              const SizedBox(height: 15),

              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    question.explanation,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      color: KeepUpApp.textColor.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              // --- CLICKABLE FOX (Plays Audio) ---
              Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  onTap: () => _speak(question.explanation),
                  child: Image.asset('assets/fox.png', height: 80),
                ),
              ),

              const SizedBox(height: 20), // Space for button

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onMainButtonClick,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KeepUpApp.bgPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    currentIndex < widget.questions.length - 1
                        ? "Next Question"
                        : "Finish Quiz",
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
      );
    }

    // --- VIEW 1 & 2: QUESTION & VALIDATION ---
    double progress = (currentIndex + 1) / widget.questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFCE0),

      // --- NEW: FOX AS VOICE ASSISTANT FAB ---
      floatingActionButton: GestureDetector(
        onTap: () => _speak(question.question), // Click to read question
        child: Container(
          margin: const EdgeInsets.only(
            bottom: 60,
          ), // Move up slightly so it doesn't block "Continue"
          child: Image.asset('assets/fox.png', height: 90),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
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

                    Color textColor =
                        (isAnswerLocked &&
                            (isCorrect || (isSelected && !isCorrect)))
                        ? Colors.white
                        : KeepUpApp.bgPurple.withOpacity(0.7);

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
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
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
                    isAnswerLocked ? "Next" : "Continue",
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http; // Kept for consistency
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart'; // KeepUpApp colors
import 'quiz_result_screen.dart';
import '../models/quiz_model.dart'; // ✅ Ensure this file exists!

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

  final FlutterTts flutterTts = FlutterTts();

  // ✅ Randomized State Variables
  List<String> currentShuffledOptions = [];
  int currentCorrectIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  // ✅ ROBUST SHUFFLING LOGIC
  void _loadQuestion() {
    final question = widget.questions[currentIndex];

    // 1. Create indices [0, 1, 2, 3]
    List<int> originalIndices = List.generate(
      question.options.length,
      (index) => index,
    );

    // 2. Shuffle them!
    originalIndices.shuffle();

    setState(() {
      // 3. Reorder the text options based on shuffled indices
      currentShuffledOptions = originalIndices.map((index) {
        return question.options[index];
      }).toList();

      // 4. Find where the ORIGINAL correct answer moved to
      // Example: If correct was 0, and 0 moved to index 3, this returns 3.
      currentCorrectIndex = originalIndices.indexOf(question.correctIndex);

      // Debug Print to Console
      print("--- Question ${currentIndex + 1} ---");
      print("Shuffled Layout: $originalIndices");
      print("New Correct Slot: Index $currentCorrectIndex");
      print(
        "Correct Answer Text: ${currentShuffledOptions[currentCorrectIndex]}",
      );

      // Reset UI state
      selectedIndex = null;
      isAnswerLocked = false;
      showExplanation = false;
    });
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
      // ✅ VITAL: Compare selected index with the SHUFFLED correct index
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
      _loadQuestion(); // ✅ Shuffle the next question immediately
    } else {
      _finishQuiz();
    }
  }

  void _showResultBottomSheet(bool isCorrect, QuizQuestion question) {
    setState(() => showExplanation = true);

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
      isScrollControlled: true, // ✅ Allows scrolling if content is long
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF9E5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            // ✅ Makes the popup scrollable
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isCorrect ? "Correct!" : "Did You Know?",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isCorrect
                            ? Colors.green
                            : const Color(0xFF2D2D2D),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _speak(question.explanation),
                      child: Column(
                        children: [
                          Image.asset('assets/fox.png', height: 50),
                          Text(
                            "Tap to listen",
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Container(color: Colors.orange[100], height: 120),
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
                      flutterTts.stop();
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
    String today = DateTime.now().toString().split(' ')[0];
    await prefs.setString('last_played_${widget.quizId}', today);

    // Send XP to Backend (Use 10.0.2.2 for Emulator)
    if (userId != null && earnedXp > 0) {
      try {
        final url = Uri.parse(
          'http://10.0.2.2:8080/api/news/user/xp?userId=$userId&points=$earnedXp&category=${widget.quizId}',
        );
        await http.post(url);
      } catch (e) {
        print("Error sending XP: $e");
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
            onContinue: () => Navigator.pop(context),
          ),
        ),
      );
    }
  }

  // ✅ CLEANER HELPER: Removes "A. ", "1. ", etc.
  String _cleanOptionText(String text) {
    return text.replaceAll(RegExp(r'^[A-D1-4a-d][\.\)]\s*'), '');
  }

  @override
  Widget build(BuildContext context) {
    // 🚨 SAFETY CHECK: If state is lost/stale, reload it
    if (currentShuffledOptions.isEmpty) {
      _loadQuestion();
    }

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
      // Fox Icon for TTS
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
              // Header Row
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
                  itemCount: currentShuffledOptions.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    bool isSelected = selectedIndex == index;

                    // ✅ THIS LINE IS THE KEY: Check against SHUFFLED Index
                    bool isCorrect = index == currentCorrectIndex;

                    Color bgColor = Colors.transparent;
                    Color borderColor = const Color(0xFFFFE082);

                    if (isAnswerLocked) {
                      // Logic: Always show the REAL correct answer in Green.
                      if (isCorrect) {
                        bgColor = Colors.green;
                        borderColor = Colors.green;
                      }
                      // Logic: If you picked wrong, show Red on your pick.
                      else if (isSelected && !isCorrect) {
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
                          // Use the clean helper
                          _cleanOptionText(currentShuffledOptions[index]),
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

              // Submit Button
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

              // 🧪 DEBUG TEXT (Remove before Finals!)
              // This shows you the answer so you can verify the logic is working
              if (!isAnswerLocked)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "Debug: Answer is at Index $currentCorrectIndex",
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final int xpEarned;
  final VoidCallback onContinue;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.xpEarned,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFCE0), // Cream Background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // 1. Fox Image
              Image.asset('assets/fox.png', height: 180, fit: BoxFit.contain),
              const SizedBox(height: 30),

              // 2. Title
              Text(
                "Well Done!",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 10),

              // 3. Subtitle
              Text(
                "QUESTIONS YOU GOT RIGHT",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              // 4. Score Big Text
              Text(
                "$score of $totalQuestions",
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.w900, // Extra bold
                  color: const Color(0xFF2D2D2D),
                ),
              ),

              const SizedBox(height: 15),

              // 5. XP Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Text(
                  "+$xpEarned XP Earned",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),

              const Spacer(),

              // 6. Buttons

              // Continue Button (Filled Dark)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D2D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    "Continue",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Exit Button (Outlined)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: OutlinedButton(
                  onPressed: onContinue, // Acts same as continue for now
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2D2D2D), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Exit",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

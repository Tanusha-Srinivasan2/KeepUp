import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'landing_page.dart';
import 'leaderboard_screen.dart';
import 'quiz_screen.dart';
import '../models/quiz_model.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final String baseUrl = "http://10.0.2.2:8080";

  // ✅ UPDATED: Using Local Assets for Instant Loading
  final List<Map<String, dynamic>> categories = const [
    {
      "name": "Technology",
      "image": "assets/technology.png", // <--- Local Asset
      "color": Color(0xFFFFF9C4),
    },
    {
      "name": "Business",
      "image": "assets/business.png",
      "color": Color(0xFFFFE082),
    },
    {
      "name": "Science",
      "image": "assets/science.png",
      "color": Color(0xFFFFCC80),
    },
    {
      "name": "Politics",
      "image": "assets/politics.png",
      "color": Color(0xFFFFB74D),
    },
    {
      "name": "Sports",
      "image": "assets/sports.png",
      "color": Color(0xFFFFA726),
    },
  ];

  Future<void> _fetchAndStartQuiz(String category) async {
    final prefs = await SharedPreferences.getInstance();
    String? lastPlayed = prefs.getString('last_played_$category');
    String today = DateTime.now().toIso8601String().split('T')[0];

    if (lastPlayed == today) {
      _showError(
        "You already played the $category quiz today! Come back tomorrow.",
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      final url = Uri.parse(
        '$baseUrl/api/news/quiz/category?category=$category',
      );
      final response = await http.get(url);

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final List<dynamic> quizData = json.decode(response.body);
        final List<QuizQuestion> questions = quizData
            .map((q) => QuizQuestion.fromJson(q))
            .toList();

        if (questions.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  QuizScreen(questions: questions, quizId: category),
            ),
          );
        }
      } else {
        _showError(
          "No quiz ready for $category yet. Try generating news first!",
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError("Connection error: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showCategoryOptions(BuildContext context, String category) {
    const primaryOrange = Colors.orange;
    const darkText = Color(0xFF2D2D2D);
    const bodyText = Color(0xFF4B5563);
    const dialogBg = Color(0xFFFFF9E5);

    IconData categoryIcon;
    switch (category) {
      case "Technology":
        categoryIcon = Icons.rocket_launch_rounded;
        break;
      case "Business":
        categoryIcon = Icons.business_center_rounded;
        break;
      case "Science":
        categoryIcon = Icons.science_rounded;
        break;
      case "Politics":
        categoryIcon = Icons.account_balance_rounded;
        break;
      case "Sports":
        categoryIcon = Icons.sports_soccer_rounded;
        break;
      default:
        categoryIcon = Icons.explore_rounded;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: dialogBg,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(categoryIcon, size: 40, color: primaryOrange),
              ),
              const SizedBox(height: 20),
              Text(
                "$category Hub",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Choose your path to knowledge:",
                style: GoogleFonts.poppins(fontSize: 16, color: bodyText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              _buildAestheticButton(
                context,
                icon: Icons.article_outlined,
                label: "Read News",
                color: primaryOrange,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HomeScreen(categoryFilter: category),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildAestheticButton(
                context,
                icon: Icons.psychology_alt,
                label: "Take Quiz (+XP)",
                color: const Color.fromARGB(255, 255, 178, 115),
                hasShadow: true,
                onPressed: () {
                  Navigator.pop(context);
                  _fetchAndStartQuiz(category);
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Maybe Later",
                  style: GoogleFonts.poppins(
                    color: bodyText.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAestheticButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool hasShadow = false,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white, size: 26),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: hasShadow ? 0 : 5,
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5),
      bottomNavigationBar: _buildBottomNavBar(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    "Categories",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                itemCount: categories.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) =>
                    _buildCategoryCard(context, categories[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Map<String, dynamic> category,
  ) {
    return GestureDetector(
      onTap: () => _showCategoryOptions(context, category['name']),
      child: Container(
        height: 120,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: category['color'],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 180,
              // ✅ UPDATED: Use AssetImage instead of NetworkImage
              child: Image.asset(
                category['image'],
                fit: BoxFit.cover,
                // Removed errorBuilder since assets are guaranteed to exist
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    category['color'],
                    category['color'],
                    category['color'].withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 30.0),
                child: Text(
                  category['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 90,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF9E5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(
            Icons.home_outlined,
            "Home",
            false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LandingPage()),
            ),
          ),
          _navItem(Icons.explore, "Explore", true, onTap: () {}),
          _navItem(
            Icons.leaderboard_outlined,
            "Rank",
            false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LeaderboardScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool isSelected, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
}

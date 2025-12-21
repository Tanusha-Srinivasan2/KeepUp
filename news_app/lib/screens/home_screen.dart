import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import 'daily_quiz_screen.dart';
import 'category_list_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> categories = [
    {'name': 'Tech', 'color': Color(0xFF4CC9F0), 'icon': Icons.computer},
    {'name': 'Business', 'color': Color(0xFF4361EE), 'icon': Icons.trending_up},
    {'name': 'Science', 'color': Color(0xFF7209B7), 'icon': Icons.science},
    {
      'name': 'Health',
      'color': Color(0xFFF72585),
      'icon': Icons.health_and_safety,
    },
    {
      'name': 'Sports',
      'color': Color(0xFFF6AA1C),
      'icon': Icons.sports_basketball,
    },
    {'name': 'Movies', 'color': Color(0xFF1DD3B0), 'icon': Icons.movie},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(
          "News Quest",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. DAILY QUIZ BANNER
          GestureDetector(
            onTap: () {
              Provider.of<NewsProvider>(context, listen: false).loadDailyQuiz();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DailyQuizScreen()),
              );
            },
            child: Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE94560), Color(0xFFD63447)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 15),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.white, size: 40),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Daily Challenge",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "3 Questions • Top Stories",
                        style: GoogleFonts.roboto(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. CATEGORY GRID
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.2,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return GestureDetector(
                  onTap: () {
                    Provider.of<NewsProvider>(
                      context,
                      listen: false,
                    ).loadCategoryNews(cat['name']);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CategoryListScreen(categoryName: cat['name']),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cat['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cat['color'], width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(cat['icon'], color: cat['color'], size: 35),
                        SizedBox(height: 10),
                        Text(
                          cat['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

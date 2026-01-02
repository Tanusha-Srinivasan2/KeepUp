import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  // Data for the cards
  final List<Map<String, dynamic>> categories = const [
    {
      "name": "Technology",
      "image":
          "https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=1000&auto=format&fit=crop",
      "color": Color(0xFFFFF9C4),
    },
    {
      "name": "Business",
      "image":
          "https://images.unsplash.com/photo-1460925895917-afdab827c52f?q=80&w=1000&auto=format&fit=crop",
      "color": Color(0xFFFFE082),
    },
    {
      "name": "Science",
      "image":
          "https://images.unsplash.com/photo-1532094349884-543bc11b234d?q=80&w=1000&auto=format&fit=crop",
      "color": Color(0xFFFFCC80),
    },
    {
      "name": "Politics",
      "image":
          "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=1000&auto=format&fit=crop",
      "color": Color(0xFFFFB74D),
    },
    {
      "name": "Sports",
      "image":
          "https://images.unsplash.com/photo-1546519638-68e109498ffc?q=80&w=1000&auto=format&fit=crop",
      "color": Color(0xFFFFA726),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5), // Light Cream Background
      // ✅ AESTHETIC NAV BAR (Visual Only)
      bottomNavigationBar: _buildBottomNavBar(),

      body: SafeArea(
        child: Column(
          children: [
            // 1. Header
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
                        color: Color(0xFF2D2D2D),
                        size: 18,
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

            // 2. List of Category Cards
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                itemCount: categories.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildCategoryCard(context, categories[index]);
                },
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(categoryFilter: category['name']),
          ),
        );
      },
      child: Container(
        height: 120,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25), // More rounded
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
              child: Image.network(
                category['image'],
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(color: Colors.grey),
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

  // ✅ UPDATED NAV BAR
  Widget _buildBottomNavBar() {
    return Container(
      height: 90,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF9E5), // Matches Scaffold Background seamlessly
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.home_outlined, "Home", false),
          _navItem(Icons.explore, "Explore", true), // Highlighted
          _navItem(Icons.leaderboard_outlined, "Rank", false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: isSelected
              ? BoxDecoration(
                  color: const Color(0xFF2D2D2D), // Dark Pill
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
    );
  }
}

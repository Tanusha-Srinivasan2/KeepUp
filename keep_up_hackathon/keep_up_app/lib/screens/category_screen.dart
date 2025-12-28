import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  // Data for the cards: Name, Image URL, and Base Color
  final List<Map<String, dynamic>> categories = const [
    {
      "name": "Technology",
      "image":
          "https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=1000&auto=format&fit=crop", // Robot/Chip
      "color": Color(0xFFFFF9C4), // Light Yellow
    },
    {
      "name": "Business",
      "image":
          "https://images.unsplash.com/photo-1460925895917-afdab827c52f?q=80&w=1000&auto=format&fit=crop", // Graphs
      "color": Color(0xFFFFE082), // Amber
    },
    {
      "name": "Science",
      "image":
          "https://images.unsplash.com/photo-1532094349884-543bc11b234d?q=80&w=1000&auto=format&fit=crop", // Lab/DNA
      "color": Color(0xFFFFCC80), // Orange tint
    },
    {
      "name": "Health",
      "image":
          "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=1000&auto=format&fit=crop", // Runner
      "color": Color(0xFFFFB74D), // Deep Orange tint
    },
    {
      "name": "Sports",
      "image":
          "https://images.unsplash.com/photo-1546519638-68e109498ffc?q=80&w=1000&auto=format&fit=crop", // Basketball
      "color": Color(0xFFFFA726), // Darker Orange
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5), // Light Cream Background
      // Custom Bottom Navigation Bar (Visual only, to match image)
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
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF4A4A4A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
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
        height: 120, // Height of the card
        clipBehavior: Clip
            .antiAlias, // Ensures image doesn't bleed out of rounded corners
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // Fallback color if image fails
          color: category['color'],
        ),
        child: Stack(
          children: [
            // LAYER 1: The Image (Aligned to the Right)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 180, // Takes up roughly half the card width
              child: Image.network(
                category['image'],
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) =>
                    Container(color: Colors.grey), // Error handling
              ),
            ),

            // LAYER 2: The Gradient Overlay (Left to Right)
            // This creates the smooth fade from the solid color to the image
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    category['color'], // Solid color on the left (behind text)
                    category['color'], // Stays solid for a bit
                    category['color'].withOpacity(
                      0.0,
                    ), // Fades to transparent over image
                  ],
                  stops: const [
                    0.0,
                    0.4,
                    1.0,
                  ], // Adjust these stops to control the fade point
                ),
              ),
            ),

            // LAYER 3: The Text
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 30.0),
                child: Text(
                  category['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333), // Dark Grey Text
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Same Bottom Bar as Home Screen for consistency
  Widget _buildBottomNavBar() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.home_outlined, "Home", false),
          _navItem(Icons.explore, "Explore", true), // Highlighted
          _navItem(Icons.person_outline, "Profile", false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: isSelected
              ? BoxDecoration(
                  color: const Color(
                    0xFF2D2D2D,
                  ), // Dark background for selected
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: Icon(icon, color: isSelected ? Colors.white : Colors.grey),
        ),
        if (!isSelected)
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
          ),
      ],
    );
  }
}

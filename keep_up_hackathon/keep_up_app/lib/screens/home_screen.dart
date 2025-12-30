import 'dart:convert';
import 'dart:ui'; // Required for the scroll fix
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Ensure this import points to your updated NewsCard model
import '../models/news_model.dart';
import '../widgets/voice_button.dart';

class HomeScreen extends StatefulWidget {
  final String? categoryFilter;

  const HomeScreen({super.key, this.categoryFilter});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<NewsCard> cards = [];
  bool isLoading = true;
  final FlutterTts flutterTts = FlutterTts();

  // 1. Categories List
  final List<String> _categories = [
    "All",
    "Technology",
    "Business",
    "Science",
    "Health",
    "Sports",
    "Politics",
    "Entertainment",
  ];

  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _handleInitialFilter();
  }

  // 2. Handle incoming category from the Category Screen
  void _handleInitialFilter() {
    if (widget.categoryFilter != null) {
      int passedIndex = _categories.indexWhere(
        (element) =>
            element.toLowerCase() == widget.categoryFilter!.toLowerCase(),
      );

      if (passedIndex != -1) {
        _selectedCategoryIndex = passedIndex;
      }
    }
    // Fetch news immediately based on selection
    fetchNews(_categories[_selectedCategoryIndex]);
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  // 3. Fetch and Filter Logic
  Future<void> fetchNews(String category) async {
    setState(() {
      isLoading = true;
    });

    // Make sure this URL is correct for your emulator (10.0.2.2 usually)
    final url = Uri.parse('http://10.0.2.2:8080/api/news/feed');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<NewsCard> allCards = data
            .map((json) => NewsCard.fromJson(json))
            .toList();

        // Database Matching: Checks if DB 'topic' contains the category name
        if (category != "All") {
          allCards = allCards.where((c) {
            return c.topic.toLowerCase().contains(category.toLowerCase());
          }).toList();
        }

        setState(() {
          cards = allCards;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print("Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching news: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5), // Cream background
      floatingActionButton: const VoiceAssistantButton(),
      bottomNavigationBar: _buildBottomNavBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            // SCROLLABLE CATEGORY TABS
            _buildCategoryTabs(),

            const SizedBox(height: 10),

            // Main Content Area
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    )
                  : cards.isEmpty
                  ? _buildEmptyState()
                  : CardSwiper(
                      // FIX: Dynamic cards count prevents "RangeError" crash
                      cardsCount: cards.length,
                      numberOfCardsDisplayed: cards.length < 3
                          ? cards.length
                          : 3,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      cardBuilder: (context, index, x, y) =>
                          _buildNewsCard(cards[index], index),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Scrollable Category Tabs with Mouse Support
  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 60,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final isSelected = index == _selectedCategoryIndex;
            return Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                  fetchNews(_categories[index]);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFDE047)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Text(
                    _categories[index],
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.black : Colors.grey,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            "No news found for ${_categories[_selectedCategoryIndex]}.",
            style: GoogleFonts.poppins(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => fetchNews(_categories[_selectedCategoryIndex]),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Refresh"),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 20,
                  color: Colors.black87,
                ),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              Text(
                "Discover",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.catching_pokemon,
              color: Colors.orange,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  // 5. Card Design with Image and Gradient Overlay
  Widget _buildNewsCard(NewsCard card, int index) {
    final List<Color> cardColors = [
      const Color(0xFFFEF08A), // Yellow
      const Color(0xFFBFDBFE), // Blue
      const Color(0xFFBBF7D0), // Green
    ];
    final cardColor = cardColors[index % cardColors.length];

    String displayTopic = card.topic.contains(',')
        ? card.topic.split(',')[0].trim()
        : card.topic;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE SECTION
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                image: DecorationImage(
                  // FIX: Use the actual image URL from the card
                  image: NetworkImage(card.imageUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    // Fallback handled by Image widget or error builder if needed
                  },
                ),
              ),
              child: Stack(
                children: [
                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Topic Tag
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        displayTopic.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TEXT CONTENT SECTION
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE (Headline)
                  Text(
                    card.title, // Use the real title now
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F1F1F),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // DESCRIPTION (Summary)
                  Text(
                    card.description, // Use the real description
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF4B5563),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ACTION BUTTONS SECTION
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            child: Row(
              children: [
                _iconWithAction(Icons.access_time, () {}),
                const SizedBox(width: 5),
                Text(
                  card.time,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ), // Show Time
                const SizedBox(width: 15),
                _iconWithAction(Icons.sentiment_satisfied_alt, () {}),
                const Spacer(),
                _iconWithAction(Icons.bookmark_border, () {}),
                const SizedBox(width: 15),
                _iconWithAction(
                  Icons.volume_up_outlined,
                  () => _speak("${card.title}. ${card.description}"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconWithAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 24, color: const Color(0xFF4B5563)),
    );
  }

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
          _navItem(Icons.explore, "Explore", true),
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
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: Icon(icon, color: isSelected ? Colors.white : Colors.grey),
        ),
        if (isSelected) const SizedBox(height: 4),
        if (!isSelected)
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
          ),
      ],
    );
  }
}

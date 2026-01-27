import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/news_model.dart';
import 'news_detail_screen.dart';
import 'chat_screen.dart';
import 'landing_page.dart';
import 'category_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? categoryFilter;

  const HomeScreen({super.key, this.categoryFilter});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<NewsCard> cards = [];
  bool isLoading = true;
  final Set<String> _savedCardIds = {};

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
  DateTime? _selectedDate;

  // ✅ API Base URL
  final String baseUrl = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();
    _handleInitialFilter();
    _fetchUserBookmarks();
  }

  // --- 1. REPORT API LOGIC ---
  Future<void> _submitReport(String contentId, String title) async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id') ?? "guest_user";

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/news/report'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "contentId": contentId,
          "reportedText": title,
          "reason": "Flagged from Home Feed",
        }),
      );
      if (response.statusCode == 200) {
        print("Report submitted for $contentId");
      }
    } catch (e) {
      print("Error reporting: $e");
    }
  }

  void _showReportDialog(BuildContext context, NewsCard card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Report Content",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Flag this content as inappropriate? We will review it.",
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitReport(card.id, card.title); // Send to Backend
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Thanks for reporting. We will investigate."),
                ),
              );
            },
            child: Text(
              "Report",
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. EXISTING HELPERS ---
  String _getAssetImage(String topic) {
    String t = topic.toLowerCase();
    if (t.contains('tech')) return 'assets/technology.png';
    if (t.contains('sport')) return 'assets/sports.png';
    if (t.contains('politic')) return 'assets/politics.png';
    if (t.contains('business') || t.contains('finance'))
      return 'assets/business.png';
    if (t.contains('science')) return 'assets/science.png';
    if (t.contains('health')) return 'assets/health.png';
    if (t.contains('entertainment') || t.contains('movie'))
      return 'assets/entertainment.png';
    return 'assets/general.png';
  }

  Future<void> _fetchUserBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId == null) return;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news/user/$userId/bookmarks'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _savedCardIds.clear();
          for (var item in data) {
            if (item is Map && item.containsKey('id'))
              _savedCardIds.add(item['id']);
          }
        });
      }
    } catch (e) {
      print("Error fetching bookmarks: $e");
    }
  }

  Future<void> _toggleBookmark(NewsCard card) async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId == null) return;

    bool isCurrentlySaved = _savedCardIds.contains(card.id);
    setState(() {
      if (isCurrentlySaved)
        _savedCardIds.remove(card.id);
      else
        _savedCardIds.add(card.id);
    });

    try {
      if (isCurrentlySaved) {
        await http.delete(
          Uri.parse('$baseUrl/api/news/user/$userId/bookmark/${card.id}'),
        );
      } else {
        await http.post(
          Uri.parse('$baseUrl/api/news/user/$userId/bookmark'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "id": card.id,
            "topic": card.topic,
            "title": card.title,
            "description": card.description,
            "imageUrl": card.imageUrl,
            "time": card.time,
            "sourceUrl": card.sourceUrl,
          }),
        );
      }
    } catch (e) {
      print("Error toggling bookmark: $e");
    }
  }

  void _handleInitialFilter() {
    if (widget.categoryFilter != null) {
      int passedIndex = _categories.indexWhere(
        (element) =>
            element.toLowerCase() == widget.categoryFilter!.toLowerCase(),
      );
      if (passedIndex != -1) _selectedCategoryIndex = passedIndex;
    }
    fetchNews(_categories[_selectedCategoryIndex]);
  }

  Future<void> fetchNews(String category) async {
    setState(() => isLoading = true);
    String fetchUrl = '$baseUrl/api/news/feed';
    if (_selectedDate != null) {
      String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      fetchUrl += "?date=$dateStr";
    }

    try {
      final response = await http.get(Uri.parse(fetchUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<NewsCard> allCards = data
            .map((json) => NewsCard.fromJson(json))
            .toList();
        if (category != "All") {
          allCards = allCards
              .where(
                (c) => c.topic.toLowerCase().contains(category.toLowerCase()),
              )
              .toList();
        }
        setState(() {
          cards = allCards;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching news: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.orange,
            colorScheme: const ColorScheme.light(primary: Colors.orange),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      fetchNews(_categories[_selectedCategoryIndex]);
    }
  }

  void _clearDateFilter() {
    setState(() => _selectedDate = null);
    fetchNews(_categories[_selectedCategoryIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5),
      floatingActionButton: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        ),
        child: Container(
          width: 75,
          height: 75,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Image.asset('assets/fox.png', fit: BoxFit.contain),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCategoryTabs(),
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    )
                  : cards.isEmpty
                  ? _buildEmptyState()
                  : CardSwiper(
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

  Widget _buildNewsCard(NewsCard card, int index) {
    final List<Color> cardColors = [
      const Color(0xFFFEF08A),
      const Color(0xFFBFDBFE),
      const Color(0xFFBBF7D0),
    ];
    final cardColor = cardColors[index % cardColors.length];
    bool isSaved = _savedCardIds.contains(card.id);
    String displayTopic = card.topic.contains(',')
        ? card.topic.split(',')[0].trim()
        : card.topic;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewsDetailScreen(newsItem: card),
        ),
      ),
      child: Container(
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
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  image: DecorationImage(
                    image: AssetImage(_getAssetImage(card.topic)),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
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
                    // ✅ AI-GENERATED BADGE (Policy Compliance)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "AI-Generated",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
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
                    Text(
                      card.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF4B5563),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ✅ SOURCE ATTRIBUTION (Policy Compliance)
                    if (card.sourceName.isNotEmpty)
                      Text(
                        "Source: ${card.sourceName}",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // ✅ UPDATED FOOTER
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleBookmark(card),
                    child: Row(
                      children: [
                        Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          size: 24,
                          color: isSaved
                              ? Colors.orange
                              : const Color(0xFF4B5563),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSaved ? "Saved" : "Save",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isSaved ? Colors.orange : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // ✅ COMPLIANCE: REPORT BUTTON ADDED
                  GestureDetector(
                    onTap: () => _showReportDialog(context, card),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.flag_outlined,
                          size: 22,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Report",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NAVIGATION HELPERS ---
  Widget _buildBottomNavBar() {
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
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LandingPage()),
              (route) => false,
            ),
          ),
          _navItem(
            Icons.explore,
            "Explore",
            true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CategoryScreen()),
            ),
          ),
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

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          return Center(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategoryIndex = index);
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
                  if (Navigator.canPop(context)) Navigator.of(context).pop();
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Discover",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  if (_selectedDate != null)
                    GestureDetector(
                      onTap: _clearDateFilter,
                      child: Text(
                        "${DateFormat('MMM d').format(_selectedDate!)} (Tap to Clear)",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.calendar_today_outlined,
                  color: _selectedDate != null
                      ? Colors.orange
                      : Colors.grey[800],
                ),
                onPressed: _pickDate,
              ),
            ],
          ),
        ],
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
            _selectedDate != null
                ? "No news found for ${DateFormat('MMM d').format(_selectedDate!)}."
                : "No news found.",
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
}

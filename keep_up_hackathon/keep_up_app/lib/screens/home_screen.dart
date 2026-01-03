import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';

import '../models/news_model.dart';
import 'news_detail_screen.dart';
import 'ai_response_screen.dart';
import 'landing_page.dart'; // ✅ Imports LandingPage
import 'category_screen.dart'; // ✅ Imports CategoryScreen
import 'leaderboard_screen.dart'; // ✅ Imports LeaderboardScreen

class HomeScreen extends StatefulWidget {
  final String? categoryFilter;

  const HomeScreen({super.key, this.categoryFilter});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<NewsCard> cards = [];
  bool isLoading = true;

  // Voice & Chat Variables
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isThinking = false;

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

  @override
  void initState() {
    super.initState();
    _handleInitialFilter();
  }

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
    fetchNews(_categories[_selectedCategoryIndex]);
  }

  @override
  void dispose() {
    flutterTts.stop();
    _speech.cancel();
    super.dispose();
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

  Future<void> fetchNews(String category) async {
    setState(() => isLoading = true);
    // ✅ Updated to use HTTPS
    String baseUrl =
        'https://amalia-trancelike-beulah.ngrok-free.dev/api/news/feed';

    if (_selectedDate != null) {
      String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      baseUrl += "?date=$dateStr";
    }

    try {
      final response = await http.get(Uri.parse(baseUrl));
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
      print("Fetch Error: $e");
      setState(() => isLoading = false);
    }
  }

  void _showChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChatSheet(),
    );
  }

  Widget _buildChatSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: 400,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/fox.png', width: 40, height: 40),
                      const SizedBox(width: 10),
                      Text(
                        "Ask me anything!",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Center(
                  child: _isThinking
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Thinking...",
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          ],
                        )
                      : Text(
                          "Tap the mic to start listening.\nTap again to stop.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  if (_isListening) {
                    setModalState(() => _isListening = false);
                    _speech.stop();
                    return;
                  }
                  bool available = await _speech.initialize();
                  if (available) {
                    setModalState(() => _isListening = true);
                    _speech.listen(
                      onResult: (val) async {
                        if (val.finalResult) {
                          setModalState(() {
                            _isListening = false;
                            _isThinking = true;
                          });
                          await _askAI(val.recognizedWords);
                        }
                      },
                    );
                  }
                },
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: _isListening ? Colors.red : Colors.orange,
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _askAI(String question) async {
    String contextInfo =
        "Context: Browsing ${_categories[_selectedCategoryIndex]} news.";
    final url = Uri.https(
      'amalia-trancelike-beulah.ngrok-free.dev',
      '/api/news/chat',
      {'question': "$contextInfo Question: $question"},
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AiResponseScreen(text: response.body),
          ),
        );
      } else {
        await flutterTts.speak("Sorry, the server is having trouble.");
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      await flutterTts.speak("I can't reach the server right now.");
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _saveBookmark(NewsCard card) async {
    setState(() => _savedCardIds.add(card.id));
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId == null) return;
    final url = Uri.parse(
      'https://amalia-trancelike-beulah.ngrok-free.dev/api/news/user/$userId/bookmark',
    );
    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": card.id,
          "topic": card.topic,
          "title": card.title,
          "description": card.description,
          "imageUrl": card.imageUrl,
          "time": card.time,
        }),
      );
    } catch (e) {
      print("Error saving bookmark: $e");
    }
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5),

      floatingActionButton: GestureDetector(
        onTap: _showChatModal,
        child: Container(
          width: 75,
          height: 75,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Image.asset('assets/fox.png', fit: BoxFit.contain),
        ),
      ),

      // ✅ UPDATED NAV BAR
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

  // ✅ NAV BAR FUNCTION
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
          // Home Icon -> Navigates to LandingPage (Not selected)
          _navItem(
            Icons.home_outlined,
            "Home",
            false,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LandingPage()),
                (route) => false,
              );
            },
          ),

          // Explore Icon -> Selected (We are "in" explore)
          // Tapping it takes you back to Category List
          _navItem(
            Icons.explore,
            "Explore",
            true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryScreen()),
              );
            },
          ),

          // Rank Icon -> Navigates to Leaderboard
          _navItem(
            Icons.leaderboard_outlined,
            "Rank",
            false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaderboardScreen(),
                ),
              );
            },
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
                    color: const Color(0xFF2D2D2D), // Dark Pill for Explore
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

  Widget _buildNewsCard(NewsCard card, int index) {
    final List<Color> cardColors = [
      const Color(0xFFFEF08A),
      const Color(0xFFBFDBFE),
      const Color(0xFFBBF7D0),
    ];
    final cardColor = cardColors[index % cardColors.length];
    String displayTopic = card.topic.contains(',')
        ? card.topic.split(',')[0].trim()
        : card.topic;
    bool isSaved = _savedCardIds.contains(card.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailScreen(newsItem: card),
          ),
        );
      },
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
                    image: NetworkImage(card.imageUrl),
                    fit: BoxFit.cover,
                    onError: (e, s) {},
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
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: Row(
                children: [
                  _iconWithAction(
                    Icons.access_time,
                    const Color(0xFF4B5563),
                    () {},
                  ),
                  const SizedBox(width: 5),
                  Text(
                    card.time,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 15),
                  _iconWithAction(
                    Icons.sentiment_satisfied_alt,
                    const Color(0xFF4B5563),
                    () {},
                  ),
                  const Spacer(),
                  _iconWithAction(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    isSaved ? Colors.orange : const Color(0xFF4B5563),
                    () => _saveBookmark(card),
                  ),
                  const SizedBox(width: 15),
                  _iconWithAction(
                    Icons.volume_up_outlined,
                    const Color(0xFF4B5563),
                    () => _speak("${card.title}. ${card.description}"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconWithAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 24, color: color),
    );
  }
}

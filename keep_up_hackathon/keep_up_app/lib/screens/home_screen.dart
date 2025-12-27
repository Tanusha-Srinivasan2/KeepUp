import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/news_model.dart';
import '../widgets/voice_button.dart'; // <--- NEW IMPORT

class HomeScreen extends StatefulWidget {
  final String? categoryFilter;

  const HomeScreen({super.key, this.categoryFilter});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<NewsCard> cards = [];
  bool isLoading = true;
  final FlutterTts flutterTts = FlutterTts(); // TTS for reading cards

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  // Speak function for the Card content only
  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Future<void> fetchNews() async {
    final url = Uri.parse('http://10.0.2.2:8080/api/news/feed');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<NewsCard> allCards = data
            .map((json) => NewsCard.fromJson(json))
            .toList();

        // Filter by Category if one was selected
        if (widget.categoryFilter != null) {
          allCards = allCards
              .where(
                (c) => c.topic.toLowerCase().contains(
                  widget.categoryFilter!.toLowerCase(),
                ),
              )
              .toList();
        }

        setState(() {
          cards = allCards;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // GLOBAL VOICE ASSISTANT BUTTON (Replaces old mic logic)
      floatingActionButton: const VoiceAssistantButton(),

      appBar: AppBar(
        title: Text(
          widget.categoryFilter ?? "News Feed",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            )
          : cards.isEmpty
          ? const Center(
              child: Text(
                "No news found.",
                style: TextStyle(color: Colors.white),
              ),
            )
          : CardSwiper(
              cardsCount: cards.length,
              cardBuilder: (context, index, x, y) =>
                  _buildNewsCard(cards[index]),
            ),
    );
  }

  Widget _buildNewsCard(NewsCard card) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E676), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.topic.toUpperCase(),
              style: GoogleFonts.poppins(
                color: const Color(0xFF00E676),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              card.contentLine,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 22, color: Colors.white),
            ),
            const SizedBox(height: 30),

            // This button reads the CARD content (TTS)
            IconButton(
              onPressed: () => _speak(card.contentLine),
              icon: const Icon(Icons.volume_up, color: Colors.white, size: 40),
            ),
          ],
        ),
      ),
    );
  }
}

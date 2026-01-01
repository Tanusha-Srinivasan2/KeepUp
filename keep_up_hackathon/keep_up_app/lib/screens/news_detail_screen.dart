import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/news_model.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsCard newsItem;

  const NewsDetailScreen({super.key, required this.newsItem});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  // To show loading state during AI response
  bool _isThinking = false;

  @override
  void dispose() {
    flutterTts.stop();
    _speech.cancel();
    super.dispose();
  }

  // 1. OPEN CHAT MODAL (The Fox's Brain)
  void _showChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChatSheet(),
    );
  }

  // 2. THE CHAT SHEET UI
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/fox.png', width: 40, height: 40),
                      const SizedBox(width: 10),
                      Text(
                        "Ask me about this!",
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

              // Response Area
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
                          "Tap the mic to ask a question about this news article.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                ),
              ),

              // Mic Button inside Modal
              GestureDetector(
                onTapDown: (_) async {
                  // START LISTENING
                  bool available = await _speech.initialize();
                  if (available) {
                    setModalState(() => _isListening = true);
                    _speech.listen(
                      onResult: (val) async {
                        if (val.hasConfidenceRating && val.confidence > 0) {
                          // When speech is done, send to AI
                          if (val.finalResult) {
                            setModalState(() {
                              _isListening = false;
                              _isThinking = true;
                            });
                            await _askAI(val.recognizedWords, context);
                            // Close modal after answering (optional, or keep open to read text)
                            Navigator.pop(context);
                          }
                        }
                      },
                    );
                  }
                },
                onTapUp: (_) {
                  setModalState(() => _isListening = false);
                  _speech.stop();
                },
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: _isListening ? Colors.red : Colors.orange,
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isListening ? "Listening..." : "Hold to Speak",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. SEND QUESTION TO BACKEND (Context Aware)
  Future<void> _askAI(String question, BuildContext modalContext) async {
    // Construct context from the current article
    String contextString =
        "Title: ${widget.newsItem.title}. Content: ${widget.newsItem.description}";

    // Use your existing Chat Endpoint, passing the article context manually if needed
    // Or just ask the general chat endpoint if it's smart enough
    final url = Uri.parse(
      'http://10.0.2.2:8080/api/news/chat?question=$question',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        String answer = response.body;
        // Speak the answer
        await flutterTts.speak(answer);
      }
    } catch (e) {
      print("AI Error: $e");
      await flutterTts.speak("Sorry, I couldn't connect to the brain.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5), // Cream Background
      // ✅ FOX FLOATING ACTION BUTTON
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: _showChatModal,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Image.asset('assets/fox.png', fit: BoxFit.contain),
        ),
      ),

      body: CustomScrollView(
        slivers: [
          // 1. Image Header
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFFFF9E5),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.newsItem.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Container(color: Colors.grey[300]),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Content Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Topic & Date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.newsItem.topic.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.newsItem.time,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Headline
                  Text(
                    widget.newsItem.title,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text(
                    widget.newsItem.description,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

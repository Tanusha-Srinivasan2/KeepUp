import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/catchup_model.dart';
import '../widgets/voice_button.dart';

class CatchUpScreen extends StatefulWidget {
  const CatchUpScreen({super.key});

  @override
  State<CatchUpScreen> createState() => _CatchUpScreenState();
}

class _CatchUpScreenState extends State<CatchUpScreen> {
  List<CatchUpItem> items = [];
  bool isLoading = true;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    fetchCatchUp();
  }

  Future<void> fetchCatchUp() async {
    try {
      final url = Uri.parse('http://10.0.2.2:8080/api/news/catchup?region=US');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          items = data.map((e) => CatchUpItem.fromJson(e)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: const VoiceAssistantButton(),
      appBar: AppBar(
        title: Text(
          "Quick Catch Up",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[800]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.timeAgo.toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF00E676),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.volume_up,
                              color: Colors.grey,
                            ),
                            onPressed: () =>
                                _speak("${item.headline}. ${item.summary}"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.headline,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.summary,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

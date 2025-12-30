import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/catchup_model.dart';

class CatchUpScreen extends StatefulWidget {
  const CatchUpScreen({super.key});

  @override
  State<CatchUpScreen> createState() => _CatchUpScreenState();
}

class _CatchUpScreenState extends State<CatchUpScreen> {
  List<CatchUpItem> items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCatchUp();
  }

  Future<void> fetchCatchUp() async {
    try {
      // Use correct IP for emulator vs real device
      final url = Uri.parse('http://10.0.2.2:8080/api/news/catchup?region=US');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          items = data.map((e) => CatchUpItem.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5), // Light cream background
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFDE047)),
              )
            : Column(
                children: [
                  _buildHeaderSection(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return _buildCatchUpCard(items[index]);
                      },
                    ),
                  ),
                  _buildBottomButton(),
                ],
              ),
      ),
    );
  }

  // Header with Back Button, Title, Mascot, and Calendar
  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 24,
                ),
              ),
              Text(
                "Catch Up!",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Mascot & Calendar Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ CHANGE MADE HERE: Using your local asset fox
              Image.asset('assets/fox.png', height: 120, fit: BoxFit.contain),
              const SizedBox(width: 30),
              // Calendar Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 100,
                    color: Colors.grey,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 18.0),
                    child: Text(
                      "${DateTime.now().day}", // Current Day
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 30),
          Text(
            "Here's what you missed:",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // The new, more readable card design
  Widget _buildCatchUpCard(CatchUpItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24), // Increased padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic Tag & Date Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getTopicColor(item.topic).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.topic.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getTopicColor(item.topic),
                  ),
                ),
              ),
              Text(
                item.date,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Headline (Larger & Darker)
          Text(
            item.headline,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),

          // Summary (Darker, No Cutoff)
          Text(
            item.summary,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.grey[800], // Darker grey for better readability
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // The main action button at the bottom
  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFDE047), // Bright Yellow
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            "VIEW FULL NEWS FEED",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Helper to pick a color based on topic
  Color _getTopicColor(String topic) {
    switch (topic.toLowerCase()) {
      case 'science':
        return Colors.blue;
      case 'business':
        return Colors.green;
      case 'sports':
        return Colors.orange;
      case 'technology':
        return Colors.purple;
      case 'politics':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

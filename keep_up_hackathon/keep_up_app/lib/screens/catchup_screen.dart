import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class CatchUpScreen extends StatefulWidget {
  const CatchUpScreen({super.key});

  @override
  State<CatchUpScreen> createState() => _CatchUpScreenState();
}

class _CatchUpScreenState extends State<CatchUpScreen> {
  List<dynamic> weeklySummaries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCatchUp();
  }

  Future<void> fetchCatchUp() async {
    final url = Uri.parse('http://10.0.2.2:8080/api/news/catchup');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          weeklySummaries = json.decode(response.body);
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
      // ✅ 1. THEME BACKGROUND (Cream)
      backgroundColor: const Color(0xFFFFF9E5),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Your Daily Recap",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ✅ 2. THEME LOADER (Orange)
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : weeklySummaries.isEmpty
          ? Center(
              child: Text(
                "No summaries available yet.",
                style: GoogleFonts.poppins(color: Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: weeklySummaries.length,
              itemBuilder: (context, index) {
                return _buildDayBox(weeklySummaries[index]);
              },
            ),
    );
  }

  Widget _buildDayBox(Map<String, dynamic> dayData) {
    String dateStr = dayData['date'];
    List<dynamic> summaries = dayData['summary'];

    DateTime date = DateTime.parse(dateStr);
    String formattedDate = DateFormat('EEEE, MMM d').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // ✅ 3. SUBTLE SHADOW
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  // ✅ 4. HEADER ICON BG (Light Orange)
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today,
                  // ✅ 5. ICON COLOR (Orange)
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formattedDate,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  // ✅ 6. HEADER TEXT (Dark Grey/Black)
                  color: const Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          ...summaries.map((item) => _buildSummaryItem(item)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 12),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              // ✅ 7. BULLET POINT (Orange)
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? "News",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['description'] ?? "",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF4B5563), // Cool Grey
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

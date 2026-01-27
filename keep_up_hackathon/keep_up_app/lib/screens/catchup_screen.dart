import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/subscription_service.dart';
import 'subscription_screen.dart';

class CatchUpScreen extends StatefulWidget {
  const CatchUpScreen({super.key});

  @override
  State<CatchUpScreen> createState() => _CatchUpScreenState();
}

class _CatchUpScreenState extends State<CatchUpScreen> {
  List<dynamic> weeklySummaries = [];
  bool isLoading = true;
  final String baseUrl = "http://10.0.2.2:8080";
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isPremium = false;
  bool _checkingPremium = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    await _subscriptionService.initialize();
    final isPremium = await _subscriptionService.isPremium();
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _checkingPremium = false;
      });
      if (_isPremium) {
        fetchCatchUp();
      }
    }
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

      // ✅ FEATURE GATING: Show paywall for free users
      body: _checkingPremium
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : (!_isPremium ? _buildPaywall() : _buildContent()),
    );
  }

  // ✅ Premium-only paywall
  Widget _buildPaywall() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, size: 60, color: Colors.orange),
            ),
            const SizedBox(height: 25),
            Text(
              "Premium Feature",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Unlock daily AI-powered news summaries!",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  ).then((_) => _checkPremiumStatus());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  "Upgrade to Premium",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return isLoading
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
          );
  }

  // --- REPORT API LOGIC ---
  Future<void> _submitReport(String title, String description) async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id') ?? "guest_user";

    try {
      await http.post(
        Uri.parse('$baseUrl/api/news/report'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "contentId": "catchup_summary",
          "reportedText": "$title: $description",
          "reason": "Flagged from Catch-Up Screen",
        }),
      );
    } catch (e) {
      print("Error reporting: $e");
    }
  }

  void _showReportDialog(String title, String description) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Report Summary",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Flag this AI summary as inaccurate or inappropriate?",
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
              _submitReport(title, description);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Summary reported. Thank you!")),
              );
            },
            child: Text(
              "Report",
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
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
              Expanded(
                child: Text(
                  formattedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    // ✅ 6. HEADER TEXT (Dark Grey/Black)
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
              ),
              // ✅ AI-GENERATED BADGE (Policy Compliance)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: Colors.purple[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "AI Summary",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.purple[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
    String title = item['title'] ?? "News";
    String description = item['description'] ?? "";

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
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF4B5563), // Cool Grey
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                // ✅ REPORT BUTTON (Policy Compliance)
                GestureDetector(
                  onTap: () => _showReportDialog(title, description),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Report",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
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
    );
  }
}

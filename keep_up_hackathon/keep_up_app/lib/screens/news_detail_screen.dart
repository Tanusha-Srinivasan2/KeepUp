import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';


import '../models/news_model.dart';
import 'chat_screen.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsCard newsItem;
  const NewsDetailScreen({super.key, required this.newsItem});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final String baseUrl = ApiConfig.baseUrl;

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

  Future<void> _launchSource() async {
    final Uri url = Uri.parse(widget.newsItem.sourceUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Could not open link")));
    }
  }

  void _openAgent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          initialContext:
              "User is reading article: '${widget.newsItem.title}'. Summary: '${widget.newsItem.description}'",
        ),
      ),
    );
  }

  // --- REPORT API LOGIC ---
  Future<void> _submitReport() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id') ?? "guest_user";

    try {
      await http.post(
        Uri.parse('$baseUrl/api/news/report'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "contentId": widget.newsItem.id,
          "reportedText": widget.newsItem.title,
          "reason": "Flagged from Detail Screen",
        }),
      );
    } catch (e) {
      print("Error reporting: $e");
    }
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Report Article",
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
              _submitReport(); // CALL API
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Article reported.")),
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

  // --- BIAS METER UI ---
  Widget _buildBiasMeter(String rating, String explanation) {
    Color getBiasColor(String r) {
      String rating = r.toLowerCase();
      if (rating == 'left' || rating == 'center left' || rating == 'center-left' || rating == 'lean left') return Colors.blue;
      if (rating == 'right' || rating == 'center right' || rating == 'center-right' || rating == 'lean right') return Colors.red;
      return Colors.purple; // Center
    }

    double getPointerAlignment(String r) {
      String rating = r.toLowerCase();
      if (rating == 'left') return -1.0;
      if (rating == 'center left' || rating == 'center-left' || rating == 'lean left') return -0.5;
      if (rating == 'right') return 1.0;
      if (rating == 'center right' || rating == 'center-right' || rating == 'lean right') return 0.5;
      return 0.0; // Center
    }

    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.balance, color: getBiasColor(rating), size: 18),
              const SizedBox(width: 8),
              Text(
                "Political Bias Analysis",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Spectrum Bar
          SizedBox(
            height: 14,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.purple, Colors.red],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(getPointerAlignment(rating), 0),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Align(alignment: Alignment.centerLeft, child: Text("Left", style: GoogleFonts.poppins(fontSize: 10, color: Colors.blue)))),
              Expanded(child: Align(alignment: Alignment.center, child: Text("Center", style: GoogleFonts.poppins(fontSize: 10, color: Colors.purple)))),
              Expanded(child: Align(alignment: Alignment.centerRight, child: Text("Right", style: GoogleFonts.poppins(fontSize: 10, color: Colors.red)))),
            ],
          ),
          const Divider(height: 20),
          Text(
            "Transparency (Why?):",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            explanation,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black87,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // --- CONTEXTUAL POPUP ---
  void _showBiasWarning(BuildContext context) {
    if (widget.newsItem.biasRating.toLowerCase() != 'center') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange.shade900,
            duration: const Duration(seconds: 5),
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "This is a ${widget.newsItem.biasRating}-leaning source. We recommend comparing with neutral sources like Reuters or AP.",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _showBiasWarning(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5),
      body: CustomScrollView(
        slivers: [
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
            // ✅ REPORT BUTTON IN APP BAR ACTIONS
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.flag_outlined,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                  onPressed: () => _showReportDialog(context),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _getAssetImage(widget.newsItem.topic),
                    fit: BoxFit.cover,
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      const SizedBox(width: 8),
                      // ✅ AI-GENERATED BADGE (Policy Compliance)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
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
                              "AI Summary",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _openAgent,
                        child: Image.asset(
                          'assets/fox.png',
                          width: 65,
                          height: 65,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.newsItem.title,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D2D2D),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.newsItem.description,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // ✅ SOURCE ATTRIBUTION (Policy Compliance)
                  if (widget.newsItem.sourceName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        children: [
                          Icon(
                            Icons.source_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Source: ${widget.newsItem.sourceName}",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Bias Meter UI
                  _buildBiasMeter(widget.newsItem.biasRating, widget.newsItem.biasExplanation),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _launchSource,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D2D2D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Read Full Story",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.open_in_new, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ✅ AI DISCLAIMER (Policy Compliance)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "This summary was AI-generated. Verify with original source.",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

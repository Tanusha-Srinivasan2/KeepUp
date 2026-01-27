import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/subscription_service.dart';
import 'subscription_screen.dart';

class ChatScreen extends StatefulWidget {
  final String? initialContext;
  const ChatScreen({super.key, this.initialContext});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final String baseUrl = "http://10.0.2.2:8080";
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isPremium = false;
  bool _checkingPremium = true;

  // Example dummy data for UI testing. Replace with your real Provider/State Logic.
  final List<Map<String, dynamic>> _messages = [
    {
      "isUser": false,
      "text": "Hi! I'm your News Fox. Ask me anything about today's stories!",
    },
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    if (widget.initialContext != null) {
      _messages.add({
        "isUser": true,
        "text": "Context: ${widget.initialContext}",
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted)
          setState(() {
            _messages.add({
              "isUser": false,
              "text":
                  "I see you're reading about that! What specific questions do you have?",
            });
          });
      });
    }
  }

  Future<void> _checkPremiumStatus() async {
    await _subscriptionService.initialize();
    final isPremium = await _subscriptionService.isPremium();
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _checkingPremium = false;
      });
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add({"isUser": true, "text": _controller.text});
      _isLoading = true;
    });
    _controller.clear();

    // SIMULATE AI RESPONSE (Replace with actual backend call)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted)
        setState(() {
          _messages.add({
            "isUser": false,
            "text": "That's an interesting point! Based on the news,...",
          });
          _isLoading = false;
        });
    });
  }

  // --- REPORT API LOGIC ---
  Future<void> _submitChatReport(String text) async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id') ?? "guest_user";

    try {
      await http.post(
        Uri.parse('$baseUrl/api/news/report'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "contentId": "chat_message",
          "reportedText": text,
          "reason": "Flagged from Chat",
        }),
      );
    } catch (e) {
      print("Chat report error: $e");
    }
  }

  void _reportMessage(int index) {
    String msgText = _messages[index]['text'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Report Response",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: const Text("Is this AI response offensive?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitChatReport(msgText); // API Call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Response reported.")),
              );
            },
            child: const Text("Report", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Chat with Fox",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      // ✅ FEATURE GATING: Show paywall for free users
      body: _checkingPremium
          ? const Center(child: CircularProgressIndicator())
          : (!_isPremium ? _buildPaywall() : _buildChatInterface()),
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
              "Unlock the AI Chatbot to ask questions about any news story!",
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

  // Chat interface for premium users
  Widget _buildChatInterface() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return _buildMessageBubble(msg['text'], msg['isUser'], index);
            },
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(color: Colors.orange),
          ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildMessageBubble(String text, bool isUser, int index) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // ✅ AI LABEL FOR AI MESSAGES (Policy Compliance)
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 5, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: Colors.purple[400]),
                  const SizedBox(width: 4),
                  Text(
                    "AI-Generated",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.purple[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isUser ? Colors.orange : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                bottomRight: isUser ? Radius.zero : const Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
              ],
            ),
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
          ),
          // ✅ REPORT BUTTON FOR AI MESSAGES
          if (!isUser)
            GestureDetector(
              onTap: () => _reportMessage(index),
              child: Padding(
                padding: const EdgeInsets.only(left: 5, bottom: 10),
                child: Text(
                  "Report this response",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Ask about the news...",
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.orange,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

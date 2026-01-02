import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AiResponseScreen extends StatefulWidget {
  final String text;

  const AiResponseScreen({super.key, required this.text});

  @override
  State<AiResponseScreen> createState() => _AiResponseScreenState();
}

class _AiResponseScreenState extends State<AiResponseScreen> {
  // ✅ FIX: Removed 'static' to prevent stale connections
  final FlutterTts flutterTts = FlutterTts();
  bool _hasSpoken = false;

  @override
  void initState() {
    super.initState();
    _initAndSpeak();
  }

  Future<void> _initAndSpeak() async {
    // 1. Give the emulator a moment to breathe
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      _speakWithRetry();
    }
  }

  Future<void> _speakWithRetry() async {
    if (widget.text.isEmpty) return;

    // Retry up to 3 times
    for (int i = 1; i <= 3; i++) {
      if (!mounted) return;

      try {
        print("🦊 TTS: Attempt $i - Setting up...");

        // ✅ FIX: Re-configure the engine RIGHT BEFORE speaking
        await flutterTts.setLanguage("en-US");
        await flutterTts.setPitch(1.0);
        await flutterTts.setSpeechRate(0.5);

        // Wait for language to set
        await Future.delayed(const Duration(milliseconds: 200));

        print("🦊 TTS: Attempt $i - Speaking...");
        var result = await flutterTts.speak(widget.text);

        if (result == 1) {
          print("🦊 TTS: Success! Speaking now.");
          setState(() => _hasSpoken = true);
          return; // Exit function, success!
        } else {
          print("🦊 TTS: Speak returned 0 (Fail). Waiting...");
          // If it fails, we wait 1 second and try again
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        print("🦊 TTS Error: $e");
      }
    }
  }

  Future<void> _manualSpeak() async {
    await flutterTts.stop();
    _speakWithRetry();
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF2D2D2D), size: 30),
          onPressed: () {
            flutterTts.stop();
            Navigator.pop(context);
          },
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF59D),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.orange,
                size: 60,
              ),
            ),

            const SizedBox(height: 40),

            Text(
              "KeepUp Assistant",
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF2D2D2D),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextButton.icon(
              onPressed: _manualSpeak,
              icon: const Icon(Icons.volume_up_outlined, color: Colors.orange),
              label: Text(
                "Read Again",
                style: GoogleFonts.poppins(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

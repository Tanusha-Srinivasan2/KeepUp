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
  final FlutterTts flutterTts = FlutterTts();
  bool _isPlaying = false;

  // Audio Queue Management
  List<String> _chunks = [];
  int _currentChunkIndex = 0;

  @override
  void initState() {
    super.initState();
    _prepareAndSpeak();
  }

  void _prepareAndSpeak() {
    // 1. Safety First: Split text to prevent "Binder Transaction" crashes
    _chunks = _splitText(widget.text);

    // 2. Wake up the engine
    _initEngine();
  }

  // Helper: Splits long text into safe, speakable chunks (max 200 chars)
  List<String> _splitText(String text) {
    List<String> chunks = [];
    // Split by sentence endings (. ? !) to keep natural pauses
    RegExp sentenceSplit = RegExp(r"(?<=[.?!])\s+");

    List<String> sentences = text.split(sentenceSplit);

    String currentChunk = "";

    for (String sentence in sentences) {
      if ((currentChunk.length + sentence.length) < 200) {
        currentChunk += "$sentence ";
      } else {
        if (currentChunk.isNotEmpty) chunks.add(currentChunk.trim());
        currentChunk = "$sentence ";
      }
    }
    if (currentChunk.isNotEmpty) chunks.add(currentChunk.trim());

    return chunks;
  }

  Future<void> _initEngine() async {
    try {
      // 1. Basic Configuration
      await flutterTts.setLanguage("en-US");
      await flutterTts.setEngine(
        "com.google.android.tts",
      ); // Force Google Engine
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5);

      // 2. CRITICAL: When one chunk finishes, play the next!
      flutterTts.setCompletionHandler(() {
        _playNextChunk();
      });

      // 3. Wait for the slow emulator to bind
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        setState(() => _isPlaying = true);
        _playNextChunk();
      }
    } catch (e) {
      print("🦊 TTS Setup Error: $e");
    }
  }

  Future<void> _playNextChunk() async {
    if (!mounted) return;

    if (_currentChunkIndex < _chunks.length) {
      String textToSpeak = _chunks[_currentChunkIndex];
      print(
        "🦊 Speaking chunk ${_currentChunkIndex + 1}/${_chunks.length}: $textToSpeak",
      );

      // Retry logic for each chunk (in case connection drops)
      bool success = false;
      for (int i = 0; i < 3; i++) {
        var result = await flutterTts.speak(textToSpeak);
        if (result == 1) {
          success = true;
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (success) {
        _currentChunkIndex++;
      } else {
        print("🦊 Failed to speak chunk after 3 attempts.");
      }
    } else {
      // Done speaking everything
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  Future<void> _stopSpeaking() async {
    await flutterTts.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _currentChunkIndex = 0; // Reset for replay
      });
    }
  }

  Future<void> _replay() async {
    await _stopSpeaking();
    setState(() => _isPlaying = true);
    // Give a tiny pause before restarting
    await Future.delayed(const Duration(milliseconds: 500));
    _playNextChunk();
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
            _stopSpeaking();
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon Container
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
              child: Icon(
                _isPlaying ? Icons.graphic_eq : Icons.auto_awesome,
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

            // Text Scroll Area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  width: double.infinity,
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
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isPlaying)
                  TextButton.icon(
                    onPressed: _stopSpeaking,
                    icon: const Icon(
                      Icons.stop_circle_outlined,
                      color: Colors.red,
                    ),
                    label: Text(
                      "Stop",
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: _replay,
                    icon: const Icon(
                      Icons.volume_up_outlined,
                      color: Colors.orange,
                    ),
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
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import '../screens/ai_response_screen.dart'; // Ensure this import path is correct

class VoiceAssistantButton extends StatefulWidget {
  const VoiceAssistantButton({super.key});

  @override
  State<VoiceAssistantButton> createState() => _VoiceAssistantButtonState();
}

class _VoiceAssistantButtonState extends State<VoiceAssistantButton> {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // ---------------------------------------------------------
  // ✅ CONFIG FOR ANDROID EMULATOR
  // "10.0.2.2" is the special IP that points to your computer's localhost
  // ---------------------------------------------------------
  final String _baseUrl = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // 1. LISTEN TO VOICE
  void _listen() async {
    if (!_isListening) {
      // Initialize Microphone
      bool available = await _speech.initialize(
        onStatus: (status) => print('🎤 Mic Status: $status'),
        onError: (errorNotification) =>
            print('❌ Mic Error: $errorNotification'),
      );

      if (available) {
        setState(() => _isListening = true);

        _speech.listen(
          onResult: (val) {
            // Wait for user to finish speaking
            if (val.finalResult || val.confidence > 0.8) {
              setState(() => _isListening = false);
              _speech.stop();

              if (val.recognizedWords.isNotEmpty) {
                _askBackend(val.recognizedWords);
              }
            }
          },
        );
      } else {
        _showError("Microphone permission denied. Check Emulator settings.");
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // 2. SEND TO JAVA BACKEND
  Future<void> _askBackend(String question) async {
    // Show Loading Feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text("Asking KeepUp: '$question'...")),
          ],
        ),
        duration: const Duration(seconds: 4), // Keep visible while loading
      ),
    );

    try {
      final url = Uri.parse('$_baseUrl/api/news/chat?question=$question');
      print("🚀 LOG: Sending request to $url");

      // Timeout after 10 seconds so the app doesn't freeze
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      print("✅ LOG: Server Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        if (!mounted) return;
        // Success! Navigate to Answer Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AiResponseScreen(text: response.body),
          ),
        );
      } else {
        _showError(
          "Server Error (${response.statusCode}): Make sure your Java backend is running!",
        );
      }
    } catch (e) {
      print("❌ LOG: Connection Error: $e");
      _showError(
        "Connection Failed. \n\nCheck if your Spring Boot app is running on port 8080.",
      );
    }
  }

  // Helper to show popup alerts
  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Oops!"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _listen,
      backgroundColor: _isListening
          ? Colors.redAccent
          : const Color(0xFF00E676),
      child: Icon(
        _isListening ? Icons.mic_off : Icons.mic,
        color: Colors.white,
      ),
    );
  }
}

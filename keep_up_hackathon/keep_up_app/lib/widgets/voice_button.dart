import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import '../screens/ai_response_screen.dart';

class VoiceAssistantButton extends StatefulWidget {
  const VoiceAssistantButton({super.key});

  @override
  State<VoiceAssistantButton> createState() => _VoiceAssistantButtonState();
}

class _VoiceAssistantButtonState extends State<VoiceAssistantButton> {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // 1. LISTEN TO VOICE
  void _listen() async {
    if (!_isListening) {
      // Start Listening
      bool available = await _speech.initialize(
        onStatus: (status) => print('🎤 Mic Status: $status'),
        onError: (errorNotification) =>
            print('❌ Mic Error: $errorNotification'),
      );

      if (available) {
        setState(() => _isListening = true);

        _speech.listen(
          onResult: (val) {
            // Detect when user stops talking
            if (val.finalResult) {
              _stopListening(); // Update UI first
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
      // User tapped button to stop manually
      _stopListening();
      _speech.stop();
    }
  }

  void _stopListening() {
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  // 2. SEND TO JAVA BACKEND
  Future<void> _askBackend(String question) async {
    // Show Loading SnackBar
    if (!mounted) return;
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
        duration: const Duration(
          seconds: 2,
        ), // Short duration so it doesn't stick
      ),
    );

    try {
      // ✅ FIX: Use Uri.http to handle spaces in the question correctly
      final url = Uri.http('10.0.2.2:8080', '/api/news/chat', {
        'question': question,
      });

      print("🚀 LOG: Sending request to $url");

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
          "Server Error (${response.statusCode}): Is Spring Boot running?",
        );
      }
    } catch (e) {
      print("❌ LOG: Connection Error: $e");
      _showError(
        "Connection Failed. Check if Spring Boot is running on port 8080.",
      );
    }
  }

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
        _isListening ? Icons.stop : Icons.mic, // Changed icon for better UX
        color: Colors.white,
      ),
    );
  }
}

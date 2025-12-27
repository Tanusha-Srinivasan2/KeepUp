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

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) async {
            if (val.hasConfidenceRating && val.confidence > 0) {
              _speech.stop();
              setState(() => _isListening = false);
              _askBackend(val.recognizedWords);
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _askBackend(String question) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Asking AI: '$question'...")));
    try {
      // NOTE: Using 10.0.2.2 for Android Emulator
      final url = Uri.parse(
        'http://10.0.2.2:8080/api/news/chat?question=$question',
      );
      final response = await http.get(url);

      if (response.statusCode == 200 && mounted) {
        // Navigate to Full Screen Answer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AiResponseScreen(text: response.body),
          ),
        );
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _listen,
      backgroundColor: _isListening ? Colors.red : const Color(0xFF00E676),
      child: Icon(
        _isListening ? Icons.mic_off : Icons.mic,
        color: Colors.black,
      ),
    );
  }
}

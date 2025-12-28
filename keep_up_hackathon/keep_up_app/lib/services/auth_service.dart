import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class AuthService {
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';

  // Get current ID (or null if new)
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  // Register only if we haven't already
  static Future<void> loginOrRegister() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Check if we already exist
    if (prefs.containsKey(_keyUserId)) {
      print("Welcome back, ${prefs.getString(_keyUserName)}");
      return;
    }

    // 2. Generate New Identity
    var uuid = const Uuid();
    String newId = uuid.v4(); // Unique ID like "a1b2-c3d4..."
    String newName = "Hacker ${Random().nextInt(999)}"; // "Hacker 402"

    // 3. Save to Phone
    await prefs.setString(_keyUserId, newId);
    await prefs.setString(_keyUserName, newName);

    // 4. Send to Backend
    // NOTE: using 10.0.2.2 for emulator
    try {
      final url = Uri.parse(
        'http://10.0.2.2:8080/api/news/user/create?userId=$newId&name=$newName',
      );
      final response = await http.post(url);

      if (response.statusCode == 200) {
        print("Registered on Server: $newName");
      } else {
        print("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Connection Error: $e");
    }
  }
}

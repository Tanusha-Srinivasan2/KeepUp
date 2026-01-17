import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';

  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Returns the current User ID (email) from local storage
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Returns the current User Name from local storage
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  /// ✅ Triggers Google Sign-In and registers the user using their EMAIL as the primary ID
  static Future<bool> signInWithGoogle() async {
    try {
      // 1. Trigger the Google Sign-In selection UI
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return false; // User canceled the sign-in
      }

      // 2. EXTRACT DATA: Use .email to match your desired Firestore ID format
      String userId = googleUser.email;
      String userName = googleUser.displayName ?? "Reader";

      // 3. SAVE LOCALLY: Store session data so the app remembers who is logged in
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, userId);
      await prefs.setString(_keyUserName, userName);

      // 4. SYNC WITH BACKEND: Create the user document in Firestore via Spring Boot
      await _registerOnBackend(userId, userName);

      return true; // Success!
    } catch (error) {
      print("Google Sign-In Error: $error");
      return false;
    }
  }

  /// ✅ Helper to send user details to your Spring Boot server
  static Future<void> _registerOnBackend(String userId, String name) async {
    try {
      // Use 10.0.2.2 for Android Emulator to reach your local Spring Boot server
      final url = Uri.parse(
        'http://10.0.2.2:8080/api/news/user/create?userId=$userId&name=$name',
      );

      final response = await http.post(url);

      if (response.statusCode == 200) {
        print("✅ Backend Sync Successful for: $userId");
      } else {
        print("⚠️ Backend Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Connection Error during registration: $e");
    }
  }

  /// ✅ Logs the user out of Google and clears local data
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Wipes user_id and user_name
    await _googleSignIn.signOut();
    print("User logged out and local storage cleared.");
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../main.dart';
import 'landing_page.dart';
import 'splash_screen.dart'; // ✅ Ensures smooth transition

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      // 1. Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User canceled
      }

      // 2. Extract Details
      // ✅ Use 'id' for a unique, stable User ID (Best Practice)
      String userId = googleUser.id;
      // ✅ Use 'displayName' to get the actual name from Google
      String name = googleUser.displayName ?? "Reader";

      // 3. Register User in Backend
      // Note: We use try/catch inside here specifically for the HTTP call
      // so even if the backend is down, the user can still log in locally.
      try {
        final url = Uri.parse(
          'http://10.0.2.2:8080/api/news/user/create?userId=$userId&name=$name',
        );
        await http.post(url);
      } catch (e) {
        print("Backend sync failed (User can still login locally): $e");
      }

      // 4. Save Session Locally
      // This is CRITICAL for the Landing Page to show the correct name
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      await prefs.setString('user_name', name);

      // 5. Navigate to Splash (Celebration) Screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
    } catch (error) {
      print("Sign In Error: $error");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login Failed: $error")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset('assets/fox.png', width: 150),
              ),
              const SizedBox(height: 40),

              // App Name
              Text(
                "Keep Up",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 10),

              // Tagline
              Text(
                "Stay smart. Stay ahead.\nYour daily news companion.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.orange)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // You can add a Google G logo asset here if you have one
                            // Image.asset('assets/google_logo.png', height: 24),
                            const Icon(Icons.login, color: Colors.orange),
                            const SizedBox(width: 10),
                            Text(
                              "Continue with Google",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

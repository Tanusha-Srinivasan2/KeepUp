import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // ✅ 1. Import AdMob

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp();

  // ✅ 2. Initialize AdMob (CRITICAL FIX for MissingPluginException)
  await MobileAds.instance.initialize();

  runApp(const KeepUpApp());
}

class KeepUpApp extends StatefulWidget {
  const KeepUpApp({super.key});

  // Keep your specific colors
  static const Color primaryYellow = Color(0xFFFFD700);
  static const Color bgYellow = Color(0xFFFFF8B8);
  static const Color bgPurple = Color(0xFF2A1B3D);
  static const Color textColor = Color(0xFF2A1B3D);

  @override
  State<KeepUpApp> createState() => _KeepUpAppState();
}

class _KeepUpAppState extends State<KeepUpApp> {
  bool _isLoggedIn = false;
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // ✅ Check if user_id exists in storage
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('user_id');

    setState(() {
      _isLoggedIn = userId != null && userId.isNotEmpty;
      _checkingAuth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      // Show a simple white screen while checking auth
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: KeepUpApp.primaryYellow),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Keep Up',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFEFCE0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: KeepUpApp.primaryYellow,
          brightness: Brightness.light,
          primary: KeepUpApp.primaryYellow,
          onPrimary: KeepUpApp.textColor,
        ),
        textTheme: GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme)
            .apply(
              bodyColor: KeepUpApp.textColor,
              displayColor: KeepUpApp.textColor,
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: KeepUpApp.textColor,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: KeepUpApp.textColor),
        ),
      ),
      // ✅ Routing Logic: Login vs Home (via Splash)
      home: _isLoggedIn ? const SplashScreen() : const AuthScreen(),
    );
  }
}

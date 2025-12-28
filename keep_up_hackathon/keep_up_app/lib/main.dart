import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/landing_page.dart';
import 'services/auth_service.dart'; // <--- NEW IMPORT

void main() async {
  // <--- Changed to async
  // 1. Required for async code in main
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Register/Login the user before the app starts
  await AuthService.loginOrRegister();

  runApp(const KeepUpApp());
}

class KeepUpApp extends StatelessWidget {
  const KeepUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keep Up',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // We use a dark, sleek theme for that "News" vibe
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E676), // Hacker Green
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const LandingPage(),
    );
  }
}

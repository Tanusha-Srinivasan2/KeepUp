import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
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
      // We will create this HomeScreen next!
      home: const HomeScreen(),
    );
  }
}

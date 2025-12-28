import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart'; // Keep this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // REMOVED: await AuthService.loginOrRegister(); <--- We moved this!
  runApp(const KeepUpApp());
}

class KeepUpApp extends StatelessWidget {
  const KeepUpApp({super.key});

  static const Color primaryYellow = Color(0xFFFFD700);
  static const Color bgYellow = Color(0xFFFFF8B8);
  static const Color bgPurple = Color(0xFF2A1B3D);
  static const Color textColor = Color(0xFF2A1B3D);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keep Up',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFEFCE0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryYellow,
          brightness: Brightness.light,
          primary: primaryYellow,
          onPrimary: textColor,
        ),
        textTheme: GoogleFonts.nunitoTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: textColor, displayColor: textColor),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: textColor),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

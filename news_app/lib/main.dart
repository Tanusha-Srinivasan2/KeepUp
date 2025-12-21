import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/news_provider.dart';
import 'screens/home_screen.dart'; // Make sure this points to your new Home Screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep this if you are using Firebase features (Auth, Analytics, etc.)
  // If not, you can technically comment these two lines out, but it hurts nothing to keep them.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // CHANGE IS HERE:
        // We removed "..loadStories()"
        // We just create the provider. The HomeScreen handles the loading now.
        ChangeNotifierProvider(create: (_) => NewsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          // Optional: Make the background color match your design globally
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        ),
        home: HomeScreen(), // This is your new Dashboard
      ),
    );
  }
}

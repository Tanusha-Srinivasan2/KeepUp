import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // ✅ 1. Import AdMob
import 'package:workmanager/workmanager.dart'; // ✅ 4. Import WorkManager
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // ✅ 6. Crashlytics

// Services
import 'services/background_sync_service.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';

/// ✅ POLICY COMPLIANCE: WorkManager callback dispatcher for background tasks
/// This runs in a separate isolate, so no access to Flutter widgets
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case BackgroundSyncService.taskName:
        await BackgroundSyncService.syncNews();
        break;
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp();

  // ✅ 6. Initialize Crashlytics (Play Store Ranking - keep crash rate under 1.09%)
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // ✅ 2. Initialize AdMob (CRITICAL FIX for MissingPluginException)
  await MobileAds.instance.initialize();

  // ✅ 3. Configure AdMob for policy compliance
  // - maxAdContentRating: PG for age-appropriate ads (use 'g' for kids apps)
  // - tagForChildDirectedTreatment: 'no' for 13+ audience
  await MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      maxAdContentRating: MaxAdContentRating.pg,
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
    ),
  );

  // ✅ 4. Initialize WorkManager for background sync (Policy Compliance)
  // Uses WorkManager instead of ForegroundService per Google Play policies
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // ✅ 5. Register periodic task for daily news sync
  await Workmanager().registerPeriodicTask(
    'dailyNewsSyncTask',
    BackgroundSyncService.taskName,
    frequency: const Duration(hours: 24),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
  );

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

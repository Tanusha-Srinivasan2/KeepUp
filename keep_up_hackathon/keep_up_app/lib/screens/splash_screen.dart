import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import '../services/auth_service.dart'; // ❌ REMOVE THIS
import 'landing_page.dart'; // ✅ Change this to your Home/Landing Page

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _stage = 0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // ❌ REMOVE AuthService.loginOrRegister();
    // We are already logged in when we get here!

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        _precacheAndStart();
        _initialized = true;
      }
    });
  }

  void _precacheAndStart() {
    precacheImage(const AssetImage('assets/splash_pattern.png'), context);
    precacheImage(const AssetImage('assets/jumpfox.png'), context);
    precacheImage(const AssetImage('assets/foxlogo.png'), context);

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // STAGE 0: Show Logo
    await Future.delayed(const Duration(seconds: 1)); // Shorter wait

    // STAGE 1: Transition Background & Fox
    if (mounted) setState(() => _stage = 1);
    await Future.delayed(const Duration(milliseconds: 1500));

    // STAGE 2: "Promoted" Text
    if (mounted) setState(() => _stage = 2);
    await Future.delayed(const Duration(milliseconds: 3000));

    // FINISH: Go to the Main App!
    if (mounted) {
      Navigator.pushReplacement(
        context,
        // ✅ Navigate to HomeScreen (or LandingPage)
        MaterialPageRoute(builder: (context) => const LandingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Keep your existing build/UI code exactly the same) ...
    // It was perfect!
    return Scaffold(
      body: Stack(
        children: [
          // LAYER 1: SOLID GOLD BACKGROUND
          AnimatedOpacity(
            duration: const Duration(milliseconds: 800),
            opacity: _stage >= 1 ? 1.0 : 0.0,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                ),
              ),
            ),
          ),

          // LAYER 2: PATTERN BACKGROUND
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _stage == 0 ? 1.0 : 0.0,
            child: Container(
              color: const Color(0xFFFFE082),
              child: Image.asset(
                'assets/splash_pattern.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // LAYER 3: ANIMATED CONTENT
          SizedBox(
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // VIEW 1: APP LOGO
                AnimatedOpacity(
                  opacity: _stage == 0 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(15),
                        child: Image.asset('assets/foxlogo.png'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "KeepUp",
                        style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // VIEW 2: THE JUMPING FOX
                if (_stage >= 1)
                  AnimatedSlide(
                    offset: _stage == 2
                        ? const Offset(0, -0.2)
                        : const Offset(0, 0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutBack,
                    child: AnimatedScale(
                      scale: _stage >= 1 ? 1.3 : 0.5,
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      child: Image.asset('assets/jumpfox.png', height: 220),
                    ),
                  ),

                // VIEW 3: PROMOTED TEXT
                Positioned(
                  bottom: 150,
                  child: AnimatedOpacity(
                    opacity: _stage == 2 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      children: [
                        Text(
                          "Promoted to",
                          style: GoogleFonts.nunito(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Bronze League!",
                          style: GoogleFonts.nunito(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

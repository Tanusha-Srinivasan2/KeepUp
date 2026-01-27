import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'landing_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _showContent = false;
  bool _initialized = false;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Bounce animation for the fox
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        _precacheAndStart();
        _initialized = true;
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _precacheAndStart() {
    precacheImage(const AssetImage('assets/jumpfox.png'), context);
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Short delay then show content
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() => _showContent = true);
      _bounceController.forward();
    }

    // Wait for the animation to complete, then navigate
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Main content column
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Fox + Diamond
                  AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.5 + (_bounceAnimation.value * 0.5),
                        child: Opacity(
                          opacity: _bounceAnimation.value.clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // The jumping fox
                        Image.asset('assets/jumpfox.png', height: 280),
                        // Diamond floating above
                        Positioned(
                          top: -20,
                          right: -30,
                          child: AnimatedBuilder(
                            animation: _bounceController,
                            builder: (context, child) {
                              // Subtle floating effect for diamond
                              return Transform.translate(
                                offset: Offset(0, -10 * _bounceAnimation.value),
                                child: child,
                              );
                            },
                            child: Image.asset(
                              'assets/diamond1.png',
                              height: 60,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Welcome text
                  AnimatedOpacity(
                    opacity: _showContent ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 800),
                    child: AnimatedSlide(
                      offset: _showContent ? Offset.zero : const Offset(0, 0.5),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutBack,
                      child: Text(
                        "Welcome back!",
                        style: GoogleFonts.nunito(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

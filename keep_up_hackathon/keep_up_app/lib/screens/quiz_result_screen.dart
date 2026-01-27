import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart'; // ✅ In-App Review API

import '../services/subscription_service.dart';
import 'landing_page.dart';

class QuizResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int xpEarned;
  final VoidCallback onContinue;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.xpEarned,
    required this.onContinue,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  RewardedAd? _rewardedAd;
  bool _isRetrying = false;
  bool _isAdLoaded = false;
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isPremium = false;

  final String baseUrl = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();
    _checkPremiumAndLoadAd();
  }

  Future<void> _checkPremiumAndLoadAd() async {
    await _subscriptionService.initialize();
    final isPremium = await _subscriptionService.isPremium();
    if (mounted) {
      setState(() => _isPremium = isPremium);
      // Only load ads for free users
      if (!_isPremium) {
        _loadRewardedAd();
      }

      // ✅ Trigger In-App Review after successful quiz (when user is happy)
      if (widget.score >= (widget.totalQuestions / 2)) {
        _maybeRequestReview();
      }
    }
  }

  // ✅ In-App Review - Only prompt occasionally when user is happy
  Future<void> _maybeRequestReview() async {
    final prefs = await SharedPreferences.getInstance();
    int quizCount = prefs.getInt('successful_quiz_count') ?? 0;
    quizCount++;
    await prefs.setInt('successful_quiz_count', quizCount);

    // Only request review every 3rd successful quiz to avoid annoying users
    if (quizCount % 3 == 0) {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      }
    }
  }

  // 1. LOAD AD
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // Test ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (error) {
          print('Ad failed to load: $error');
          setState(() => _isAdLoaded = false);
        },
      ),
    );
  }

  // 2. WATCH AD OR FREE RETRY FOR PREMIUM
  Future<void> _watchAdToRetry() async {
    // ✅ PREMIUM USERS: Free retry without ads
    if (_isPremium) {
      await _unlockQuizForRetry();
      return;
    }

    // Free users must watch ad
    if (_rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ad loading... please try again.")),
      );
      _loadRewardedAd();
      return;
    }

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        // ✅ USER FINISHED AD -> UNLOCK RETRY
        await _unlockQuizForRetry();
      },
    );
  }

  // 3. ✅ THE CRITICAL FIX: Update Local SharedPrefs AND Backend
  Future<void> _unlockQuizForRetry() async {
    setState(() => _isRetrying = true);
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    // ✅ SET LOCAL PERMISSION FLAG (LandingPage looks for this)
    await prefs.setBool('retry_unlocked_Daily', true);

    if (userId != null) {
      try {
        String category = "Daily";
        final url = Uri.parse(
          '$baseUrl/api/news/user/$userId/unlock-quiz?category=$category',
        );
        await http.post(url);
      } catch (e) {
        print("Backend sync error: $e");
        // We continue anyway because local flag is already set
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔥 Bonus Try Unlocked! Click 'Start' on Home."),
          backgroundColor: Colors.green,
        ),
      );

      // Send back to Landing Page so they can start the 2nd attempt
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPerfect = widget.score == widget.totalQuestions;
    bool passed = widget.score >= (widget.totalQuestions / 2);

    String title = isPerfect
        ? "Perfect!"
        : (passed ? "Great Job!" : "Keep Trying!");
    String message = passed
        ? "You earned ${widget.xpEarned} XP today!"
        : "You didn't pass this time.";

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/fox.png', height: 180, fit: BoxFit.contain),
              const SizedBox(height: 30),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Score: ${widget.score} / ${widget.totalQuestions}",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              const SizedBox(height: 60),

              // ✅ RETRY BUTTON (Only if not a perfect score)
              if (!isPerfect)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isRetrying ? null : _watchAdToRetry,
                    icon: _isRetrying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                          ),
                    label: Text(
                      _isPremium
                          ? "Free Retry (Premium)"
                          : "Unlock Bonus Try (Watch Ad)",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 15),

              // CONTINUE BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: widget.onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D2D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    "Back to Home",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

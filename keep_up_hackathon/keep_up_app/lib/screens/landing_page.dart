import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/quiz_model.dart';
import '../services/subscription_service.dart';

// Screens
import 'category_screen.dart';
import 'leaderboard_screen.dart';
import 'quiz_screen.dart';
import 'catchup_screen.dart';
import 'bookmarks_screen.dart';
import 'auth_screen.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String username = "Reader";
  String xp = "...";
  String rank = "...";
  String streak = "...";
  bool isLoadingQuiz = false;
  int _selectedIndex = 0;

  // ✅ Ad Variables
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;

  // ✅ Premium Status
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isPremium = false;
  Map<String, String> _lastPlayed = {}; // ✅ Store backend lastPlayed data

  final String baseUrl = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
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
    }
  }

  // --- ADMOB LOGIC ---
  void _loadRewardedAd() {
    if (_isAdLoading || _isAdLoaded) return;

    setState(() => _isAdLoading = true);
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // Test ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isAdLoaded = true;
            _isAdLoading = false;
          });
        },
        onAdFailedToLoad: (error) {
          print('Ad failed to load: $error');
          setState(() {
            _isAdLoaded = false;
            _isAdLoading = false;
          });
        },
      ),
    );
  }

  void _showStreakRestoreAd(String userId) {
    // ✅ PREMIUM USERS: Free streak restore without ads
    if (_isPremium) {
      Navigator.pop(context);
      _callRestoreStreakApi(userId);
      return;
    }

    // Free users must watch ad
    if (_rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ad not ready yet. Try again in a moment."),
        ),
      );
      _loadRewardedAd();
      return;
    }

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        Navigator.pop(context);
        await _callRestoreStreakApi(userId);
      },
    );

    _rewardedAd = null;
    _isAdLoaded = false;
    _loadRewardedAd();
  }

  Future<void> _callRestoreStreakApi(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/news/user/$userId/restore-streak');
      final response = await http.post(url);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🔥 Streak Restored! Play now to keep it."),
            backgroundColor: Colors.green,
          ),
        );
        _fetchUserData();
      }
    } catch (e) {
      print("Error restoring streak: $e");
    }
  }

  // --- AUTH & DATA LOGIC ---

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    String? storedName = prefs.getString('user_name');

    if (userId == null) {
      if (mounted)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      return;
    }

    setState(() => username = storedName ?? "Reader");

    try {
      final url = Uri.parse('$baseUrl/api/news/user/$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            xp = (data['xp'] ?? 0).toString();
            rank = (data['rank'] ?? 0).toString();
            streak = (data['streak'] ?? 1).toString();
            // ✅ Parse lastPlayed map safely
            if (data['lastPlayed'] != null) {
              _lastPlayed = Map<String, String>.from(data['lastPlayed']);
            }
          });
          _checkStreakStatus(data, userId);
        }
      }
    } catch (e) {
      print("Error loading stats: $e");
    }
  }

  void _checkStreakStatus(Map<String, dynamic> data, String userId) {
    String? lastActiveStr = data['lastActiveDate'];
    if (lastActiveStr == null) return;

    try {
      DateTime lastActive = DateTime.parse(lastActiveStr);
      DateTime now = DateTime.now();

      // Normalize to date only (remove time component)
      DateTime lastDateOnly = DateTime(
        lastActive.year,
        lastActive.month,
        lastActive.day,
      );
      DateTime todayOnly = DateTime(now.year, now.month, now.day);

      // Calculate days since last active
      int daysSinceLastActive = todayOnly.difference(lastDateOnly).inDays;

      // If user hasn't played for 2+ days, their streak is broken
      // (1 day gap is okay - they played "yesterday")
      if (daysSinceLastActive >= 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showStreakLostDialog(userId);
        });
      }
    } catch (e) {
      print("Error parsing lastActiveDate: $e");
    }
  }

  void _showStreakLostDialog(String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF9E5),
        title: Row(
          children: [
            const Icon(Icons.broken_image, color: Colors.red),
            const SizedBox(width: 10),
            Text(
              "Streak Broken!",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "You missed a day! Watch a short ad to restore your streak freeze and keep your progress.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "No thanks",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showStreakRestoreAd(userId),
            icon: const Icon(Icons.play_circle_filled, color: Colors.white),
            label: Text(
              "Watch Ad",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Enforce Daily Limit + Bonus Try logic (Increasing Ad Cost)
  Future<void> _startQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().split('T')[0];

    // Reset daily retry count if it's a new day
    String? storedDate = prefs.getString('last_reset_date');
    if (storedDate != today) {
      prefs.setString('last_reset_date', today);
      prefs.setInt('daily_retry_count', 0);
      prefs.setBool('retry_unlocked_Daily', false);
    }

    // 1. Check if they already played today (using backend data)
    bool alreadyPlayed =
        _lastPlayed.containsKey("Daily") && _lastPlayed["Daily"] == today;

    // 2. Check if they have an unlocked retry from an ad
    bool hasRetryUnlocked = prefs.getBool('retry_unlocked_Daily') ?? false;

    if (alreadyPlayed && !hasRetryUnlocked) {
      int currentRetryCount = prefs.getInt('daily_retry_count') ?? 0;
      int requiredAds = currentRetryCount + 1;

      // ✅ Show dialog to watch ads for retry
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFFFFF9E5),
          title: Row(
            children: [
              const Icon(Icons.lock_clock, color: Colors.orange),
              const SizedBox(width: 10),
              Text(
                "Daily Limit Reached",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            requiredAds == 1
                ? "You've already completed today's challenge! Watch an ad to unlock one bonus attempt."
                : "Attempt #${currentRetryCount + 1}: You need to watch $requiredAds ads to unlock this attempt.",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _initiateAdWatchSequence(requiredAds);
              },
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: Text(
                "Watch Ad",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => isLoadingQuiz = true);
    try {
      final url = Uri.parse('$baseUrl/api/news/quiz');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> quizData = json.decode(response.body);

        if (quizData.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No quiz questions available right now. Please try again later.',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final List<QuizQuestion> questions = quizData
            .map((q) => QuizQuestion.fromJson(q))
            .toList();

        if (mounted) {
          // 3. Consume the retry token if it was being used
          if (hasRetryUnlocked) {
            await prefs.setBool('retry_unlocked_Daily', false);
            // Increment retry count for next time
            int currentRetry = prefs.getInt('daily_retry_count') ?? 0;
            await prefs.setInt('daily_retry_count', currentRetry + 1);
          }

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  QuizScreen(questions: questions, quizId: "Daily"),
            ),
          );
          _fetchUserData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load quiz. Status: ${response.statusCode}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Error fetching quiz: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error connecting to server. Check your internet connection.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoadingQuiz = false);
    }
  }

  // ✅ Handle multi-ad watch sequence
  void _initiateAdWatchSequence(int requiredAds) {
    if (_isPremium) {
      _unlockRetry();
      return;
    }
    _watchNextAd(1, requiredAds);
  }

  void _watchNextAd(int currentAdIndex, int totalAds) {
    if (currentAdIndex > totalAds) {
      _unlockRetry();
      return;
    }

    // Checking if ad is ready
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          // Reset ad state immediately
          _rewardedAd = null;
          _isAdLoaded = false;
          // Trigger load for NEXT ad
          _loadRewardedAd();

          // Smooth transition to next step
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _watchNextAd(currentAdIndex + 1, totalAds);
            }
          });
        },
      );
    } else {
      // Ad not ready yet - Polling Logic
      // Ensure we are trying to load
      _loadRewardedAd();

      // Update UI to show we are waiting, but only if it's been a while or first check
      // For simplicity, we just show a persistent snackbar updates
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Loading Ad $currentAdIndex of $totalAds... Please wait.",
          ),
          duration: const Duration(
            seconds: 1,
          ), // Short duration so it updates/doesn't linger too long if we succeed
        ),
      );

      // Retry after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _watchNextAd(currentAdIndex, totalAds);
        }
      });
    }
  }

  Future<void> _unlockRetry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('retry_unlocked_Daily', true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Bonus Attempt Unlocked! Tap 'Daily Challenge' to start.",
          ),
          backgroundColor: Colors.green,
        ),
      );
      _startQuiz();
    }
  }

  void _onItemTapped(int index) async {
    if (index == 1)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CategoryScreen()),
      );
    else if (index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
      );
      _fetchUserData();
    } else
      setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // ✅ SETTINGS BUTTON (Policy Compliance - AI Disclaimer access)
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF2D2D2D)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTopStat('assets/lightning.png', xp),
            _buildTopStat('assets/fire.png', streak),
            _buildTopStat('assets/gem.png', rank),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUserData,
        color: const Color(0xFF2D2D2D),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatScreen(),
                      ),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: Image.asset(
                        'assets/fox.png',
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome,",
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D2D2D),
                          ),
                        ),
                        Text(
                          username,
                          style: GoogleFonts.nunito(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: _buildMainCard(
                      context,
                      title: "Daily Challenge",
                      subtitle: "3 Questions",
                      bgColor: const Color(0xFFFFF8B8),
                      textColor: const Color(0xFF2D2D2D),
                      btnColor: Colors.orange,
                      onTap: isLoadingQuiz ? null : _startQuiz,
                      isLoading: isLoadingQuiz,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildMainCard(
                      context,
                      title: "Catch me Up",
                      subtitle: "15 Minutes",
                      bgColor: const Color(0xFF2D2D2D),
                      textColor: Colors.white,
                      btnColor: Colors.white.withOpacity(0.2),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CatchUpScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildFullWidthCard(
                context,
                title: "Explore today's top news",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildFullWidthCard(
                context,
                title: "Your Bookmarks",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookmarksScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 90,
        decoration: const BoxDecoration(
          color: Color(0xFFFFF9E5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_outlined, "Home", 0),
            _buildNavItem(Icons.explore_outlined, "Explore", 1),
            _buildNavItem(Icons.leaderboard_outlined, "Rank", 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: isSelected
                ? BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(20),
                  )
                : null,
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 26,
            ),
          ),
          if (!isSelected) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopStat(String imagePath, String value) {
    return Row(
      children: [
        Image.asset(imagePath, width: 24, height: 24),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMainCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color textColor,
    required Color btnColor,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 200,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: textColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: textColor,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      "Start",
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthCard(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8B8),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF2D2D2D),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ✅ POLICY COMPLIANCE: Background News Sync Service
/// Uses WorkManager instead of ForegroundService per Google Play policies.
///
/// This service handles:
/// - Daily news updates in the background
/// - Caching latest news for offline reading
class BackgroundSyncService {
  static const String baseUrl = "http://10.0.2.2:8080";
  static const String taskName = "dailyNewsSync";

  /// Executes background sync task - called by WorkManager
  static Future<bool> syncNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');

      if (userId == null) {
        print("⚠️ Background sync: No user logged in");
        return false;
      }

      // 1. Fetch latest news from backend
      final url = Uri.parse('$baseUrl/api/news/feed');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // 2. Cache the news for offline access
        final newsData = response.body;
        await prefs.setString('cached_news', newsData);
        await prefs.setString(
          'last_sync_time',
          DateTime.now().toIso8601String(),
        );

        print("✅ Background sync completed at ${DateTime.now()}");
        return true;
      } else {
        print("⚠️ Background sync failed: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Background sync error: $e");
      return false;
    }
  }

  /// Get cached news from local storage
  static Future<List<dynamic>?> getCachedNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cachedNews = prefs.getString('cached_news');

      if (cachedNews != null) {
        return json.decode(cachedNews) as List<dynamic>;
      }
      return null;
    } catch (e) {
      print("Error loading cached news: $e");
      return null;
    }
  }

  /// Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastSync = prefs.getString('last_sync_time');

    if (lastSync != null) {
      return DateTime.parse(lastSync);
    }
    return null;
  }
}

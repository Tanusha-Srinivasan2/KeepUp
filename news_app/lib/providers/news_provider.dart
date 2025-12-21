import 'package:flutter/material.dart';
import '../models/news_story.dart';
import '../services/ai_service.dart';

class NewsProvider with ChangeNotifier {
  List<NewsStory> _stories = [];
  bool _isLoading = false;

  List<NewsStory> get stories => _stories;
  bool get isLoading => _isLoading;

  // Load the Daily Quiz (3 items)
  Future<void> loadDailyQuiz() async {
    _isLoading = true;
    _stories = [];
    notifyListeners();
    _stories = await AiService.fetchNews('daily');
    _isLoading = false;
    notifyListeners();
  }

  // Load Category News (10 items)
  Future<void> loadCategoryNews(String category) async {
    _isLoading = true;
    _stories = [];
    notifyListeners();
    _stories = await AiService.fetchNews('category', category: category);
    _isLoading = false;
    notifyListeners();
  }
}

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/news_story.dart';

class AiService {
  static const String _apiKey = 'AIzaSyCS3NKrJcYB1YVfJUJt7bUy4yJ5CxrabmU';

  static Future<List<NewsStory>> fetchNews(
    String type, {
    String? category,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: _apiKey,
      );
      String prompt;

      if (type == 'daily') {
        // MODE A: DAILY QUIZ (3 Stories + Questions)
        prompt = '''
Role: You are the Chief Editor of a high-stakes news app. Your goal is to curate only the top 3 most impactful, verified, and actionable news formatted in a way that can be easily understood by any age group and make 1 question for each news.

Filtering Rules for the news story(The "Quality Gate"):

Impact: The story must affect at least 1 million people or move a major financial market.

Recency: Must be less than 24 hours old.

Credibility: Must be verified by at least 2 distinct major sources (e.g., Reuters, AP, Bloomberg).

No Fluff: Ignore celebrity gossip, minor sports updates, or rumors.

Output Protocol:

Search for 5 potential top stories.

Rank them internally based on the "Filtering Rules" above.

Select ONLY the top 3 stories.
          in this way, Find Top 3 global news stories right now. 
          For EACH story, generate a multiple-choice quiz question.
          Return valid JSON List. Schema:
          [{"headline": "...", "summary": "...", "sourceName": "...", "quizQuestion": {"questionText": "...", "options": ["A","B","C","D"], "correctAnswerIndex": 0}}]
        ''';
      } else {
        // MODE B: CATEGORY READER (10 Stories, NO Questions for speed)
        prompt =
            '''
Role: You are the Chief Editor of a high-stakes news app. Your goal is to curate only the top 10 most impactful, verified, and actionable news about $category formatted in a way that can be easily understood by any age group and make 1 question for each news.

Filtering Rules for the news story(The "Quality Gate"):

Impact: The story must affect at least 1 million people or move a major financial market.

Recency: Must be less than 24 hours old.

Credibility: Must be verified by at least 2 distinct major sources (e.g., Reuters, AP, Bloomberg).

No Fluff: Ignore celebrity gossip, minor sports updates, or rumors.

Output Protocol:

Search for 15 potential top stories.

Rank them internally based on the "Filtering Rules" above.

Select ONLY the top 10 stories.
          in this way, Find the Top 10 news stories specifically about $category.
          Focus on variety. Do NOT generate quiz questions.
          Return valid JSON List. Schema:
          [{"headline": "...", "summary": "...", "sourceName": "..."}]
        ''';
      }

      final response = await model.generateContent([Content.text(prompt)]);
      String? text = response.text;
      if (text == null) return [];

      String cleanJson = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      if (cleanJson.startsWith('{')) cleanJson = '[$cleanJson]';

      final List<dynamic> data = jsonDecode(cleanJson);
      return data.map((json) => NewsStory.fromJson(json)).toList();
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }
}

class NewsStory {
  final String headline;
  final String summary;
  final String sourceName;
  final QuizQuestion? quizQuestion; // Can be null for Category mode

  NewsStory({
    required this.headline,
    required this.summary,
    required this.sourceName,
    this.quizQuestion,
  });

  factory NewsStory.fromJson(Map<String, dynamic> json) {
    return NewsStory(
      headline: json['headline'] ?? '',
      summary: json['summary'] ?? '',
      sourceName: json['sourceName'] ?? 'News Source',
      quizQuestion: json.containsKey('quizQuestion')
          ? QuizQuestion.fromJson(json['quizQuestion'])
          : null,
    );
  }
}

class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;

  QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      questionText: json['questionText'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation; // The card to show AFTER the quiz

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correctIndex'] ?? 0,
      explanation: json['explanation'] ?? 'No explanation provided.',
    );
  }
}

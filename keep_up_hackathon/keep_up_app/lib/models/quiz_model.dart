class QuizQuestion {
  final String topic; // ✅ Added Topic
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuizQuestion({
    required this.topic,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      topic: json['topic'] ?? "General", // Default if missing
      question: json['question'],
      options: List<String>.from(json['options']),
      correctIndex: json['correctIndex'],
      explanation: json['explanation'],
    );
  }
}

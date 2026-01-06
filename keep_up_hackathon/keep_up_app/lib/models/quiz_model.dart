class QuizQuestion {
  final String topic;
  final String question;
  final List<String> options;
  final int correctIndex; // We will calculate this automatically!
  final String explanation;

  QuizQuestion({
    required this.topic,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    // 1. Get options safely
    List<String> opts =
        (json['options'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    // 2. INTELLIGENT INDEX FINDER 🧠
    int parsedIndex = 0; // Default to A

    // Case A: Database has "correctIndex" (0, 1, 2, 3)
    if (json['correctIndex'] != null) {
      parsedIndex = json['correctIndex'];
    }
    // Case B: Database has "answer": "C" (The issue in your screenshot!)
    else if (json['answer'] != null) {
      String letter = json['answer'].toString().trim().toUpperCase();
      switch (letter) {
        case 'A':
          parsedIndex = 0;
          break;
        case 'B':
          parsedIndex = 1;
          break;
        case 'C':
          parsedIndex = 2;
          break;
        case 'D':
          parsedIndex = 3;
          break;
        default:
          parsedIndex = 0;
      }
    }

    return QuizQuestion(
      topic: json['topic'] ?? "General",
      question: json['question'] ?? "Unknown Question",
      options: opts,
      correctIndex: parsedIndex, // Now correctly points to C (2)
      explanation: json['explanation'] ?? "No explanation available.",
    );
  }
}

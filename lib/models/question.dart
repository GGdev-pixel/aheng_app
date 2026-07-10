class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;

  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
  });
}

class Subject {
  final String id;
  final String name;
  final String icon;
  final List<Question> questions;

  const Subject({
    required this.id,
    required this.name,
    required this.icon,
    required this.questions,
  });
}
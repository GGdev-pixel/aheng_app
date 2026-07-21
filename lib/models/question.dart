enum QuestionType { multipleChoice, wordScramble, matching, fillBlank }

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String? imageUrl;
  final QuestionType type;
  final String? scrambleWord;
  final List<Map<String, String>>? matchingPairs;
  final String? blankSentence;
  final String? blankAnswer;

  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.imageUrl,
    this.type = QuestionType.multipleChoice,
    this.scrambleWord,
    this.matchingPairs,
    this.blankSentence,
    this.blankAnswer,
  });

  factory Question.fromFirestore(String id, Map<String, dynamic> data) {
    return Question(
      id: id,
      text: data['text'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctIndex: data['correctIndex'] ?? 0,
      imageUrl: data['imageUrl'],
      type: QuestionType.values.firstWhere(
            (t) => t.name == (data['type'] ?? 'multipleChoice'),
        orElse: () => QuestionType.multipleChoice,
      ),
      scrambleWord: data['scrambleWord'],
      matchingPairs: data['matchingPairs'] != null
          ? List<Map<String, String>>.from(
          (data['matchingPairs'] as List).map((e) => Map<String, String>.from(e)))
          : null,
      blankSentence: data['blankSentence'],
      blankAnswer: data['blankAnswer'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'options': options,
      'correctIndex': correctIndex,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'type': type.name,
      if (scrambleWord != null) 'scrambleWord': scrambleWord,
      if (matchingPairs != null) 'matchingPairs': matchingPairs,
      if (blankSentence != null) 'blankSentence': blankSentence,
      if (blankAnswer != null) 'blankAnswer': blankAnswer,
    };
  }
}

class Topic {
  final String id;
  final String name;
  final int order;
  final String? lessonContent;
  final String? lessonImageUrl;

  const Topic({
    required this.id,
    required this.name,
    required this.order,
    this.lessonContent,
    this.lessonImageUrl,
  });

  factory Topic.fromFirestore(String id, Map<String, dynamic> data) {
    return Topic(
      id: id,
      name: data['name'] ?? '',
      order: data['order'] ?? 0,
      lessonContent: data['lessonContent'],
      lessonImageUrl: data['lessonImageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'order': order,
      if (lessonContent != null) 'lessonContent': lessonContent,
      if (lessonImageUrl != null) 'lessonImageUrl': lessonImageUrl,
    };
  }
}

class Subject {
  final String id;
  final String name;
  final String icon;
  final int order;

  const Subject({
    required this.id,
    required this.name,
    required this.icon,
    required this.order,
  });

  factory Subject.fromFirestore(String id, Map<String, dynamic> data) {
    return Subject(
      id: id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '📚',
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'order': order,
    };
  }
}
class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String? imageUrl;

  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.imageUrl,
  });

  factory Question.fromFirestore(String id, Map<String, dynamic> data) {
    return Question(
      id: id,
      text: data['text'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctIndex: data['correctIndex'] ?? 0,
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'options': options,
      'correctIndex': correctIndex,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

class Topic {
  final String id;
  final String name;
  final int order;

  const Topic({
    required this.id,
    required this.name,
    required this.order,
  });

  factory Topic.fromFirestore(String id, Map<String, dynamic> data) {
    return Topic(
      id: id,
      name: data['name'] ?? '',
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'order': order,
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
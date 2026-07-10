import 'package:flutter/material.dart';

class ResultDetailScreen extends StatelessWidget {
  final String subjectName;
  final String topicName;
  final List<Map<String, dynamic>> questions;

  const ResultDetailScreen({
    super.key,
    required this.subjectName,
    required this.topicName,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$subjectName · $topicName')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];
          final options = List<String>.from(q['options']);
          final correctIndex = q['correctIndex'] as int;
          final selectedIndex = q['selectedIndex'] as int?;
          final isCorrect = selectedIndex == correctIndex;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${index + 1}. ${q['text']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(options.length, (i) {
                    Color? bgColor;
                    IconData? icon;

                    if (i == correctIndex) {
                      bgColor = Colors.green.shade50;
                      icon = Icons.check;
                    } else if (i == selectedIndex) {
                      bgColor = Colors.red.shade50;
                      icon = Icons.close;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(options[i])),
                          if (icon != null)
                            Icon(
                              icon,
                              size: 18,
                              color: i == correctIndex ? Colors.green : Colors.red,
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';

class WeakTopicQuestionsScreen extends StatelessWidget {
  final Subject subject;
  final Topic topic;
  final String? userId;

  const WeakTopicQuestionsScreen({
    super.key,
    required this.subject,
    required this.topic,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(topic.name)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ProgressService.getWrongQuestionsForTopic(
          subjectId: subject.id,
          topicId: topic.id,
          userId: userId,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = snapshot.data!;

          if (questions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Bu mövzuda hazırda səhv cavablanmış sual yoxdur',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];
              final options = List<String>.from(q['options'] ?? []);
              final correctIndex = q['correctIndex'] as int? ?? 0;
              final selectedIndex = q['selectedIndex'] as int?;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${q['text'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(options.length, (i) {
                        Color? bg;
                        if (i == correctIndex) {
                          bg = AppColors.success.withOpacity(0.1);
                        } else if (i == selectedIndex) {
                          bg = AppColors.accentRed.withOpacity(0.1);
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(options[i], style: const TextStyle(fontSize: 13)),
                        );
                      }),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('İzahatlar tezliklə əlavə olunacaq')),
                            );
                          },
                          icon: const Icon(Icons.lightbulb_outline, size: 16),
                          label: const Text('İzahat al'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
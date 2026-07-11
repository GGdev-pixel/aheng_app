import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Subject>>(
      stream: ContentService.getSubjects(),
      builder: (context, subjectsSnapshot) {
        if (subjectsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final subjects = subjectsSnapshot.data ?? [];

        if (subjects.isEmpty) {
          return const Center(child: Text('Hələ fənn əlavə edilməyib'));
        }

        return StreamBuilder(
          stream: ProgressService.getProgressStream(),
          builder: (context, progressSnapshot) {
            final progressMap = <String, Map<String, int>>{};
            if (progressSnapshot.hasData) {
              for (var doc in (progressSnapshot.data as dynamic).docs) {
                final data = doc.data() as Map<String, dynamic>;
                progressMap[doc.id] = {
                  'answered': data['answered'] ?? 0,
                  'correct': data['correct'] ?? 0,
                };
              }
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];

                int totalAnswered = 0;
                int totalCorrect = 0;
                progressMap.forEach((key, value) {
                  if (key.startsWith('${subject.id}_')) {
                    totalAnswered += value['answered']!;
                    totalCorrect += value['correct']!;
                  }
                });

                final percent =
                totalAnswered > 0 ? (totalCorrect / totalAnswered) : 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${subject.icon}  ${subject.name}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              totalAnswered > 0 ? '${(percent * 100).toStringAsFixed(0)}%' : '—',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: totalAnswered == 0
                                    ? Colors.grey.shade400
                                    : percent >= 0.7
                                    ? AppColors.success
                                    : percent >= 0.4
                                    ? AppColors.warning
                                    : AppColors.accentRed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalAnswered > 0
                              ? '$totalCorrect / $totalAnswered doğru cavab'
                              : 'Hələ test edilməyib',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
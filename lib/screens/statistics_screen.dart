import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../data/mock_data.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ProgressService.getProgressStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final progressMap = <String, Map<String, int>>{};
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            progressMap[doc.id] = {
              'answered': data['answered'] ?? 0,
              'correct': data['correct'] ?? 0,
            };
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mockSubjects.length,
          itemBuilder: (context, index) {
            final subject = mockSubjects[index];
            final progress = progressMap[subject.id];
            final answered = progress?['answered'] ?? 0;
            final correct = progress?['correct'] ?? 0;
            final percent = answered > 0 ? (correct / answered) : 0.0;

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
                          '${(percent * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: percent >= 0.7
                                ? Colors.green
                                : percent >= 0.4
                                ? Colors.orange
                                : Colors.red,
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
                      answered > 0
                          ? '$correct / $answered doğru cavab'
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
  }
}
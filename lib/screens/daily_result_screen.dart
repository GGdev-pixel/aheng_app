import 'package:flutter/material.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import 'daily_quiz_screen.dart';

class DailyResultScreen extends StatelessWidget {
  final List<Question> questions;
  final List<int?> answers;
  final int correctCount;
  final List<Question> wrongQuestions;

  const DailyResultScreen({
    super.key,
    required this.questions,
    required this.answers,
    required this.correctCount,
    required this.wrongQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final percent = questions.isEmpty ? 0 : (correctCount / questions.length * 100);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nəticələr'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: percent >= 70
                  ? AppColors.success.withOpacity(0.08)
                  : percent >= 40
                  ? AppColors.warning.withOpacity(0.08)
                  : AppColors.accentRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: percent >= 70
                        ? AppColors.success
                        : percent >= 40
                        ? AppColors.warning
                        : AppColors.accentRed,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$correctCount / ${questions.length} doğru cavab',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                final selected = answers[index];
                final isCorrect = selected == q.correctIndex;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? AppColors.success : AppColors.accentRed,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${index + 1}. ${q.text}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(q.options.length, (i) {
                          Color? bg;
                          if (i == q.correctIndex) {
                            bg = AppColors.success.withOpacity(0.1);
                          } else if (i == selected) {
                            bg = AppColors.accentRed.withOpacity(0.1);
                          }
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              q.options[i],
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: wrongQuestions.isNotEmpty
                  ? ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DailyQuizScreen(
                        customQuestions: wrongQuestions,
                      ),
                    ),
                  );
                },
                child: const Text('Səhvləri düzəldək'),
              )
                  : OutlinedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Bağla'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
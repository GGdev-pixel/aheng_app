import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import 'quiz_screen.dart';
import 'exam_screen.dart';

class TopicsScreen extends StatelessWidget {
  final Subject subject;

  const TopicsScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final questions = await ContentService.getExamQuestionsForSubject(subject.id, 20);
          if (questions.isEmpty || !context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExamScreen(
                title: '${subject.name} — İmtahan',
                questions: questions,
                durationMinutes: 20,
              ),
            ),
          );
        },
        icon: const Icon(Icons.timer_outlined),
        label: const Text('İmtahan rejimi'),
      ),
      appBar: AppBar(title: Text(subject.name)),
      body: StreamBuilder<List<Topic>>(
        stream: ContentService.getTopics(subject.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final topics = snapshot.data ?? [];

          if (topics.isEmpty) {
            return const Center(child: Text('Hələ mövzu əlavə edilməyib'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    topic.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showCountPicker(context, subject, topic),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
void _showCountPicker(BuildContext context, Subject subject, Topic topic) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Neçə sual həll etmək istəyirsiniz?',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              _CountOption(
                label: '10 sual',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                        subject: subject,
                        topic: topic,
                        questionCount: 10,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _CountOption(
                label: '20 sual',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                        subject: subject,
                        topic: topic,
                        questionCount: 20,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _CountOption(
                label: 'Hamısı',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                        subject: subject,
                        topic: topic,
                        questionCount: null,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _CountOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CountOption({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import 'lesson_detail_screen.dart';

class LessonTopicsScreen extends StatelessWidget {
  final Subject subject;

  const LessonTopicsScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              final hasLesson =
                  topic.lessonContent != null && topic.lessonContent!.isNotEmpty;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    topic.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    hasLesson ? 'Dərsi oxu' : 'Dərs hələ hazır deyil',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasLesson ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: hasLesson
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LessonDetailScreen(
                          subject: subject,
                          topic: topic,
                        ),
                      ),
                    );
                  }
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
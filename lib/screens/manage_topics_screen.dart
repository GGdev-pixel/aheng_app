import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import 'manage_questions_screen.dart';

class ManageTopicsScreen extends StatelessWidget {
  final Subject subject;

  const ManageTopicsScreen({super.key, required this.subject});

  void _showAddTopicDialog(BuildContext context, int currentCount) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni mövzu'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Mövzunun adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ləğv et'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await ContentService.addTopic(
                subjectId: subject.id,
                name: controller.text.trim(),
                order: currentCount,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Əlavə et'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Topic topic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silmək istəyirsiniz?'),
        content: Text('"${topic.name}" mövzusu və bütün sualları silinəcək.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ləğv et'),
          ),
          TextButton(
            onPressed: () async {
              await ContentService.deleteTopic(subject.id, topic.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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

          return Column(
            children: [
              Expanded(
                child: topics.isEmpty
                    ? const Center(child: Text('Hələ mövzu yoxdur'))
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(topic.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () =>
                                  _confirmDelete(context, topic),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageQuestionsScreen(
                                subject: subject,
                                topic: topic,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddTopicDialog(context, topics.length),
                    icon: const Icon(Icons.add),
                    label: const Text('Mövzu əlavə et'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
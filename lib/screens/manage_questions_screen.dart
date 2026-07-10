import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/content_service.dart';

class ManageQuestionsScreen extends StatelessWidget {
  final Subject subject;
  final Topic topic;

  const ManageQuestionsScreen({
    super.key,
    required this.subject,
    required this.topic,
  });

  void _showAddQuestionDialog(BuildContext context) {
    final textController = TextEditingController();
    final option1 = TextEditingController();
    final option2 = TextEditingController();
    final option3 = TextEditingController();
    final option4 = TextEditingController();
    int correctIndex = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni sual'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(labelText: 'Sual mətni'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                for (int i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: i,
                          groupValue: correctIndex,
                          onChanged: (value) {
                            setDialogState(() => correctIndex = value!);
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: [option1, option2, option3, option4][i],
                            decoration: InputDecoration(
                              labelText: 'Cavab ${i + 1}',
                              helperText: correctIndex == i ? 'Düzgün cavab' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ləğv et'),
            ),
            TextButton(
              onPressed: () async {
                final options = [
                  option1.text.trim(),
                  option2.text.trim(),
                  option3.text.trim(),
                  option4.text.trim(),
                ];
                if (textController.text.trim().isEmpty ||
                    options.any((o) => o.isEmpty)) {
                  return;
                }
                await ContentService.addQuestion(
                  subjectId: subject.id,
                  topicId: topic.id,
                  text: textController.text.trim(),
                  options: options,
                  correctIndex: correctIndex,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Əlavə et'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Question question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silmək istəyirsiniz?'),
        content: const Text('Bu sual silinəcək.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ləğv et'),
          ),
          TextButton(
            onPressed: () async {
              await ContentService.deleteQuestion(
                  subject.id, topic.id, question.id);
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
      appBar: AppBar(title: Text(topic.name)),
      body: StreamBuilder<List<Question>>(
        stream: ContentService.getQuestions(subject.id, topic.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = snapshot.data ?? [];

          return Column(
            children: [
              Expanded(
                child: questions.isEmpty
                    ? const Center(child: Text('Hələ sual yoxdur'))
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(question.text),
                        subtitle: Text(
                          'Düzgün: ${question.options[question.correctIndex]}',
                          style: const TextStyle(color: Colors.green),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () =>
                              _confirmDelete(context, question),
                        ),
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
                    onPressed: () => _showAddQuestionDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Sual əlavə et'),
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
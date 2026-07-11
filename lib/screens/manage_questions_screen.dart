import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
    File? pickedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni sual'),
          content: SizedBox(
            width: double.maxFinite,
            height: 450,
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(labelText: 'Sual mətni'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                if (pickedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            pickedImage!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('IMAGE ERROR: $error');
                              return Container(
                                height: 150,
                                color: Colors.grey.shade200,
                                child: const Center(child: Text('Şəkil yüklənmədi')),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                            onPressed: () {
                              setDialogState(() => pickedImage = null);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked =
                    await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setDialogState(() => pickedImage = File(picked.path));
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: Text(pickedImage == null ? 'Şəkil əlavə et' : 'Şəkli dəyiş'),
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
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context),
              child: const Text('Ləğv et'),
            ),
            TextButton(
              onPressed: isUploading
                  ? null
                  : () async {
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

                setDialogState(() => isUploading = true);

                String? imageUrl;
                if (pickedImage != null) {
                  imageUrl =
                  await ContentService.uploadQuestionImage(pickedImage!);
                }

                await ContentService.addQuestion(
                  subjectId: subject.id,
                  topicId: topic.id,
                  text: textController.text.trim(),
                  options: options,
                  correctIndex: correctIndex,
                  imageUrl: imageUrl,
                );

                if (context.mounted) Navigator.pop(context);
              },
              child: isUploading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Əlavə et'),
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
                        leading: question.imageUrl != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            question.imageUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                            : null,
                        title: Text(question.text),
                        subtitle: Text(
                          'Düzgün: ${question.options[question.correctIndex]}',
                          style: const TextStyle(color: Colors.green),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _confirmDelete(context, question),
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
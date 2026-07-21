import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import 'manage_questions_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ManageTopicsScreen extends StatelessWidget {
  final Subject subject;

  const ManageTopicsScreen({super.key, required this.subject});

  void _showLessonDialog(BuildContext context, Topic topic) {
    final controller = TextEditingController(text: topic.lessonContent ?? '');
    File? pickedImage;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${topic.name} — dərs'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pickedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(pickedImage!, height: 120, fit: BoxFit.cover, width: double.infinity),
                      ),
                    )
                  else if (topic.lessonImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(topic.lessonImageUrl!, height: 120, fit: BoxFit.cover, width: double.infinity),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1024,
                        imageQuality: 70,
                      );
                      if (picked != null) {
                        setDialogState(() => pickedImage = File(picked.path));
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Şəkil əlavə et'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      hintText: 'Dərsin mətnini yazın...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Ləğv et'),
            ),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () async {
                setDialogState(() => isSaving = true);

                String? imageUrl = topic.lessonImageUrl;
                if (pickedImage != null) {
                  imageUrl = await ContentService.uploadQuestionImage(pickedImage!);
                }

                await ContentService.updateLesson(
                  subjectId: subject.id,
                  topicId: topic.id,
                  content: controller.text.trim(),
                  imageUrl: imageUrl,
                );

                if (context.mounted) Navigator.pop(context);
              },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Yadda saxla'),
            ),
          ],
        ),
      ),
    );
  }

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
                        subtitle: Text(
                          topic.lessonContent != null && topic.lessonContent!.isNotEmpty
                              ? 'Dərs yazılıb'
                              : 'Dərs yazılmayıb',
                          style: TextStyle(
                            fontSize: 12,
                            color: topic.lessonContent != null
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.menu_book_outlined),
                              onPressed: () => _showLessonDialog(context, topic),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, topic),
                            ),
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
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import 'quiz_screen.dart';
import 'lesson_detail_screen.dart';

class _TopicProgress {
  final String subjectId;
  final String topicId;
  final int answered;
  final int correct;
  _TopicProgress(this.subjectId, this.topicId, this.answered, this.correct);
  double get percent => answered > 0 ? correct / answered : 0;
}

class StudyPlanScreen extends StatelessWidget {
  const StudyPlanScreen({super.key});

  Future<List<Map<String, dynamic>>> _buildPlan(List<_TopicProgress> entries) async {
    final result = <Map<String, dynamic>>[];
    for (var entry in entries.take(8)) {
      final subject = await ContentService.getSubjectOnce(entry.subjectId);
      final topic = await ContentService.getTopicOnce(entry.subjectId, entry.topicId);
      if (subject == null || topic == null) continue;
      result.add({'subject': subject, 'topic': topic, 'entry': entry});
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Hazırlıq planı')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, userSnap) {
          final userData = userSnap.data?.data() as Map<String, dynamic>?;
          final examTs = userData?['examDate'];

          if (examTs == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'İmtahan tarixi təyin edilməyib. Profil bölməsindən tarixi seçin.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final examDate = (examTs as Timestamp).toDate();
          final daysLeft = examDate.difference(DateTime.now()).inDays;

          return StreamBuilder(
            stream: ProgressService.getProgressStream(),
            builder: (context, progressSnap) {
              final entries = <_TopicProgress>[];
              if (progressSnap.hasData) {
                final docs = (progressSnap.data as dynamic).docs as List;
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final answered = data['answered'] ?? 0;
                  if (answered <= 0) continue;
                  final subjectId = data['subjectId'];
                  final topicId = data['topicId'];
                  if (subjectId == null || topicId == null) continue;
                  entries.add(_TopicProgress(subjectId, topicId, answered, data['correct'] ?? 0));
                }
              }
              entries.sort((a, b) => a.percent.compareTo(b.percent));

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryBlue, AppColors.primaryBlue.withOpacity(0.85)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          daysLeft < 0
                              ? 'İmtahan keçdi'
                              : daysLeft == 0
                              ? 'Bu gün!'
                              : '$daysLeft',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (daysLeft > 0)
                          const Text(
                            'gün qaldı',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '${examDate.day}.${examDate.month.toString().padLeft(2, '0')}.${examDate.year}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Plan hazırlamaq üçün bir neçə test edin — statistikanız toplandıqca burada tövsiyələr görünəcək.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  else ...[
                    const Text(
                      'Tövsiyə olunan mövzular',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ən zəif nəticəli mövzulardan başlayaraq sıralanıb',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _buildPlan(entries),
                      builder: (context, planSnap) {
                        if (!planSnap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final plan = planSnap.data!;
                        if (plan.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: plan.map((item) {
                            final subject = item['subject'] as Subject;
                            final topic = item['topic'] as Topic;
                            final entry = item['entry'] as _TopicProgress;
                            final percentText = (entry.percent * 100).toStringAsFixed(0);
                            final hasLesson = topic.lessonContent != null &&
                                topic.lessonContent!.trim().isNotEmpty;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${subject.icon} ${topic.name}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                        ),
                                        Text(
                                          '$percentText%',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: entry.percent >= 0.7
                                                ? AppColors.success
                                                : entry.percent >= 0.4
                                                ? AppColors.warning
                                                : AppColors.accentRed,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      subject.name,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        if (hasLesson) ...[
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => LessonDetailScreen(
                                                      subject: subject,
                                                      topic: topic,
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.menu_book_outlined, size: 16),
                                              label: const Text('Dərs'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => QuizScreen(
                                                    subject: subject,
                                                    topic: topic,
                                                    questionCount: 15,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.quiz_outlined, size: 16),
                                            label: const Text('Test et'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
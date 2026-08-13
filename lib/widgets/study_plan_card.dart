import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../screens/quiz_screen.dart';
import '../screens/study_plan_screen.dart';

class _TopicProgress {
  final String subjectId;
  final String topicId;
  final int answered;
  final int correct;
  _TopicProgress(this.subjectId, this.topicId, this.answered, this.correct);
  double get percent => answered > 0 ? correct / answered : 0;
}

class StudyPlanCard extends StatelessWidget {
  const StudyPlanCard({super.key});

  Future<Map<String, dynamic>?> _findFirstValidEntry(List<_TopicProgress> entries) async {
    for (var entry in entries) {
      final subject = await ContentService.getSubjectOnce(entry.subjectId);
      final topic = await ContentService.getTopicOnce(entry.subjectId, entry.topicId);
      if (subject != null && topic != null) {
        return {'subject': subject, 'topic': topic, 'entry': entry};
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>?;
        final examTs = userData?['examDate'];

        if (examTs == null) return const SizedBox.shrink();

        final examDate = (examTs as Timestamp).toDate();
        final daysLeft = examDate.difference(DateTime.now()).inDays;

        if (daysLeft < 0) return const SizedBox.shrink();

        return StreamBuilder(
          stream: ProgressService.getProgressStream(),
          builder: (context, progressSnap) {
            if (!progressSnap.hasData) return const SizedBox.shrink();

            final docs = (progressSnap.data as dynamic).docs as List;
            final entries = <_TopicProgress>[];
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final answered = data['answered'] ?? 0;
              if (answered <= 0) continue;
              final subjectId = data['subjectId'];
              final topicId = data['topicId'];
              if (subjectId == null || topicId == null) continue;
              entries.add(_TopicProgress(subjectId, topicId, answered, data['correct'] ?? 0));
            }

            if (entries.isEmpty) return const SizedBox.shrink();

            entries.sort((a, b) => a.percent.compareTo(b.percent));

            return FutureBuilder<Map<String, dynamic>?>(
              future: _findFirstValidEntry(entries),
              builder: (context, lookupSnap) {
                if (lookupSnap.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (!lookupSnap.hasData || lookupSnap.data == null) {
                  return const SizedBox.shrink();
                }

                final subject = lookupSnap.data!['subject'] as Subject;
                final topic = lookupSnap.data!['topic'] as Topic;
                final weakest = lookupSnap.data!['entry'] as _TopicProgress;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.primaryBlue.withOpacity(0.85)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag_outlined, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            daysLeft == 0 ? 'İmtahan bu gündür!' : '$daysLeft gün qaldı',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Bugünkü tövsiyə: ${subject.name} — ${topic.name}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      Text(
                        'Bu mövzuda ${(weakest.percent * 100).toStringAsFixed(0)}% nəticəniz var',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryBlue,
                          ),
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
                          child: const Text('İndi məşq et'),
                        ),
                      ),
                    ],
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

class StudyPlanBadge extends StatelessWidget {
  const StudyPlanBadge({super.key});

  Future<Map<String, dynamic>?> _findFirstValidEntry(List<_TopicProgress> entries) async {
    for (var entry in entries) {
      final subject = await ContentService.getSubjectOnce(entry.subjectId);
      final topic = await ContentService.getTopicOnce(entry.subjectId, entry.topicId);
      if (subject != null && topic != null) {
        return {'subject': subject, 'topic': topic, 'entry': entry};
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>?;
        final examTs = userData?['examDate'];

        if (examTs == null) return const SizedBox.shrink();

        final examDate = (examTs as Timestamp).toDate();
        final daysLeft = examDate.difference(DateTime.now()).inDays;

        if (daysLeft < 0) return const SizedBox.shrink();

        return StreamBuilder(
          stream: ProgressService.getProgressStream(),
          builder: (context, progressSnap) {
            if (!progressSnap.hasData) return const SizedBox.shrink();

            final docs = (progressSnap.data as dynamic).docs as List;
            final entries = <_TopicProgress>[];
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final answered = data['answered'] ?? 0;
              if (answered <= 0) continue;
              final subjectId = data['subjectId'];
              final topicId = data['topicId'];
              if (subjectId == null || topicId == null) continue;
              entries.add(_TopicProgress(subjectId, topicId, answered, data['correct'] ?? 0));
            }

            if (entries.isEmpty) {
              return _buildPill(context, daysLeft, null, null);
            }

            entries.sort((a, b) => a.percent.compareTo(b.percent));

            return FutureBuilder<Map<String, dynamic>?>(
              future: _findFirstValidEntry(entries),
              builder: (context, lookupSnap) {
                final subject = lookupSnap.data?['subject'] as Subject?;
                final topic = lookupSnap.data?['topic'] as Topic?;
                return _buildPill(context, daysLeft, subject, topic);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPill(BuildContext context, int daysLeft, Subject? subject, Topic? topic) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudyPlanScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag_outlined, size: 14, color: AppColors.primaryBlue),
              const SizedBox(width: 4),
              Text(
                daysLeft == 0 ? 'Bu gün!' : '$daysLeft gün',
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

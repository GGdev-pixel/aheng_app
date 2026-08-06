import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import 'topics_screen.dart';
import 'daily_quiz_screen.dart';
import 'daily_settings_screen.dart';
import '../theme/app_theme.dart';
import 'statistics_screen.dart';
import '../services/progress_service.dart';
import '../widgets/streak_flame_icon.dart';
import 'quiz_screen.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Subject>>(
      stream: ContentService.getSubjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final subjects = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DailyCard(),
            const SizedBox(height: 16),
            _WeakTopicsCard(subjects: subjects),

            const SizedBox(height: 24),
            if (subjects.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('Hələ fənn əlavə edilməyib')),
              )
            else
              ...subjects.map((subject) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: _SubjectIcon(subjectName: subject.name),
                    title: Text(
                      subject.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TopicsScreen(subject: subject),
                        ),
                      );
                    },
                  ),
                );
              }),
            const SizedBox(height: 20),
            _UnfinishedTestCard(),
          ],
        );
      },
    );
  }
}

class _DailyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final streak = data?['dailyStreak'] ?? 0;
        final hasSettings = data?['dailySettings'] != null &&
            (data?['dailySettings']['subjectIds'] as List?)?.isNotEmpty == true;

        return Card(
          color: AppColors.primaryBlue.withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        StreakFlameIcon(streak: streak),
                        const SizedBox(width: 8),
                        Text(
                          '$streak gün ardıcıl',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DailySettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DailyQuizScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.today),
                    label: Text(
                      hasSettings
                          ? 'Gündəlik sualları başla'
                          : 'Gündəlik sualları tənzimlə',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
class _SubjectIcon extends StatelessWidget {
  final String subjectName;

  const _SubjectIcon({required this.subjectName});

  IconData get _icon {
    switch (subjectName) {
      case 'Qanunvericilik':
        return Icons.gavel_rounded;
      case 'Məntiq':
        return Icons.psychology_alt_rounded;
      case 'Azərbaycan dili':
        return Icons.menu_book_rounded;
      case 'İnformatika':
        return Icons.computer_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_icon, color: AppColors.primaryBlue, size: 24),
    );
  }
}
class _WeakTopicsCard extends StatelessWidget {
  final List<Subject> subjects;

  const _WeakTopicsCard({required this.subjects});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ProgressService.getProgressStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final progressMap = <String, Map<String, int>>{};
        for (var doc in (snapshot.data as dynamic).docs) {
          final data = doc.data() as Map<String, dynamic>;
          progressMap[doc.id] = {
            'answered': data['answered'] ?? 0,
            'correct': data['correct'] ?? 0,
          };
        }

        final subjectStats = <MapEntry<Subject, double>>[];
        for (var subject in subjects) {
          int answered = 0;
          int correct = 0;
          progressMap.forEach((key, value) {
            if (key.startsWith('${subject.id}_')) {
              answered += value['answered']!;
              correct += value['correct']!;
            }
          });
          if (answered > 0) {
            subjectStats.add(MapEntry(subject, correct / answered));
          }
        }

        if (subjectStats.isEmpty) return const SizedBox.shrink();

        subjectStats.sort((a, b) => a.value.compareTo(b.value));
        final weakest = subjectStats.first;

        if (weakest.value >= 0.7) return const SizedBox.shrink();

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Statistika')),
                  body: const StatisticsScreen(),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentRed.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentRed.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_down_rounded, color: AppColors.accentRed),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zəif tərəf: ${weakest.key.name}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        '${(weakest.value * 100).toStringAsFixed(0)}% doğru — bu mövzunu təkrarlayın',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.accentRed),
              ],
            ),
          ),
        );
      },
    );
  }
}
class _UnfinishedTestCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: ProgressService.getInProgressStream(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        final data = docs.first.data() as Map<String, dynamic>;
        final subjectId = data['subjectId'] as String?;
        final topicId = data['topicId'] as String?;
        final subjectName = data['subjectName'] ?? '';
        final topicName = data['topicName'] ?? '';
        final currentIndex = data['currentIndex'] ?? 0;
        final total = (data['questionIds'] as List?)?.length ?? 0;

        if (subjectId == null || topicId == null) return const SizedBox.shrink();

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final subject = await ContentService.getSubjectOnce(subjectId);
            final topic = await ContentService.getTopicOnce(subjectId, topicId);
            if (subject == null || topic == null || !context.mounted) return;
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
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.play_circle_outline, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yarımçıq qalmış test',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        '$subjectName · $topicName — sual ${currentIndex + 1}/$total',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.warning),
              ],
            ),
          ),
        );
      },
    );
  }
}
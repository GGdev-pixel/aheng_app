import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/trend_chart.dart';
import '../widgets/weak_topics_panel.dart';

class StatisticsScreen extends StatelessWidget {
  final String? userId;

  const StatisticsScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Subject>>(
      stream: ContentService.getSubjects(),
      builder: (context, subjectsSnapshot) {
        if (subjectsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final subjects = subjectsSnapshot.data ?? [];

        if (subjects.isEmpty) {
          return const Center(child: Text('Hələ fənn əlavə edilməyib'));
        }

        return StreamBuilder(
          stream: ProgressService.getProgressStream(userId: userId),
          builder: (context, progressSnapshot) {
            final progressMap = <String, Map<String, int>>{};
            if (progressSnapshot.hasData) {
              for (var doc in (progressSnapshot.data as dynamic).docs) {
                final data = doc.data() as Map<String, dynamic>;
                progressMap[doc.id] = {
                  'answered': data['answered'] ?? 0,
                  'correct': data['correct'] ?? 0,
                };
              }
            }

            int totalAnswered = 0;
            int totalCorrect = 0;
            progressMap.forEach((key, value) {
              totalAnswered += value['answered']!;
              totalCorrect += value['correct']!;
            });

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(
                  totalAnswered: totalAnswered,
                  totalCorrect: totalCorrect,
                  userId: userId,
                ),
                const SizedBox(height: 20),
                WeakTopicsPanel(userId: userId),
                const SizedBox(height: 20),
                _TrendSection(userId: userId),
                const SizedBox(height: 20),
                ...subjects.map((subject) {
                  return _SubjectExpansionCard(
                    subject: subject,
                    progressMap: progressMap,
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalAnswered;
  final int totalCorrect;
  final String? userId;

  const _SummaryCard({
    required this.totalAnswered,
    required this.totalCorrect,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    final percent = totalAnswered > 0 ? (totalCorrect / totalAnswered * 100) : 0.0;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final streak = (snapshot.data?.data() as Map<String, dynamic>?)?['dailyStreak'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              _SummaryStat(
                icon: Icons.quiz_outlined,
                value: '$totalAnswered',
                label: 'Sual cavablandı',
              ),
              _verticalDivider(),
              _SummaryStat(
                icon: Icons.check_circle_outline,
                value: '${percent.toStringAsFixed(0)}%',
                label: 'Doğru cavab',
              ),
              _verticalDivider(),
              _SummaryStat(
                icon: Icons.local_fire_department_outlined,
                value: '$streak',
                label: 'Gün ardıcıl',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white24,
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SubjectExpansionCard extends StatelessWidget {
  final Subject subject;
  final Map<String, Map<String, int>> progressMap;

  const _SubjectExpansionCard({required this.subject, required this.progressMap});

  @override
  Widget build(BuildContext context) {
    int totalAnswered = 0;
    int totalCorrect = 0;
    progressMap.forEach((key, value) {
      if (key.startsWith('${subject.id}_')) {
        totalAnswered += value['answered']!;
        totalCorrect += value['correct']!;
      }
    });
    final percent = totalAnswered > 0 ? (totalCorrect / totalAnswered) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${subject.icon}  ${subject.name}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              totalAnswered > 0 ? '${(percent * 100).toStringAsFixed(0)}%' : '—',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: totalAnswered == 0
                    ? Colors.grey.shade400
                    : percent >= 0.7
                    ? AppColors.success
                    : percent >= 0.4
                    ? AppColors.warning
                    : AppColors.accentRed,
              ),
            ),
          ],
        ),
        children: [
          StreamBuilder<List<Topic>>(
            stream: ContentService.getTopics(subject.id),
            builder: (context, topicSnapshot) {
              final topics = topicSnapshot.data ?? [];

              if (topics.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Hələ mövzu yoxdur'),
                );
              }

              return Column(
                children: topics.map((topic) {
                  final key = '${subject.id}_${topic.id}';
                  final data = progressMap[key];
                  final answered = data?['answered'] ?? 0;
                  final correct = data?['correct'] ?? 0;
                  final topicPercent = answered > 0 ? (correct / answered) : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                topic.name,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              answered > 0 ? '${(topicPercent * 100).toStringAsFixed(0)}%' : '—',
                              style: TextStyle(
                                fontSize: 12,
                                color: answered == 0 ? Colors.grey.shade400 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: topicPercent,
                            minHeight: 5,
                            backgroundColor: Colors.grey.shade200,
                            color: answered == 0
                                ? Colors.transparent
                                : topicPercent >= 0.7
                                ? AppColors.success
                                : topicPercent >= 0.4
                                ? AppColors.warning
                                : AppColors.accentRed,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _TrendSection extends StatelessWidget {
  final String? userId;

  const _TrendSection({this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: ProgressService.getResultsStream(userId: userId),
      builder: (context, snapshot) {
        final docs = (snapshot.data?.docs ?? [])
            .where((doc) => (doc.data() as Map<String, dynamic>)['subjectId'] != 'daily')
            .toList();

        if (docs.isEmpty) return const SizedBox.shrink();

        final chronological = docs.reversed.toList();
        final recent = chronological.length > 15
            ? chronological.sublist(chronological.length - 15)
            : chronological;

        final percentages = recent.map<double>((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final int answered = data['answered'] ?? 1;
          final int correct = data['correct'] ?? 0;
          return answered > 0 ? (correct / answered * 100) : 0.0;
        }).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Son testlərin dinamikası',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                TrendChart(percentages: percentages),
              ],
            ),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import 'topics_screen.dart';
import 'daily_quiz_screen.dart';
import 'daily_settings_screen.dart';
import '../theme/app_theme.dart';

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
                        const Icon(Icons.local_fire_department, color: AppColors.accentRed, size: 28),
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
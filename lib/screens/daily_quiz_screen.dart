import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/streak_milestone_dialog.dart';
import '../widgets/premium_dialog.dart';
import 'daily_settings_screen.dart';
import 'daily_result_screen.dart';

class DailyQuizScreen extends StatefulWidget {
  final bool isRetake;
  final List<Question>? customQuestions;

  const DailyQuizScreen({
    super.key,
    this.isRetake = false,
    this.customQuestions,
  });

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> {
  bool _loading = true;
  bool _alreadyDoneToday = false;
  bool _noSettings = false;
  bool _isPremiumUser = false;

  List<Question> _quizQuestions = [];
  List<int?> _userAnswers = [];

  int _currentIndex = 0;
  int? _selectedOption;

  bool get _isMistakeRound => widget.customQuestions != null;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (_isMistakeRound) {
      final qs = widget.customQuestions!;
      setState(() {
        _quizQuestions = qs;
        _userAnswers = List<int?>.filled(qs.length, null);
        _loading = false;
      });
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final data = doc.data();
    final lastCompleted = data?['dailyLastCompleted'];
    final settings = data?['dailySettings'] as Map<String, dynamic>?;
    final isPremium = data?['isPremium'] == true;

    if (settings == null || (settings['subjectIds'] as List?)?.isEmpty != false) {
      setState(() {
        _noSettings = true;
        _loading = false;
      });
      return;
    }

    if (lastCompleted == _todayKey && !widget.isRetake) {
      setState(() {
        _alreadyDoneToday = true;
        _isPremiumUser = isPremium;
        _loading = false;
      });
      return;
    }

    final subjectIds = List<String>.from(settings['subjectIds']);
    final count = settings['count'] ?? 10;

    final List<Question> pool = [];
    for (var subjectId in subjectIds) {
      final questions = await ContentService.getAllQuestionsForSubject(subjectId);
      pool.addAll(questions);
    }

    pool.shuffle(Random());
    final selected = pool.take(count).toList();

    setState(() {
      _quizQuestions = selected;
      _userAnswers = List<int?>.filled(selected.length, null);
      _loading = false;
    });
  }

  void _selectOption(int index) {
    setState(() {
      _selectedOption = index;
      _userAnswers[_currentIndex] = index;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _quizQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = _userAnswers[_currentIndex];
      });
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    int correctCount = 0;
    final wrongQuestions = <Question>[];
    for (var i = 0; i < _quizQuestions.length; i++) {
      final q = _quizQuestions[i];
      if (_userAnswers[i] == q.correctIndex) {
        correctCount++;
      } else {
        wrongQuestions.add(q);
      }
    }

    if (!_isMistakeRound && !widget.isRetake) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userRef.get();
      final data = userDoc.data();

      final lastCompleted = data?['dailyLastCompleted'];
      final currentStreak = data?['dailyStreak'] ?? 0;

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      int newStreak;
      if (lastCompleted == yesterdayKey) {
        newStreak = currentStreak + 1;
      } else {
        newStreak = 1;
      }

      await userRef.update({
        'dailyLastCompleted': _todayKey,
        'dailyStreak': newStreak,
      });

      const milestones = [10, 20, 50, 70, 100];
      final crossedMilestone = milestones
          .where((m) => currentStreak < m && newStreak >= m)
          .toList();

      if (crossedMilestone.isNotEmpty && mounted) {
        await StreakMilestoneDialog.show(context, crossedMilestone.last);
      }
    }

    if (!_isMistakeRound) {
      final questionsData = List.generate(_quizQuestions.length, (i) {
        final q = _quizQuestions[i];
        return {
          'text': q.text,
          'options': q.options,
          'correctIndex': q.correctIndex,
          'selectedIndex': _userAnswers[i],
        };
      });

      await ProgressService.saveQuizAttempt(
        subjectId: 'daily',
        subjectName: 'Gündəlik suallar',
        topicId: _todayKey,
        topicName: _todayKey,
        questionsData: questionsData,
      );
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DailyResultScreen(
          questions: _quizQuestions,
          answers: _userAnswers,
          correctCount: correctCount,
          wrongQuestions: wrongQuestions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gündəlik suallar')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_noSettings) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gündəlik suallar')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Əvvəlcə fənləri seçməlisiniz',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DailySettingsScreen(),
                      ),
                    );
                  },
                  child: const Text('Tənzimləmələrə keç'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_alreadyDoneToday) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gündəlik suallar')),
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get(),
          builder: (context, snapshot) {
            final streak = (snapshot.data?.data()
            as Map<String, dynamic>?)?['dailyStreak'] ??
                0;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 48, color: Colors.green),
                    const SizedBox(height: 16),
                    const Text(
                      'Bugünkü sualları artıq tamamladınız!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.orange, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          '$streak gün ardıcıl',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sabah yenidən qayıdın',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (_isPremiumUser) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DailyQuizScreen(isRetake: true),
                            ),
                          );
                        } else {
                          PremiumDialog.show(
                            context,
                            message: 'Gündəlik sualları limitsiz təkrarlamaq üçün Premium abunəlik lazımdır.',
                          );
                        }
                      },
                      icon: const Icon(Icons.replay),
                      label: const Text('Yenidən başla'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    if (_quizQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gündəlik suallar')),
        body: const Center(child: Text('Seçilmiş fənlərdə sual yoxdur')),
      );
    }

    final question = _quizQuestions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isMistakeRound ? 'Səhvlərin düzəlişi' : 'Gündəlik suallar'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / _quizQuestions.length,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Sual ${_currentIndex + 1} / ${_quizQuestions.length}',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (question.imageUrl != null) ...[
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 100, maxHeight: 260),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            question.imageUrl!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(
                                height: 180,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (question.text.trim().isNotEmpty) ...[
                      Text(
                        question.text,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    ...List.generate(question.options.length, (index) {
                      final isSelected = _selectedOption == index;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _selectOption(index),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryBlue.withOpacity(0.08)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              question.options[index],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedOption != null ? _nextQuestion : null,
                  child: Text(
                    _currentIndex < _quizQuestions.length - 1 ? 'Növbəti sual' : 'Bitir',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
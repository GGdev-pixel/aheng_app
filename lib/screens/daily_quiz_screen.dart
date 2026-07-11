import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import '../services/progress_service.dart';
import 'daily_settings_screen.dart';

class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({super.key});

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> {
  bool _loading = true;
  bool _alreadyDoneToday = false;
  bool _noSettings = false;
  bool _isRetryMode = false;

  List<Question> _quizQuestions = [];
  List<int?> _userAnswers = [];
  List<Question> _wrongQuestions = [];

  int _currentIndex = 0;
  int _correctCount = 0;
  int? _selectedOption;
  bool _answered = false;

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
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final data = doc.data();
    final lastCompleted = data?['dailyLastCompleted'];
    final settings = data?['dailySettings'] as Map<String, dynamic>?;

    if (settings == null || (settings['subjectIds'] as List?)?.isEmpty != false) {
      setState(() {
        _noSettings = true;
        _loading = false;
      });
      return;
    }

    if (lastCompleted == _todayKey) {
      setState(() {
        _alreadyDoneToday = true;
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
    if (_answered) return;
    setState(() {
      _selectedOption = index;
      _answered = true;
      _userAnswers[_currentIndex] = index;

      final question = _quizQuestions[_currentIndex];
      if (index == question.correctIndex) {
        _correctCount++;
      } else if (!_isRetryMode) {
        _wrongQuestions.add(question);
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _quizQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
    } else {
      if (_isRetryMode) {
        _showRetryResult();
      } else {
        _finish();
      }
    }
  }

  Future<void> _finish() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

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

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Təbriklər!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bugünkü ${_quizQuestions.length} sualdan $_correctCount-nə düzgün cavab verdiniz.',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                const SizedBox(width: 8),
                Text(
                  '$newStreak gün',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_wrongQuestions.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startRetry();
              },
              child: const Text('Səhvləri düzəldək'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Bağla'),
          ),
        ],
      ),
    );
  }

  void _startRetry() {
    setState(() {
      _isRetryMode = true;
      _quizQuestions = List<Question>.from(_wrongQuestions);
      _userAnswers = List<int?>.filled(_quizQuestions.length, null);
      _wrongQuestions = [];
      _currentIndex = 0;
      _correctCount = 0;
      _selectedOption = null;
      _answered = false;
    });
  }

  void _showRetryResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Nəticə'),
        content: Text(
          '${_quizQuestions.length} sualdan $_correctCount-nə düzgün cavab verdiniz.',
        ),
        actions: [
          if (_wrongQuestions.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startRetry();
              },
              child: const Text('Yenidən cəhd et'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Bağla'),
          ),
        ],
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
        title: Text(_isRetryMode ? 'Səhvlərin düzəlişi' : 'Gündəlik suallar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _quizQuestions.length,
            ),
            const SizedBox(height: 8),
            Text(
              'Sual ${_currentIndex + 1} / ${_quizQuestions.length}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (question.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  question.imageUrl!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 180,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              question.text,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ...List.generate(question.options.length, (index) {
              final isSelected = _selectedOption == index;
              final isCorrect = index == question.correctIndex;

              Color? color;
              if (_answered) {
                if (isCorrect) {
                  color = Colors.green.shade100;
                } else if (isSelected) {
                  color = Colors.red.shade100;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _selectOption(index),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      question.options[index],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            if (_answered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  child: Text(
                    _currentIndex < _quizQuestions.length - 1
                        ? 'Növbəti sual'
                        : 'Bitir',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
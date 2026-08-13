import 'dart:async';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import 'exam_result_screen.dart';

class ExamScreen extends StatefulWidget {
  final String title;
  final List<Question> questions;
  final int durationMinutes;

  const ExamScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.durationMinutes,
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  late List<int?> _answers;
  int _currentIndex = 0;
  late int _secondsLeft;
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _answers = List<int?>.filled(widget.questions.length, null);
    _secondsLeft = widget.durationMinutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        _finishExam();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeText {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _selectAnswer(int index) {
    setState(() => _answers[_currentIndex] = index);
  }

  void _goTo(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _finishExam() async {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();

    int correct = 0;
    final questionsData = List.generate(widget.questions.length, (i) {
      final q = widget.questions[i];
      final selected = _answers[i];
      if (selected == q.correctIndex) correct++;
      return {
        'text': q.text,
        'options': q.options,
        'correctIndex': q.correctIndex,
        'selectedIndex': selected,
      };
    });

    await ProgressService.saveQuizAttempt(
      subjectId: 'exam',
      subjectName: 'İmtahan rejimi',
      topicId: DateTime.now().millisecondsSinceEpoch.toString(),
      topicName: widget.title,
      questionsData: questionsData,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ExamResultScreen(
          title: widget.title,
          questions: widget.questions,
          answers: _answers,
          correctCount: correct,
        ),
      ),
    );
  }

  Future<void> _confirmFinishEarly() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İmtahanı bitirmək'),
        content: Text(
          'Cavablanmamış ${_answers.where((a) => a == null).length} sual var. Bitirmək istəyirsiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Davam et'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bitir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _finishExam();
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];
    final isLowTime = _secondsLeft < 60;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmFinishEarly();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          automaticallyImplyLeading: false,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isLowTime
                    ? AppColors.accentRed.withOpacity(0.1)
                    : AppColors.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 16,
                      color: isLowTime ? AppColors.accentRed : AppColors.primaryBlue),
                  const SizedBox(width: 6),
                  Text(
                    _timeText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isLowTime ? AppColors.accentRed : AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sual ${_currentIndex + 1} / ${widget.questions.length}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      if (question.imageUrl != null) ...[
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 100, maxHeight: 240),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(question.imageUrl!, fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (question.text.trim().isNotEmpty) ...[
                        Text(
                          question.text,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      ...List.generate(question.options.length, (index) {
                        final isSelected = _answers[_currentIndex] == index;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _selectAnswer(index),
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
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: widget.questions.length,
                    itemBuilder: (context, index) {
                      final answered = _answers[index] != null;
                      final isCurrent = index == _currentIndex;
                      return GestureDetector(
                        onTap: () => _goTo(index),
                        child: Container(
                          width: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? AppColors.primaryBlue
                                : answered
                                ? AppColors.success.withOpacity(0.15)
                                : Colors.grey.shade100,
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.primaryBlue
                                  : answered
                                  ? AppColors.success
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Row(
                  children: [
                    if (_currentIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _goTo(_currentIndex - 1),
                          child: const Text('Geri'),
                        ),
                      ),
                    if (_currentIndex > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentIndex < widget.questions.length - 1
                            ? () => _goTo(_currentIndex + 1)
                            : _confirmFinishEarly,
                        child: Text(
                          _currentIndex < widget.questions.length - 1
                              ? 'İrəli'
                              : 'İmtahanı bitir',
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
    );
  }
}
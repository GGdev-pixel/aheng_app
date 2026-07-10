import 'dart:math';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/progress_service.dart';

class QuizScreen extends StatefulWidget {
  final Subject subject;

  const QuizScreen({super.key, required this.subject});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Question> _quizQuestions;
  int _currentIndex = 0;
  int _correctCount = 0;
  int? _selectedOption;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    final allQuestions = List<Question>.from(widget.subject.questions);
    allQuestions.shuffle(Random());
    final count = allQuestions.length < 10 ? allQuestions.length : 10;
    _quizQuestions = allQuestions.take(count).toList();
  }

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (index == _quizQuestions[_currentIndex].correctIndex) {
        _correctCount++;
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
      _showResult();
    }
  }

  void _showResult() {
    ProgressService.saveQuizResult(
      subjectId: widget.subject.id,
      answered: _quizQuestions.length,
      correct: _correctCount,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Nəticə'),
        content: Text(
          'Siz ${_quizQuestions.length} sualdan $_correctCount-nə düzgün cavab verdiniz.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
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
    if (_quizQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.subject.name)),
        body: const Center(child: Text('Bu mövzuda sual yoxdur')),
      );
    }

    final question = _quizQuestions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
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
                        : 'Nəticəyə bax',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
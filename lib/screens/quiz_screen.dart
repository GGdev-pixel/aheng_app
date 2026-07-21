import 'dart:math';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/word_scramble_game.dart';
import '../widgets/fill_blank_game.dart';

class QuizScreen extends StatefulWidget {
  final Subject subject;
  final Topic topic;

  const QuizScreen({super.key, required this.subject, required this.topic});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question>? _quizQuestions;
  int _currentIndex = 0;
  int _correctCount = 0;
  int? _selectedOption;
  bool _answered = false;
  List<int?> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final allQuestions =
    await ContentService.getQuestions(widget.subject.id, widget.topic.id).first;
    allQuestions.shuffle(Random());
    final count = allQuestions.length < 10 ? allQuestions.length : 10;
    setState(() {
      _quizQuestions = allQuestions.take(count).toList();
      _userAnswers = List<int?>.filled(_quizQuestions!.length, null);
    });
  }

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
      _answered = true;
      _userAnswers[_currentIndex] = index;
      if (index == _quizQuestions![_currentIndex].correctIndex) {
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _quizQuestions!.length - 1) {
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
      topicId: widget.topic.id,
      answered: _quizQuestions!.length,
      correct: _correctCount,
    );

    final questionsData = List.generate(_quizQuestions!.length, (i) {
      final q = _quizQuestions![i];
      return {
        'text': q.text,
        'options': q.options,
        'correctIndex': q.correctIndex,
        'selectedIndex': _userAnswers[i],
      };
    });

    ProgressService.saveQuizAttempt(
      subjectId: widget.subject.id,
      subjectName: widget.subject.name,
      topicId: widget.topic.id,
      topicName: widget.topic.name,
      questionsData: questionsData,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Nəticə'),
        content: Text(
          'Siz ${_quizQuestions!.length} sualdan $_correctCount-nə düzgün cavab verdiniz.',
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
    if (_quizQuestions == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topic.name)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_quizQuestions!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topic.name)),
        body: const Center(child: Text('Bu mövzuda sual yoxdur')),
      );
    }

    final question = _quizQuestions![_currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text(widget.topic.name)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _quizQuestions!.length,
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
                  'Sual ${_currentIndex + 1} / ${_quizQuestions!.length}',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (question.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              if (question.type == QuestionType.wordScramble)
                Expanded(
                  child: SingleChildScrollView(
                    child: WordScrambleGame(
                      key: ValueKey(question.id),
                      word: question.scrambleWord ?? '',
                      onAnswered: (isCorrect) {
                        setState(() {
                          _answered = true;
                          _userAnswers[_currentIndex] = isCorrect ? 1 : 0;
                          if (isCorrect) _correctCount++;
                        });
                      },
                    ),
                  ),
                )
              else if (question.type == QuestionType.fillBlank)
                Expanded(
                  child: SingleChildScrollView(
                    child: FillBlankGame(
                      key: ValueKey(question.id),
                      sentence: question.blankSentence ?? '',
                      options: question.options,
                      correctIndex: question.correctIndex,
                      onAnswered: (isCorrect) {
                        setState(() {
                          _answered = true;
                          _userAnswers[_currentIndex] = isCorrect ? 1 : 0;
                          if (isCorrect) _correctCount++;
                        });
                      },
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: List.generate(question.options.length, (index) {
                      final isSelected = _selectedOption == index;
                      final isCorrect = index == question.correctIndex;

                      Color borderColor = Colors.grey.shade300;
                      Color bgColor = Colors.white;
                      Color textColor = AppColors.textPrimary;
                      IconData? trailingIcon;

                      if (_answered) {
                        if (isCorrect) {
                          borderColor = AppColors.success;
                          bgColor = AppColors.success.withOpacity(0.08);
                          textColor = AppColors.success;
                          trailingIcon = Icons.check_circle;
                        } else if (isSelected) {
                          borderColor = AppColors.accentRed;
                          bgColor = AppColors.accentRed.withOpacity(0.08);
                          textColor = AppColors.accentRed;
                          trailingIcon = Icons.cancel;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _selectOption(index),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: bgColor,
                              border: Border.all(color: borderColor, width: 1.5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    question.options[index],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                if (trailingIcon != null)
                                  Icon(trailingIcon, color: textColor, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              if (_answered)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextQuestion,
                    child: Text(
                      _currentIndex < _quizQuestions!.length - 1
                          ? 'Növbəti sual'
                          : 'Bitir',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
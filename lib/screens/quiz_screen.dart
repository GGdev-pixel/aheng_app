import 'dart:math';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/word_scramble_game.dart';
import '../widgets/fill_blank_game.dart';
import '../widgets/multi_select_game.dart';

class QuizScreen extends StatefulWidget {
  final Subject subject;
  final Topic topic;
  final int? questionCount;

  const QuizScreen({
    super.key,
    required this.subject,
    required this.topic,
    this.questionCount,
  });

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
  bool get _isFullMode => widget.questionCount == null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (_isFullMode) {
      final saved = await ProgressService.getInProgress(
        widget.subject.id,
        widget.topic.id,
      );
      if (saved != null && mounted) {
        final resume = await _askResume();
        if (resume == true) {
          await _restoreProgress(saved);
          return;
        } else {
          await ProgressService.clearInProgress(widget.subject.id, widget.topic.id);
        }
      }
    }
    await _loadQuestions();
  }

  Future<bool?> _askResume() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Davam etmək'),
        content: const Text(
          'Bu mövzuda yarımçıq qalmış testiniz var. Davam etmək istəyirsiniz, yoxsa yenidən başlayaq?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Yenidən başla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Davam et'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreProgress(Map<String, dynamic> saved) async {
    final ids = List<String>.from(saved['questionIds']);
    final questions = await ContentService.getQuestionsByIds(
      widget.subject.id,
      widget.topic.id,
      ids,
    );
    setState(() {
      _quizQuestions = questions;
      _currentIndex = saved['currentIndex'] ?? 0;
      _userAnswers = List<int?>.from(saved['answers'] ?? []);
      _correctCount = saved['correctCount'] ?? 0;
    });
  }

  Future<void> _loadQuestions() async {
    final allQuestions =
    await ContentService.getQuestions(widget.subject.id, widget.topic.id).first;
    allQuestions.shuffle(Random());

    final requested = widget.questionCount;
    final count = requested == null
        ? allQuestions.length
        : (allQuestions.length < requested ? allQuestions.length : requested);

    setState(() {
      _quizQuestions = allQuestions.take(count).toList();
      _userAnswers = List<int?>.filled(_quizQuestions!.length, null);
    });
  }

  Future<void> _saveProgressIfNeeded() async {
    if (!_isFullMode || _quizQuestions == null) return;
    await ProgressService.saveInProgress(
      subjectId: widget.subject.id,
      topicId: widget.topic.id,
      subjectName: widget.subject.name,
      topicName: widget.topic.name,
      questionIds: _quizQuestions!.map((q) => q.id).toList(),
      currentIndex: _currentIndex,
      answers: _userAnswers,
      correctCount: _correctCount,
    );
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
    _saveProgressIfNeeded();
  }

  void _nextQuestion() {
    if (_currentIndex < _quizQuestions!.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
      _saveProgressIfNeeded();
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

    if (_isFullMode) {
      ProgressService.clearInProgress(widget.subject.id, widget.topic.id);
    }

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

  Widget _buildOptions(Question question) {
    if (question.type == QuestionType.wordScramble) {
      return WordScrambleGame(
        key: ValueKey(question.id),
        word: question.scrambleWord ?? '',
        onAnswered: (isCorrect) {
          setState(() {
            _answered = true;
            _userAnswers[_currentIndex] = isCorrect ? 1 : 0;
            if (isCorrect) _correctCount++;
          });
          _saveProgressIfNeeded();
        },
      );
    } else if (question.type == QuestionType.fillBlank) {
      return FillBlankGame(
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
          _saveProgressIfNeeded();
        },
      );
    } else if (question.type == QuestionType.multiSelect) {
      return MultiSelectGame(
        key: ValueKey(question.id),
        statements: question.statements ?? [],
        correctIndices: question.correctStatementIndices ?? [],
        onAnswered: (isCorrect) {
          setState(() {
            _answered = true;
            _userAnswers[_currentIndex] = isCorrect ? 1 : 0;
            if (isCorrect) _correctCount++;
          });
          _saveProgressIfNeeded();
        },
      );
    } else if (question.type == QuestionType.imageOptions) {
      const letters = ['A', 'B', 'C', 'D', 'E'];
      return GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
        children: List.generate(letters.length, (index) {
          final isSelected = _selectedOption == index;
          final isCorrect = index == question.correctIndex;

          Color borderColor = Colors.grey.shade300;
          Color bgColor = Colors.white;
          Color textColor = AppColors.textPrimary;

          if (_answered) {
            if (isCorrect) {
              borderColor = AppColors.success;
              bgColor = AppColors.success.withOpacity(0.08);
              textColor = AppColors.success;
            } else if (isSelected) {
              borderColor = AppColors.accentRed;
              bgColor = AppColors.accentRed.withOpacity(0.08);
              textColor = AppColors.accentRed;
            }
          }

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _selectOption(index),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.all(color: borderColor, width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                letters[index],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          );
        }),
      );
    }

    return Column(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    _buildOptions(question),
                  ],
                ),
              ),
            ),
            if (_answered)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
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
              ),
          ],
        ),
      ),
    );
  }
}
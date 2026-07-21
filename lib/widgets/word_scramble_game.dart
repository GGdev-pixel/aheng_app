import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WordScrambleGame extends StatefulWidget {
  final String word;
  final Function(bool isCorrect) onAnswered;

  const WordScrambleGame({
    super.key,
    required this.word,
    required this.onAnswered,
  });

  @override
  State<WordScrambleGame> createState() => _WordScrambleGameState();
}

class _WordScrambleGameState extends State<WordScrambleGame> {
  late List<String> _availableLetters;
  late List<String?> _slots;
  bool _checked = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(WordScrambleGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word != widget.word) _setup();
  }

  void _setup() {
    final letters = widget.word.split('');
    letters.shuffle(Random());
    _availableLetters = letters;
    _slots = List<String?>.filled(widget.word.length, null);
    _checked = false;
    _isCorrect = false;
  }

  void _tapAvailable(int index) {
    if (_checked) return;
    final emptySlot = _slots.indexWhere((s) => s == null);
    if (emptySlot == -1) return;
    setState(() {
      _slots[emptySlot] = _availableLetters[index];
      _availableLetters[index] = '';
    });
  }

  void _tapSlot(int index) {
    if (_checked || _slots[index] == null) return;
    setState(() {
      final letter = _slots[index]!;
      final emptyAvailable = _availableLetters.indexWhere((l) => l.isEmpty);
      _availableLetters[emptyAvailable] = letter;
      _slots[index] = null;
    });
  }

  void _check() {
    final built = _slots.join();
    final correct = built.toUpperCase() == widget.word.toUpperCase();
    setState(() {
      _checked = true;
      _isCorrect = correct;
    });
    widget.onAnswered(correct);
  }

  @override
  Widget build(BuildContext context) {
    final allFilled = !_slots.contains(null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: List.generate(_slots.length, (index) {
            final letter = _slots[index];
            return GestureDetector(
              onTap: () => _tapSlot(index),
              child: Container(
                width: 42,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _checked
                      ? (_isCorrect
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.accentRed.withOpacity(0.1))
                      : Colors.white,
                  border: Border.all(
                    color: _checked
                        ? (_isCorrect ? AppColors.success : AppColors.accentRed)
                        : (letter != null ? AppColors.primaryBlue : Colors.grey.shade300),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  letter ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_availableLetters.length, (index) {
            final letter = _availableLetters[index];
            if (letter.isEmpty) return const SizedBox(width: 42, height: 48);
            return GestureDetector(
              onTap: () => _tapAvailable(index),
              child: Container(
                width: 42,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  letter,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        if (!_checked)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: allFilled ? _check : null,
              child: const Text('Yoxla'),
            ),
          ),
      ],
    );
  }
}
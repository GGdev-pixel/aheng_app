import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FillBlankGame extends StatefulWidget {
  final String sentence;
  final List<String> options;
  final int correctIndex;
  final Function(bool isCorrect) onAnswered;

  const FillBlankGame({
    super.key,
    required this.sentence,
    required this.options,
    required this.correctIndex,
    required this.onAnswered,
  });

  @override
  State<FillBlankGame> createState() => _FillBlankGameState();
}

class _FillBlankGameState extends State<FillBlankGame> {
  int? _selectedIndex;
  bool _checked = false;

  void _selectWord(int index) {
    if (_checked) return;
    setState(() => _selectedIndex = index);
  }

  void _check() {
    if (_selectedIndex == null) return;
    final isCorrect = _selectedIndex == widget.correctIndex;
    setState(() => _checked = true);
    widget.onAnswered(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final parts = widget.sentence.split('___');
    final before = parts.isNotEmpty ? parts[0] : '';
    final after = parts.length > 1 ? parts[1] : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(before, style: const TextStyle(fontSize: 18, height: 1.6)),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _checked
                      ? (_selectedIndex == widget.correctIndex
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.accentRed.withOpacity(0.15))
                      : AppColors.primaryBlue.withOpacity(0.1),
                  border: Border.all(
                    color: _checked
                        ? (_selectedIndex == widget.correctIndex
                        ? AppColors.success
                        : AppColors.accentRed)
                        : AppColors.primaryBlue,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedIndex != null ? widget.options[_selectedIndex!] : '...',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Text(after, style: const TextStyle(fontSize: 18, height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: List.generate(widget.options.length, (index) {
            final isSelected = _selectedIndex == index;
            return GestureDetector(
              onTap: () => _selectWord(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : Colors.white,
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  widget.options[index],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
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
              onPressed: _selectedIndex != null ? _check : null,
              child: const Text('Yoxla'),
            ),
          ),
      ],
    );
  }
}
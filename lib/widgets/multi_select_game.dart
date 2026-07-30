import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MultiSelectGame extends StatefulWidget {
  final List<String> statements;
  final List<int> correctIndices;
  final Function(bool isCorrect) onAnswered;

  const MultiSelectGame({
    super.key,
    required this.statements,
    required this.correctIndices,
    required this.onAnswered,
  });

  @override
  State<MultiSelectGame> createState() => _MultiSelectGameState();
}

class _MultiSelectGameState extends State<MultiSelectGame> {
  final Set<int> _selected = {};
  bool _checked = false;

  void _toggle(int index) {
    if (_checked) return;
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  void _check() {
    final correctSet = widget.correctIndices.toSet();
    final isCorrect = _selected.length == correctSet.length &&
        _selected.every((i) => correctSet.contains(i));
    setState(() => _checked = true);
    widget.onAnswered(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final correctSet = widget.correctIndices.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Düzgün variantları seçin',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        ...List.generate(widget.statements.length, (index) {
          final isSelected = _selected.contains(index);
          final isCorrect = correctSet.contains(index);

          Color borderColor = Colors.grey.shade300;
          Color bgColor = Colors.white;

          if (_checked) {
            if (isCorrect) {
              borderColor = AppColors.success;
              bgColor = AppColors.success.withOpacity(0.08);
            } else if (isSelected) {
              borderColor = AppColors.accentRed;
              bgColor = AppColors.accentRed.withOpacity(0.08);
            }
          } else if (isSelected) {
            borderColor = AppColors.primaryBlue;
            bgColor = AppColors.primaryBlue.withOpacity(0.06);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _toggle(index),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: borderColor, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isSelected ? AppColors.primaryBlue : Colors.grey.shade400,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${index + 1}. ${widget.statements[index]}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (_checked && isCorrect)
                      const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    if (_checked && isSelected && !isCorrect)
                      const Icon(Icons.cancel, color: AppColors.accentRed, size: 18),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        if (!_checked)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected.isNotEmpty ? _check : null,
              child: const Text('Yoxla'),
            ),
          ),
      ],
    );
  }
}
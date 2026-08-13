import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import '../widgets/premium_dialog.dart';
import '../theme/app_theme.dart';

class DailySettingsScreen extends StatefulWidget {
  const DailySettingsScreen({super.key});

  @override
  State<DailySettingsScreen> createState() => _DailySettingsScreenState();
}

class _DailySettingsScreenState extends State<DailySettingsScreen> {
  Set<String> _selectedSubjectIds = {};
  int _selectedCount = 10;
  bool _loading = true;
  bool _isPremium = false;
  bool _isAutoMode = false;
  int? _suggestedCount;
  bool _calculatingCount = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _recalculateSuggestedCount() async {
    if (_selectedSubjectIds.isEmpty) {
      setState(() => _suggestedCount = null);
      return;
    }

    setState(() => _calculatingCount = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final examTs = userDoc.data()?['examDate'];

    int daysLeft = 30;
    if (examTs != null) {
      final examDate = (examTs as Timestamp).toDate();
      final diff = examDate.difference(DateTime.now()).inDays;
      daysLeft = diff > 0 ? diff : 1;
    }

    int totalQuestions = 0;
    for (var subjectId in _selectedSubjectIds) {
      final questions = await ContentService.getAllQuestionsForSubject(subjectId);
      totalQuestions += questions.length;
    }

    int suggested = (totalQuestions / daysLeft).ceil();
    suggested = ((suggested / 5).round() * 5).clamp(10, 40);

    setState(() {
      _suggestedCount = suggested;
      _selectedCount = suggested;
      _calculatingCount = false;
    });
  }

  Future<void> _loadCurrentSettings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    _isPremium = doc.data()?['isPremium'] == true;

    final data = doc.data();
    if (data != null && data['dailySettings'] != null) {
      final settings = data['dailySettings'] as Map<String, dynamic>;
      setState(() {
        _selectedSubjectIds =
        Set<String>.from(settings['subjectIds'] ?? []);
        _selectedCount = settings['count'] ?? 10;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (_selectedSubjectIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ən azı bir fənn seçin')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'dailySettings': {
        'subjectIds': _selectedSubjectIds.toList(),
        'count': _selectedCount,
      },
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gündəlik suallar')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Subject>>(
        stream: ContentService.getSubjects(),
        builder: (context, snapshot) {
          final subjects = snapshot.data ?? [];

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Fənlər',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (!_isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '1 fənn (pulsuz)',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...subjects.map((subject) {
                      return CheckboxListTile(
                        title: Text('${subject.icon} ${subject.name}'),
                        value: _selectedSubjectIds.contains(subject.id),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              if (!_isPremium && _selectedSubjectIds.isNotEmpty) {
                                PremiumDialog.show(
                                  context,
                                  message: 'Bir neçə fənn üzrə gündəlik suallar üçün Premium abunəlik lazımdır.',
                                );
                                return;
                              }
                              _selectedSubjectIds.add(subject.id);
                            } else {
                              _selectedSubjectIds.remove(subject.id);
                            }
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 24),
                    const Text(
                      'Sual sayı',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ...[10, 20, 30].map((count) {
                          final isSelected = !_isAutoMode && _selectedCount == count;
                          return ChoiceChip(
                            label: Text('$count'),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _isAutoMode = false;
                                _selectedCount = count;
                              });
                            },
                          );
                        }),
                        ChoiceChip(
                          label: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 14),
                              SizedBox(width: 4),
                              Text('Avto'),
                            ],
                          ),
                          selected: _isAutoMode,
                          onSelected: (_) async {
                            setState(() => _isAutoMode = true);
                            await _recalculateSuggestedCount();
                          },
                        ),
                      ],
                    ),
                    if (_isAutoMode) ...[
                      const SizedBox(height: 12),
                      if (_calculatingCount)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ))
                      else if (_suggestedCount != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: AppColors.primaryBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$_suggestedCount sual/gün təklif olunur. Hesablama: seçilmiş fənlərdəki cavablanmamış sualların sayı, imtahana qalan günlərə bölünür (imtahan tarixi təyin olunmayıbsa, 30 gün əsas götürülür).',
                                  style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Yadda saxla'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
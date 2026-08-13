import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import '../widgets/premium_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
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
                      children: [10, 20, 30].map((count) {
                        final isSelected = _selectedCount == count;
                        return ChoiceChip(
                          label: Text('$count'),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedCount = count);
                          },
                        );
                      }).toList(),
                    ),
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
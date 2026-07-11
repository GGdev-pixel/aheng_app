import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import 'manage_subjects_screen.dart';
import 'dart:math';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _StudentsListView(),
      const ManageSubjectsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Tələbələr' : 'Fənlərin idarəsi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Tələbələr',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: 'Fənlər',
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _ensureInviteCode();
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _ensureInviteCode() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (doc.data()?['inviteCode'] == null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'inviteCode': _generateCode(),
      });
    }
  }
}

class _StudentsListView extends StatelessWidget {
  const _StudentsListView();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .snapshots(),
          builder: (context, snapshot) {
            final code = (snapshot.data?.data()
            as Map<String, dynamic>?)?['inviteCode'];
            if (code == null) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tələbə kodu:', style: TextStyle(fontSize: 12)),
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: StreamBuilder<List<Subject>>(
            stream: ContentService.getSubjects(),
            builder: (context, subjectsSnapshot) {
              final subjects = subjectsSnapshot.data ?? [];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'student')
                    .where('teacherId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final students = snapshot.data?.docs ?? [];

                  if (students.isEmpty) {
                    return const Center(child: Text('Hələ tələbə yoxdur'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final studentDoc = students[index];
                      final studentData =
                      studentDoc.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          title: Text(
                            studentData['name'] ?? studentData['email'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(studentData['email'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_remove_outlined, color: Colors.red, size: 20),
                            onPressed: () => _removeStudent(
                              context,
                              studentDoc.id,
                              studentData['name'] ?? studentData['email'] ?? '',
                            ),
                          ),
                          children: [
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(studentDoc.id)
                                  .collection('progress')
                                  .snapshots(),
                              builder: (context, progressSnapshot) {
                                if (!progressSnapshot.hasData) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final progressDocs = progressSnapshot.data!.docs;

                                if (progressDocs.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('Hələ test edilməyib'),
                                  );
                                }

                                return Column(
                                  children: progressDocs.map((doc) {
                                    final progData =
                                    doc.data() as Map<String, dynamic>;
                                    final answered = progData['answered'] ?? 0;
                                    final correct = progData['correct'] ?? 0;
                                    final percent = answered > 0
                                        ? (correct / answered * 100)
                                        : 0;
                                    final subjectId = progData['subjectId'] ?? '';

                                    final subject = subjects.firstWhere(
                                          (s) => s.id == subjectId,
                                      orElse: () => const Subject(
                                          id: '', name: '?', icon: '📚', order: 0),
                                    );

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${subject.icon} ${subject.name}'),
                                          Text('${percent.toStringAsFixed(0)}%'),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
Future<void> _removeStudent(BuildContext context, String studentId, String studentName) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Tələbəni silmək'),
      content: Text('"$studentName" siyahıdan silinsin? Onun nəticələri qorunacaq.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Ləğv et'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sil', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(studentId)
        .update({'teacherId': FieldValue.delete()});
  }
}
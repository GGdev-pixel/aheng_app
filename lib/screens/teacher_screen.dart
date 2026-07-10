import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/mock_data.dart';

class TeacherScreen extends StatelessWidget {
  const TeacherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tələbələr'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
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
              final studentData = studentDoc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    studentData['name'] ?? studentData['email'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(studentData['email'] ?? ''),
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
                            final progData = doc.data() as Map<String, dynamic>;
                            final answered = progData['answered'] ?? 0;
                            final correct = progData['correct'] ?? 0;
                            final percent =
                            answered > 0 ? (correct / answered * 100) : 0;

                            final subject = mockSubjects.firstWhere(
                                  (s) => s.id == doc.id,
                              orElse: () => mockSubjects.first,
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
      ),
    );
  }
}
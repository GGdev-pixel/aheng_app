import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import 'manage_topics_screen.dart';

class ManageSubjectsScreen extends StatelessWidget {
  const ManageSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Subject>>(
      stream: ContentService.getSubjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final subjects = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Text(subject.icon, style: const TextStyle(fontSize: 28)),
                title: Text(
                  subject.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageTopicsScreen(subject: subject),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
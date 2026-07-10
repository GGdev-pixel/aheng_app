import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import 'quiz_screen.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockSubjects.length,
      itemBuilder: (context, index) {
        final subject = mockSubjects[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Text(subject.icon, style: const TextStyle(fontSize: 32)),
            title: Text(
              subject.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${subject.questions.length} sual'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(subject: subject),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
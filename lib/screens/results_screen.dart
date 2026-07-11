import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/progress_service.dart';
import 'result_detail_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: ProgressService.getResultsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = (snapshot.data?.docs ?? [])
            .where((doc) => (doc.data() as Map<String, dynamic>)['subjectId'] != 'daily')
            .toList();

        if (results.isEmpty) {
          return const Center(child: Text('Hələ test edilməyib'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final doc = results[index];
            final data = doc.data() as Map<String, dynamic>;

            final answered = data['answered'] ?? 0;
            final correct = data['correct'] ?? 0;
            final percent = answered > 0 ? (correct / answered * 100) : 0;
            final timestamp = data['timestamp'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  '${data['subjectName']} · ${data['topicName']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  timestamp != null
                      ? _formatDate(timestamp.toDate())
                      : '',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${percent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: percent >= 70
                            ? Colors.green
                            : percent >= 40
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                    Text(
                      '$correct/$answered',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultDetailScreen(
                        subjectName: data['subjectName'],
                        topicName: data['topicName'],
                        questions: List<Map<String, dynamic>>.from(
                          (data['questions'] as List).map(
                                (q) => Map<String, dynamic>.from(q),
                          ),
                        ),
                      ),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
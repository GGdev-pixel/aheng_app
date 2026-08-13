import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/content_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import 'weak_topic_questions_screen.dart';

class _TopicProgress {
  final String subjectId;
  final String topicId;
  final int answered;
  final int correct;

  _TopicProgress(this.subjectId, this.topicId, this.answered, this.correct);
  double get percent => answered > 0 ? correct / answered : 0;
}

class WeakTopicsScreen extends StatefulWidget {
  final String? userId;

  const WeakTopicsScreen({super.key, this.userId});

  @override
  State<WeakTopicsScreen> createState() => _WeakTopicsScreenState();
}

class _WeakTopicsScreenState extends State<WeakTopicsScreen> {
  bool _ascending = true;
  bool _loadingLookup = true;
  Map<String, Subject> _subjectsById = {};
  Map<String, Topic> _topicsById = {};

  @override
  void initState() {
    super.initState();
    _loadLookup();
  }

  Future<void> _loadLookup() async {
    final subjects = await ContentService.getSubjectsOnce();
    final subjectMap = {for (var s in subjects) s.id: s};

    final topicMap = <String, Topic>{};
    for (var subject in subjects) {
      final topicsSnapshot = await ContentService.getTopics(subject.id).first;
      for (var topic in topicsSnapshot) {
        topicMap['${subject.id}_${topic.id}'] = topic;
      }
    }

    if (mounted) {
      setState(() {
        _subjectsById = subjectMap;
        _topicsById = topicMap;
        _loadingLookup = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zəif tərəflər'),
        actions: [
          IconButton(
            icon: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: _ascending ? 'Aşağıdan yuxarı' : 'Yuxarıdan aşağı',
            onPressed: () {
              setState(() => _ascending = !_ascending);
            },
          ),
        ],
      ),
      body: _loadingLookup
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder(
        stream: ProgressService.getProgressStream(userId: widget.userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = (snapshot.data as dynamic).docs as List;
          final entries = <_TopicProgress>[];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final answered = data['answered'] ?? 0;
            if (answered <= 0) continue;
            final subjectId = data['subjectId'];
            final topicId = data['topicId'];
            if (subjectId == null || topicId == null) continue;
            if (!_subjectsById.containsKey(subjectId)) continue;
            if (!_topicsById.containsKey('${subjectId}_$topicId')) continue;
            entries.add(_TopicProgress(subjectId, topicId, answered, data['correct'] ?? 0));
          }

          if (entries.isEmpty) {
            return const Center(child: Text('Hələ statistika yoxdur'));
          }

          entries.sort((a, b) => _ascending
              ? a.percent.compareTo(b.percent)
              : b.percent.compareTo(a.percent));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final item = entries[index];
              final subject = _subjectsById[item.subjectId]!;
              final topic = _topicsById['${item.subjectId}_${item.topicId}']!;
              final percentText = (item.percent * 100).toStringAsFixed(0);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  title: Text(topic.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle:
                  Text('${subject.icon} ${subject.name} · ${item.correct}/${item.answered}'),
                  trailing: Text(
                    '$percentText%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: item.percent >= 0.7
                          ? AppColors.success
                          : item.percent >= 0.4
                          ? AppColors.warning
                          : AppColors.accentRed,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WeakTopicQuestionsScreen(
                          subject: subject,
                          topic: topic,
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
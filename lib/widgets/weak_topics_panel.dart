import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../screens/weak_topics_screen.dart';

class WeakTopicsPanel extends StatelessWidget {
  final String? userId;
  static const int minTopicsRequired = 10;

  const WeakTopicsPanel({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ProgressService.getProgressStream(userId: userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = (snapshot.data as dynamic).docs as List;
        int completedTopics = 0;
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if ((data['answered'] ?? 0) > 0) completedTopics++;
        }

        if (completedTopics < minTopicsRequired) {
          return _buildGauge(completedTopics);
        }

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WeakTopicsScreen(userId: userId),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentRed.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentRed.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights_outlined, color: AppColors.accentRed),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Zəif tərəflər',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.accentRed),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGauge(int completed) {
    final progress = completed / minTopicsRequired;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_outlined, color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Zəif tərəflərin aşkarlanması',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$completed/$minTopicsRequired mövzu tamamlayın ki, zəif tərəflərinizi müəyyən edək',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
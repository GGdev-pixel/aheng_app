import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumDialog {
  static Future<void> show(BuildContext context, {String? message}) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium,
                    color: AppColors.primaryBlue, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Premium funksiya',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message ?? 'Bu funksiyadan istifadə etmək üçün Premium abunəlik lazımdır.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Premium alış ekranına keçid (hazır olduqda)
                  },
                  child: const Text('Premium haqqında'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Bağla'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
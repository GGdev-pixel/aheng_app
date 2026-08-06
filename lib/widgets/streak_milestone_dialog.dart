import 'package:flutter/material.dart';
import 'streak_flame_icon.dart';
import 'confetti_overlay.dart';

class StreakMilestoneDialog extends StatefulWidget {
  final int streak;

  const StreakMilestoneDialog({super.key, required this.streak});

  @override
  State<StreakMilestoneDialog> createState() => _StreakMilestoneDialogState();

  static Future<void> show(BuildContext context, int streak) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Milestone',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Stack(
            children: [
        const Positioned.fill(child: ConfettiOverlay()),
             StreakMilestoneDialog(streak: streak),
            ],
        );
      },
     transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.elasticOut);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}

class _StreakMilestoneDialogState extends State<StreakMilestoneDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.12);
                return Transform.scale(
                  scale: scale,
                  child: StreakFlameIcon(streak: widget.streak, baseSize: 64),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              '${widget.streak} gün ardıcıl!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _messageFor(widget.streak),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Davam et'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _messageFor(int streak) {
    if (streak >= 100) return 'İnanılmazsınız! 100 gün ardıcıl!';
    if (streak >= 70) return 'Möhtəşəm nəticə, davam edin!';
    if (streak >= 50) return 'Yarım yüz gün! Əla gedirsiniz!';
    if (streak >= 20) return 'Sabit tempdə davam edirsiniz!';
    if (streak >= 10) return 'Gözəl başlanğıc!';
    return 'Davam edin!';
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'statistics_screen.dart';
import 'results_screen.dart';
import '../theme/theme_controller.dart';
import '../widgets/premium_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _ProfileMenuCard(
            icon: Icons.bar_chart_rounded,
            title: 'Statistika',
            subtitle: 'Fənlər üzrə nəticələriniz',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Statistika')),
                    body: const StatisticsScreen(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _ProfileMenuCard(
            icon: Icons.history_rounded,
            title: 'Nəticələr',
            subtitle: 'Keçmiş testləriniz',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Nəticələr')),
                    body: const ResultsScreen(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _TeacherCodeCard(),
          const SizedBox(height: 16),
          const _DarkModeSwitch(),
          const SizedBox(height: 24),
          const SizedBox(height: 16),
          const _ExamDatePicker(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Çıxış'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentRed,
                side: const BorderSide(color: AppColors.accentRed),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherCodeCard extends StatefulWidget {
  @override
  State<_TeacherCodeCard> createState() => _TeacherCodeCardState();
}

class _TeacherCodeCardState extends State<_TeacherCodeCard> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submitCode() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final teacherQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();

    if (teacherQuery.docs.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Kod tapılmadı';
      });
      return;
    }

    final teacherId = teacherQuery.docs.first.id;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'teacherId': teacherId,
    });

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final teacherId =
        (snapshot.data?.data() as Map<String, dynamic>?)?['teacherId'];

        if (teacherId != null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Müəllimə qoşulmusunuz'),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Müəllim kodu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Kodu daxil edin',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submitCode,
                  child: _loading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Təsdiqlə'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
class _ProfileMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
class _DarkModeSwitch extends StatefulWidget {
  const _DarkModeSwitch();

  @override
  State<_DarkModeSwitch> createState() => _DarkModeSwitchState();
}

class _DarkModeSwitchState extends State<_DarkModeSwitch> {
  bool _isPremium = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkPremium();
  }

  Future<void> _checkPremium() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final isPremium = doc.data()?['isPremium'] == true;
    final savedDark = doc.data()?['darkModeEnabled'] == true;

    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _loading = false;
      });
    }

    if (savedDark) {
      ThemeController.themeMode.value = ThemeMode.dark;
    }
  }

  Future<void> _toggle(bool value) async {
    ThemeController.themeMode.value = value ? ThemeMode.dark : ThemeMode.light;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'darkModeEnabled': value,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                mode == ThemeMode.dark ? Icons.dark_mode : Icons.dark_mode_outlined,
                size: 20,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Tünd rejim', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              Switch(
                value: mode == ThemeMode.dark,
                onChanged: _toggle,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExamDatePicker extends StatefulWidget {
  const _ExamDatePicker();

  @override
  State<_ExamDatePicker> createState() => _ExamDatePickerState();
}

class _ExamDatePickerState extends State<_ExamDatePicker> {
  DateTime? _examDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final ts = doc.data()?['examDate'];
    if (ts != null && mounted) {
      setState(() => _examDate = (ts as Timestamp).toDate());
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'examDate': Timestamp.fromDate(picked),
    });
    setState(() => _examDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final text = _examDate == null
        ? 'İmtahan tarixi təyin edilməyib'
        : '${_examDate!.day}.${_examDate!.month.toString().padLeft(2, '0')}.${_examDate!.year}';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.event_outlined, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('İmtahan tarixi', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
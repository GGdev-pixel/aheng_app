import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.school_outlined,
      title: 'Dövlət qulluğu imtahanına hazırlaşın',
      description: 'Ahəng ilə Qanunvericilik, Məntiq, Azərbaycan dili və İnformatika üzrə minlərlə sual həll edin.',
    ),
    _OnboardingPage(
      icon: Icons.local_fire_department_outlined,
      title: 'Gündəlik məşq edin',
      description: 'Hər gün qısa testlərlə biliyinizi möhkəmləndirin və ardıcıl gün seriyanızı qoruyun.',
    ),
    _OnboardingPage(
      icon: Icons.insights_outlined,
      title: 'Zəif tərəflərinizi tapın',
      description: 'Sistem test nəticələrinizə əsasən ən zəif mövzularınızı müəyyən edir və tövsiyələr verir.',
    ),
    _OnboardingPage(
      icon: Icons.timer_outlined,
      title: 'İmtahana tam hazır olun',
      description: 'İmtahan rejimi ilə real şəraitdə məşq edin, tarixi təyin edin, planınızı izləyin.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Keç'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 56, color: AppColors.primaryBlue),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.4),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryBlue : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLastPage) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(isLastPage ? 'Başlayaq' : 'Növbəti'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
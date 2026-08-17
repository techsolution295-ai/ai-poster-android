import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/app_button.dart';
import '../home/home_shell.dart';

class _Page {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Page(this.icon, this.title, this.subtitle);
}

/// First-launch onboarding carousel.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _Page(Icons.auto_awesome, 'Auto-generated templates',
        'Fresh poster templates are created for you from free stock photos and smart layouts — no design skills needed.'),
    _Page(Icons.edit, 'Powerful, simple editor',
        'Edit text, fonts, colours, logo and background. Drag, resize and rotate anything.'),
    _Page(Icons.download_rounded, 'Export & share instantly',
        'Save your poster as JPG or PNG in Instagram, Facebook or A4 sizes and share anywhere.'),
  ];

  Future<void> _finish() async {
    await LocalStorageService.instance.setOnboardingDone();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            gradient: AppColors.headerGradient,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(p.icon, size: 72, color: Colors.white),
                        ),
                        const SizedBox(height: 36),
                        Text(p.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 14),
                        Text(p.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 15, height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: AppButton(
                label: last ? 'Get Started' : 'Next',
                icon: last ? Icons.check : Icons.arrow_forward,
                onPressed: () {
                  if (last) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

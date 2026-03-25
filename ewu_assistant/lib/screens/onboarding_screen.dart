import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  static const String onboardingKey = 'onboarding_complete';

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  final List<_OnboardingItem> _items = const <_OnboardingItem>[
    _OnboardingItem(
      icon: Icons.mic_rounded,
      title: 'Ask With Your Voice',
      description:
          'Talk naturally and get quick answers about admissions, tuition, campus life, and more.',
    ),
    _OnboardingItem(
      icon: Icons.chat_bubble_rounded,
      title: 'Chat Anytime',
      description:
          'Switch to text chat when you want a quieter, scrollable conversation with the assistant.',
    ),
    _OnboardingItem(
      icon: Icons.groups_rounded,
      title: 'Join The Campus Feed',
      description:
          'Share posts, ask for help, and reply to classmates through the campus social feed.',
    ),
    _OnboardingItem(
      icon: Icons.photo_library_rounded,
      title: 'Explore The Gallery',
      description:
          'Upload campus moments, browse student snapshots, and keep up with university life.',
    ),
  ];

  int _pageIndex = 0;

  Future<void> _completeOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.onboardingKey, true);
    widget.onFinished();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _pageIndex == _items.length - 1;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text('Skip'),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _items.length,
                    onPageChanged: (int index) {
                      setState(() {
                        _pageIndex = index;
                      });
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final _OnboardingItem item = _items[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            height: 124,
                            width: 124,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryDark,
                              borderRadius: BorderRadius.circular(34),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x220A1F44),
                                  blurRadius: 24,
                                  offset: Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Icon(
                              item.icon,
                              size: 54,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(
                    _items.length,
                    (int index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _pageIndex == index ? 28 : 8,
                      decoration: BoxDecoration(
                        color: _pageIndex == index
                            ? AppTheme.primaryDark
                            : AppTheme.divider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLastPage
                        ? _completeOnboarding
                        : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOut,
                            );
                          },
                    child: Text(isLastPage ? 'Get Started' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

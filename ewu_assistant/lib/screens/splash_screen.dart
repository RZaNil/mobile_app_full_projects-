import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_branding.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _timer = Timer(const Duration(seconds: 2), widget.onCompleted);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const AppBrandLockup(
                    centered: true,
                    markSize: 104,
                    wordmarkHeight: 44,
                    subtitle:
                        'Voice-enabled campus help for East West University',
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Campus super app',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

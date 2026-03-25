import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/chat_provider.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final List<Object?> bootstrapResults = await Future.wait<Object?>(
    <Future<Object?>>[
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      SharedPreferences.getInstance(),
      SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
        DeviceOrientation.portraitUp,
      ]),
    ],
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.navBarBg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final SharedPreferences prefs = bootstrapResults[1] as SharedPreferences;
  final bool onboardingComplete =
      prefs.getBool(OnboardingScreen.onboardingKey) ?? false;

  runApp(EwuAssistantApp(onboardingComplete: onboardingComplete));
}

class EwuAssistantApp extends StatelessWidget {
  const EwuAssistantApp({super.key, required this.onboardingComplete});

  final bool onboardingComplete;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatProvider>(
      create: (_) => ChatProvider(),
      child: MaterialApp(
        title: 'EWU Assistant',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: AppLauncher(initialOnboardingComplete: onboardingComplete),
      ),
    );
  }
}

class MyApp extends EwuAssistantApp {
  const MyApp({super.key}) : super(onboardingComplete: false);
}

class AppLauncher extends StatefulWidget {
  const AppLauncher({super.key, required this.initialOnboardingComplete});

  final bool initialOnboardingComplete;

  @override
  State<AppLauncher> createState() => _AppLauncherState();
}

class _AppLauncherState extends State<AppLauncher> {
  late bool _onboardingComplete = widget.initialOnboardingComplete;
  bool _showSplash = true;

  Future<void> _handleLoginSuccess() async {
    await context.read<ChatProvider>().refreshProfile();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _handleSignedOut() async {
    final ChatProvider provider = context.read<ChatProvider>();
    provider.clearMessages();
    await provider.refreshProfile();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _handleOnboardingFinished() {
    if (!mounted) {
      return;
    }
    setState(() {
      _onboardingComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = AuthService.isLoggedIn;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _showSplash
          ? SplashScreen(
              key: const ValueKey<String>('splash'),
              onCompleted: () {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _showSplash = false;
                });
              },
            )
          : !_onboardingComplete
          ? OnboardingScreen(
              key: const ValueKey<String>('onboarding'),
              onFinished: _handleOnboardingFinished,
            )
          : !isLoggedIn
          ? LoginScreen(
              key: const ValueKey<String>('login'),
              onLoginSuccess: _handleLoginSuccess,
            )
          : HomeShell(
              key: const ValueKey<String>('home_shell'),
              onSignedOut: _handleSignedOut,
            ),
    );
  }
}

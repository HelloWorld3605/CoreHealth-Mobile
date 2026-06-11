import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/app_controller.dart';
import 'src/data/app_repository.dart';
import 'src/data/memory_app_repository.dart';
import 'src/data/remote_app_repository.dart';
import 'src/services/environment_config.dart';
import 'src/models.dart';
import 'src/screens/auth_screen.dart';
import 'src/screens/home_shell.dart';
import 'src/screens/intro_screen.dart';
import 'src/screens/onboarding_screen.dart';
import 'src/screens/plan_generating_screen.dart';
import 'src/screens/welcome_screen.dart';
import 'src/screens/otp_verification_screen.dart';
import 'src/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CoreHealthAppLoader());
}

class CoreHealthAppLoader extends StatefulWidget {
  const CoreHealthAppLoader({super.key});

  @override
  State<CoreHealthAppLoader> createState() => _CoreHealthAppLoaderState();
}

class _CoreHealthAppLoaderState extends State<CoreHealthAppLoader> {
  AppController? _controller;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final repository = await _createRepository();
    final controller = AppController(repository: repository);
    unawaited(
      controller.initialize().catchError((Object error, StackTrace stackTrace) {
        debugPrint('App initialization failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }),
    );
    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildCoreHealthTheme(),
        home: const _BootstrapScreen(),
      );
    }
    return CoreHealthApp(controller: _controller!);
  }
}

Future<AppRepository> _createRepository() async {
  // Single source of truth: the shared CoreHealth backend. The app never
  // connects to Postgres directly and embeds no third-party secrets.
  // Debug builds may opt into an offline in-memory repository for UI work via
  // --dart-define=COREHEALTH_OFFLINE=true; release builds always go remote.
  const offline = bool.fromEnvironment('COREHEALTH_OFFLINE');
  if (!kReleaseMode && offline) {
    return MemoryAppRepository();
  }

  final remote = RemoteAppRepository(baseUrl: EnvironmentConfig.apiBaseUrl);
  await remote.init();
  return remote;
}

class CoreHealthApp extends StatelessWidget {
  const CoreHealthApp({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return CoreHealthScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'CoreHealth',
            theme: buildCoreHealthTheme(),
            home: !controller.isReady
                ? const _BootstrapScreen()
                : switch (controller.stage) {
                    AppStage.welcome => const WelcomeScreen(),
                    AppStage.intro => const IntroScreen(),
                    AppStage.auth => const AuthScreen(),
                    AppStage.verifyOtp => const OtpVerificationScreen(),
                    AppStage.onboarding => const OnboardingScreen(),
                    AppStage.generatingPlan => const PlanGeneratingScreen(),
                    AppStage.home => const HomeShell(),
                  },
          );
        },
      ),
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

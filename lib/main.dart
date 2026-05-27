import 'dart:async';

import 'package:flutter/material.dart';

import 'src/app_controller.dart';
import 'src/data/local_app_repository.dart';
import 'src/data/remote_app_repository.dart';
import 'src/models.dart';
import 'src/screens/auth_screen.dart';
import 'src/screens/home_shell.dart';
import 'src/screens/intro_screen.dart';
import 'src/screens/onboarding_screen.dart';
import 'src/screens/welcome_screen.dart';
import 'src/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const apiBaseUrl = String.fromEnvironment('COREHEALTH_API_BASE_URL');
  final AppRepository repository;
  if (apiBaseUrl.isEmpty) {
    repository = LocalAppRepository();
  } else {
    final remote = RemoteAppRepository(baseUrl: apiBaseUrl);
    await remote.init();
    repository = remote;
  }
  final controller = AppController(repository: repository);
  unawaited(controller.initialize());
  runApp(CoreHealthApp(controller: controller));
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
                    AppStage.onboarding => const OnboardingScreen(),
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

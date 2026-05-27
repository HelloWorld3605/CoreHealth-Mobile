import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'src/app_controller.dart';
import 'src/data/local_app_repository.dart';
import 'src/data/postgres_app_repository.dart';
import 'src/data/remote_app_repository.dart';
import 'src/models.dart';
import 'src/screens/auth_screen.dart';
import 'src/screens/home_shell.dart';
import 'src/screens/intro_screen.dart';
import 'src/screens/onboarding_screen.dart';
import 'src/screens/welcome_screen.dart';
import 'src/screens/otp_verification_screen.dart';
import 'src/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const apiBaseUrl = String.fromEnvironment('COREHEALTH_API_BASE_URL');
  const postgresEnabled =
      bool.fromEnvironment('COREHEALTH_POSTGRES_ENABLED', defaultValue: true);
  final AppRepository repository;
  if (apiBaseUrl.isNotEmpty) {
    final remote = RemoteAppRepository(baseUrl: apiBaseUrl);
    await remote.init();
    repository = remote;
  } else if (postgresEnabled) {
    const configuredHost = String.fromEnvironment('COREHEALTH_POSTGRES_HOST');
    final host = configuredHost.isNotEmpty
        ? configuredHost
        : Platform.isAndroid
            ? '10.0.2.2'
            : 'localhost';
    const database = String.fromEnvironment(
      'COREHEALTH_POSTGRES_DATABASE',
      defaultValue: 'corehealth',
    );
    const username = String.fromEnvironment(
      'COREHEALTH_POSTGRES_USER',
      defaultValue: 'postgres',
    );
    const password = String.fromEnvironment(
      'COREHEALTH_POSTGRES_PASSWORD',
      defaultValue: '123456',
    );
    const port = int.fromEnvironment(
      'COREHEALTH_POSTGRES_PORT',
      defaultValue: 5432,
    );
    final postgres = PostgresAppRepository(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
    );
    await postgres.init();
    repository = postgres;
  } else {
    repository = LocalAppRepository();
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
                    AppStage.verifyOtp => const OtpVerificationScreen(),
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

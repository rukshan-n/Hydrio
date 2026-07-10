import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/hydrio_provider.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/welcome_screen.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize notification service
  final notificationService = NotificationService.instance;
  await notificationService.init();

  // Create provider state and initialize it
  final provider = HydrioProvider();
  await provider.initialize();

  // Request permissions in background (non-blocking)
  notificationService.requestPermissions();

  runApp(
    ChangeNotifierProvider<HydrioProvider>.value(
      value: provider,
      child: const HydrioApp(),
    ),
  );
}

class HydrioApp extends StatelessWidget {
  const HydrioApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Choose theme dynamically based on setting
    final themeSetting = context.select<HydrioProvider, String>((p) => p.settings.theme);
    
    ThemeMode themeMode;
    switch (themeSetting.toLowerCase()) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    return MaterialApp(
      title: 'Hydrio',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const HydrioGateway(),
    );
  }
}

/// A gateway widget that dynamically displays either the WelcomeScreen or the
/// home dashboard depending on whether onboarding has been completed.
class HydrioGateway extends StatelessWidget {
  const HydrioGateway({super.key});

  @override
  Widget build(BuildContext context) {
    final onboardingComplete = context.select<HydrioProvider, bool>(
      (p) => p.settings.onboardingComplete,
    );

    if (onboardingComplete) {
      return const HomeScreen();
    } else {
      return const WelcomeScreen();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/hydrio_provider.dart';
import 'core/theme/theme.dart';

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
      theme: HydrioTheme.lightTheme,
      darkTheme: HydrioTheme.darkTheme,
      themeMode: themeMode,
      home: const HydrioPlaceholderHome(),
    );
  }
}

/// A minimal placeholder home screen to verify the core base classes and compilation.
class HydrioPlaceholderHome extends StatelessWidget {
  const HydrioPlaceholderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hydrio Core'),
      ),
      body: Center(
        child: Consumer<HydrioProvider>(
          builder: (context, provider, child) {
            final target = provider.calculatedDailyTarget;
            final current = provider.todaySummary?.totalMl ?? 0;
            final message = provider.encouragingMessage;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.water_drop,
                    color: Colors.blue,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hydrio Engine Active',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Goal: $current / $target ml (${provider.settings.unit})',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      provider.logDrink(250);
                    },
                    child: const Text('Quick Add 250ml'),
                  ),
                  if (provider.hasUndoItem) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        provider.undoDelete();
                      },
                      child: const Text('Undo last action'),
                    ),
                  ]
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

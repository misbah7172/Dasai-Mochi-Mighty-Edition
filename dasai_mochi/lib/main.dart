import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'services/local_storage_service.dart';
import 'services/ble_service.dart';
import 'services/voice_service.dart';
import 'services/music_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'utils/theme.dart';
import 'utils/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load and validate environment configuration
  try {
    await AppConfig.initialize();
    
    // Validate required configurations
    final configErrors = AppConfig.validateConfig();
    if (configErrors.isNotEmpty) {
      debugPrint('Configuration warnings:');
      for (final error in configErrors) {
        debugPrint('- $error');
      }
    }
    
    debugPrint('Environment: ${AppConfig.appEnvironment}');
    debugPrint('Debug mode: ${AppConfig.debugMode}');
  } catch (e) {
    debugPrint('Configuration error: $e');
    // You can choose to continue with default values or exit
  }
  
  // Initialize notifications
  await _initializeNotifications();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const DasaiMochiApp());
}

Future<void> _initializeNotifications() async {
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelGroupKey: 'mochi_group',
        channelKey: 'mochi_reminders',
        channelName: 'Mochi Reminders',
        channelDescription: 'Notifications for Mochi reminders and alerts',
        defaultColor: MochiTheme.pastelColors['babyBlue']!,
        ledColor: Colors.white,
        playSound: true,
        enableVibration: true,
        importance: NotificationImportance.High,
        defaultRingtoneType: DefaultRingtoneType.Notification,
      ),
      NotificationChannel(
        channelGroupKey: 'mochi_group',
        channelKey: 'mochi_chat',
        channelName: 'Mochi Chat',
        channelDescription: 'Notifications for Mochi messages and interactions',
        defaultColor: MochiTheme.pastelColors['softPink']!,
        ledColor: Colors.white,
        playSound: true,
        enableVibration: true,
        importance: NotificationImportance.Default,
        defaultRingtoneType: DefaultRingtoneType.Notification,
      ),
    ],
  );
  
  // Request notification permissions
  await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });
}

class DasaiMochiApp extends StatelessWidget {
  const DasaiMochiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocalStorageService()),
        ChangeNotifierProvider(create: (_) => BLEService()),
        ChangeNotifierProvider(create: (_) => VoiceService()),
        ChangeNotifierProvider(create: (_) => MusicService()),
      ],
      child: Consumer<LocalStorageService>(
        builder: (context, storageService, _) {
          return MaterialApp(
            title: 'Dasai Mochi',
            debugShowCheckedModeBanner: false,
            theme: MochiTheme.buildTheme('default'),
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final storageService = Provider.of<LocalStorageService>(context, listen: false);
    
    try {
      // Initialize storage service
      await storageService.initialize();
      
      // Wait for splash screen duration
      await Future.delayed(const Duration(seconds: 3));
      
      if (!mounted) return;
      
      // Mark as initialized to trigger navigation
      setState(() {
        _isInitialized = true;
      });
      
    } catch (e) {
      debugPrint('Initialization error: $e');
      // Still navigate even if there are errors
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      // Force show login screen for demo - change this back for production
      // return _isSetupComplete ? const DashboardScreen() : const LoginScreen();
      return const LoginScreen(); // Always show login to demonstrate the full flow
    }
    return const SplashScreen();
  }
}
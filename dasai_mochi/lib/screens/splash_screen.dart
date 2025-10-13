import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/theme.dart';
import '../components/mochi_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MochiTheme.pastelColors['blue'],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MochiTheme.pastelColors['blue']!,
              MochiTheme.pastelColors['purple']!.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mochi Avatar with bouncing animation
              const MochiAvatar(
                expression: 'happy',
                size: 140,
                isAnimated: true,
              ).animate()
               .scale(
                 duration: const Duration(milliseconds: 800),
                 curve: Curves.elasticOut,
               )
               .then()
               .shimmer(
                 duration: const Duration(seconds: 2),
                 color: Colors.white.withValues(alpha: 0.5),
               ),
              
              const SizedBox(height: 40),
              
              // App Title
              Text(
                'Dasai Mochi',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 42,
                ),
              ).animate()
               .fadeIn(delay: const Duration(milliseconds: 500))
               .slideY(
                 begin: 0.3,
                 duration: const Duration(milliseconds: 800),
                 curve: Curves.easeOut,
               ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Smart Cute Assistant 🤖💕',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ).animate()
               .fadeIn(delay: const Duration(milliseconds: 800))
               .slideY(
                 begin: 0.3,
                 duration: const Duration(milliseconds: 800),
                 curve: Curves.easeOut,
               ),
              
              const SizedBox(height: 60),
              
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ).animate()
               .fadeIn(delay: const Duration(milliseconds: 1200))
               .scale(
                 duration: const Duration(milliseconds: 600),
                 curve: Curves.elasticOut,
               ),
              
              const SizedBox(height: 20),
              
              // Loading text
              Text(
                'Loading your cute assistant...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ).animate()
               .fadeIn(delay: const Duration(milliseconds: 1500))
               .then()
               .shimmer(
                 duration: const Duration(seconds: 2),
                 color: Colors.white.withValues(alpha: 0.5),
               ),
            ],
          ),
        ),
      ),
    );
  }
}
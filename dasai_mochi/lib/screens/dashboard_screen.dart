import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import '../services/ble_service.dart';
import '../services/voice_service.dart';
import '../utils/theme.dart';
import '../components/mochi_widgets.dart';
import 'reminder_screen.dart';
import 'chat_screen.dart';
import 'music_screen_simple.dart';
import 'weather_screen.dart';
import 'battery_status_screen.dart';
import 'device_settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _breathController;
  late PageController _pageController;
  
  int _currentPageIndex = 0;
  String _currentTime = '';
  String _currentDate = '';
  String _weatherInfo = '🌤️ 24°C';
  String _batteryLevel = '85%';
  String _mochiMood = 'happy';
  bool _isListening = false;
  
  final List<String> _quickCommands = [
    '🔔 Set Reminder',
    '💬 Chat with Mochi',
    '🎵 Play Music',
    '🌡️ Check Weather',
    '🔋 Battery Status',
    '📱 Device Settings'
  ];

  final List<String> _mochiQuotes = [
    "Ready to make your day amazing! 🌟",
    "Let's get things done together! 💪",
    "I'm here whenever you need me! 🤗",
    "Today is full of possibilities! ✨",
    "You've got this, and I've got you! 💕"
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateTime();
    _startTimeUpdater();
    _initializeServices();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _breathController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pageController = PageController();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm').format(now);
      _currentDate = DateFormat('EEEE, MMMM d').format(now);
    });
  }

  void _startTimeUpdater() {
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        _updateTime();
        _startTimeUpdater();
      }
    });
  }

  void _initializeServices() async {
    final bleService = Provider.of<BLEService>(context, listen: false);
    
    // Voice service initializes automatically
    
    // Start scanning for BLE devices
    await bleService.startScan();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _breathController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MochiTheme.pastelColors['babyBlue']!.withOpacity(0.3),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildMainContent(),
            _buildVoiceInterface(),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText(
                    _currentTime,
                    textStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                totalRepeatCount: 1,
              ),
              Text(
                _currentDate,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Consumer<BLEService>(
            builder: (context, bleService, child) {
              return _buildConnectionStatus(bleService.isConnected);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(bool isConnected) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isConnected 
                ? MochiTheme.pastelColors['mintGreen']!.withOpacity(0.8)
                : MochiTheme.pastelColors['softPink']!.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isConnected 
                    ? MochiTheme.pastelColors['mintGreen']! 
                    : MochiTheme.pastelColors['softPink']!)
                    .withOpacity(0.3 + (_pulseController.value * 0.3)),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? 'Connected' : 'Searching...',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Expanded(
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        children: [
          _buildDashboardPage(),
          _buildQuickActionsPage(),
          _buildStatusPage(),
        ],
      ),
    );
  }

  Widget _buildDashboardPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildMochiAvatar(),
          const SizedBox(height: 30),
          _buildWeatherCard(),
          const SizedBox(height: 20),
          _buildQuickStatsRow(),
          const SizedBox(height: 20),
          _buildRecentReminders(),
        ],
      ),
    );
  }

  Widget _buildMochiAvatar() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 10 * _floatController.value),
          child: AnimatedBuilder(
            animation: _breathController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (0.1 * _breathController.value),
                child: GestureDetector(
                  onTap: _onMochiTap,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          MochiTheme.pastelColors['lemonYellow']!,
                          MochiTheme.pastelColors['peachOrange']!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MochiTheme.pastelColors['peachOrange']!.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        MochiTheme.mochiExpressions[_mochiMood] ?? '😊',
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                ).animate()
                  .shimmer(delay: const Duration(seconds: 2), duration: const Duration(seconds: 2))
                  .then()
                  .shake(hz: 2, curve: Curves.easeInOut),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWeatherCard() {
    return MochiCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: MochiTheme.pastelColors['babyBlue']!.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text('🌤️', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weather Today',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _weatherInfo,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          MochiButton(
            text: '',
            icon: Icons.refresh,
            onPressed: _refreshWeather,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: '🔋',
            title: 'Battery',
            value: _batteryLevel,
            color: MochiTheme.pastelColors['mintGreen']!,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: '📱',
            title: 'Connection',
            value: 'Strong',
            color: MochiTheme.pastelColors['lavender']!,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return MochiCard(
      backgroundColor: color.withOpacity(0.2),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReminders() {
    return MochiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Reminders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              MochiButton(
                text: 'See All',
                onPressed: _openReminders,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildReminderItem('💊', 'Take vitamins', '9:00 AM'),
          _buildReminderItem('💻', 'Team meeting', '2:00 PM'),
          _buildReminderItem('🎵', 'Music practice', '6:30 PM'),
        ],
      ),
    );
  }

  Widget _buildReminderItem(String icon, String title, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MochiTheme.pastelColors['softPink']!.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.black.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _quickCommands.length,
              itemBuilder: (context, index) {
                return _buildQuickActionCard(_quickCommands[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String command, int index) {
    final colors = [
      MochiTheme.pastelColors['softPink']!,
      MochiTheme.pastelColors['mintGreen']!,
      MochiTheme.pastelColors['lavender']!,
      MochiTheme.pastelColors['peachOrange']!,
      MochiTheme.pastelColors['lemonYellow']!,
      MochiTheme.pastelColors['babyBlue']!,
    ];

    return GestureDetector(
      onTap: () => _executeQuickAction(index),
      child: MochiCard(
        backgroundColor: colors[index % colors.length].withOpacity(0.3),
        child: Center(
          child: Text(
            command,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ).animate()
        .scale(delay: Duration(milliseconds: index * 100))
        .fadeIn(),
    );
  }

  Widget _buildStatusPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Status',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Consumer<BLEService>(
            builder: (context, bleService, child) {
              return _buildDeviceStatusCard(bleService);
            },
          ),
          const SizedBox(height: 20),
          Consumer<VoiceService>(
            builder: (context, voiceService, child) {
              return _buildVoiceStatusCard(voiceService);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusCard(BLEService bleService) {
    return MochiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                bleService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                color: bleService.isConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                'Mochi Device ${bleService.isConnected ? "Connected" : "Disconnected"}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (bleService.mochiDevice != null) ...[
            _buildStatusRow('Device Name', bleService.mochiDevice!.name),
            _buildStatusRow('Battery Level', bleService.mochiDevice!.batteryLevel.toString() + '%'),
            _buildStatusRow('Signal Strength', '-60 dBm'), // Placeholder since signalStrength doesn't exist
          ] else
            const Text('No device information available'),
        ],
      ),
    );
  }

  Widget _buildVoiceStatusCard(VoiceService voiceService) {
    return MochiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                voiceService.isInitialized ? Icons.mic : Icons.mic_off,
                color: voiceService.isInitialized ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                'Voice Service ${voiceService.isInitialized ? "Available" : "Unavailable"}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusRow('Language', 'English'),
          _buildStatusRow('Voice Profile', voiceService.selectedVoice),
          _buildStatusRow('Last Command', voiceService.recognizedText.isNotEmpty ? voiceService.recognizedText : 'None'),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceInterface() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Voice command button
          Consumer<VoiceService>(
            builder: (context, voiceService, child) {
              return GestureDetector(
                onTap: _isListening ? _stopListening : _startListening,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isListening
                              ? [Colors.red.shade300, Colors.red.shade500]
                              : [MochiTheme.pastelColors['softPink']!, MochiTheme.pastelColors['lavender']!],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? Colors.red : MochiTheme.pastelColors['softPink']!)
                                .withOpacity(0.3 + (_isListening ? _pulseController.value * 0.3 : 0)),
                            blurRadius: 20,
                            spreadRadius: _isListening ? 10 : 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 32,
                      ),
                    );
                  },
                ),
              );
            },
          ),
          
          // Mochi quote bubble
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedTextKit(
                key: ValueKey(_mochiQuotes.hashCode),
                animatedTexts: _mochiQuotes.map((quote) => 
                  FadeAnimatedText(
                    quote,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    duration: const Duration(seconds: 4),
                  )
                ).toList(),
                repeatForever: true,
                pause: const Duration(seconds: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPageIndex == index ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPageIndex == index
                    ? MochiTheme.pastelColors['lavender']
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ).animate()
              .scale(duration: const Duration(milliseconds: 200)),
          );
        }),
      ),
    );
  }

  // Event handlers
  void _onMochiTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _mochiMood = _mochiMood == 'happy' ? 'excited' : 'happy';
    });
  }

  void _refreshWeather() async {
    HapticFeedback.lightImpact();
    // Simulate weather refresh
    setState(() {
      _weatherInfo = '🌈 26°C - Perfect!';
    });
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _weatherInfo = '🌤️ 24°C';
        });
      }
    });
  }

  void _openReminders() {
    HapticFeedback.lightImpact();
    // TODO: Navigate to reminders screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening reminders...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _executeQuickAction(int index) {
    HapticFeedback.lightImpact();
    
    switch (index) {
      case 0: // Set Reminder
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReminderScreen()),
        );
        break;
      case 1: // Chat with Mochi
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
        break;
      case 2: // Play Music
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MusicScreen()),
        );
        break;
      case 3: // Check Weather
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WeatherScreen()),
        );
        break;
      case 4: // Battery Status
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BatteryStatusScreen()),
        );
        break;
      case 5: // Device Settings
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DeviceSettingsScreen()),
        );
        break;
    }
  }

  void _startListening() async {
    if (!_isListening) {
      final voiceService = Provider.of<VoiceService>(context, listen: false);
      await voiceService.startListening();
      
      setState(() {
        _isListening = true;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _stopListening() async {
    if (_isListening) {
      final voiceService = Provider.of<VoiceService>(context, listen: false);
      await voiceService.stopListening();
      
      setState(() {
        _isListening = false;
      });
      HapticFeedback.lightImpact();
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import '../services/ble_service.dart';
import '../services/voice_service.dart';
import '../services/user_preferences_service.dart';
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
  late PageController _pageController;
  
  int _currentPageIndex = 0;
  String _currentTime = '';
  String _currentDate = '';
  String _weatherInfo = '🌤️ 24°C';
  String _batteryLevel = '85%';
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserPreferencesService>(
      builder: (context, userPrefs, child) {
        final themeColors = userPrefs.getThemeColors();
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(userPrefs, themeColors),
                _buildMainContent(userPrefs, themeColors),
                _buildVoiceInterface(userPrefs, themeColors),
                _buildBottomNavigation(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(UserPreferencesService userPrefs, Map<String, Color> themeColors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentTime,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _currentDate,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected ? Colors.green[200]! : Colors.red[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: isConnected ? Colors.green[600] : Colors.red[600],
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Connected' : 'Searching',
            style: TextStyle(
              color: isConnected ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(UserPreferencesService userPrefs, Map<String, Color> themeColors) {
    return Expanded(
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        children: [
          _buildDashboardPage(userPrefs, themeColors),
          _buildQuickActionsPage(userPrefs, themeColors),
          _buildStatusPage(themeColors),
        ],
      ),
    );
  }

  Widget _buildDashboardPage(UserPreferencesService userPrefs, Map<String, Color> themeColors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildSimpleWelcomeCard(userPrefs, themeColors),
          const SizedBox(height: 20),
          _buildWeatherCard(themeColors),
          const SizedBox(height: 20),
          _buildQuickStatsRow(themeColors),
          const SizedBox(height: 20),
          _buildRecentReminders(themeColors),
        ],
      ),
    );
  }

  Widget _buildSimpleWelcomeCard(UserPreferencesService userPrefs, Map<String, Color> themeColors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${userPrefs.userName}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to make today productive?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(Map<String, Color> themeColors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.wb_sunny,
            size: 24,
            color: Colors.orange[400],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weather',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _weatherInfo.replaceAll(RegExp(r'[^\w\s°C°F\-]'), ''),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: 20,
              color: Colors.grey[500],
            ),
            onPressed: _refreshWeather,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow(Map<String, Color> themeColors) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            iconData: Icons.battery_std,
            title: 'Battery',
            value: _batteryLevel,
            color: Colors.green[600]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            iconData: Icons.signal_cellular_alt,
            title: 'Signal',
            value: 'Strong',
            color: Colors.blue[600]!,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData iconData,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            iconData,
            size: 22,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReminders(Map<String, Color> themeColors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Reminders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: _openReminders,
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildReminderItem(Icons.medication_outlined, 'Take vitamins', '9:00 AM'),
          _buildReminderItem(Icons.groups_outlined, 'Team meeting', '2:00 PM'),
          _buildReminderItem(Icons.music_note_outlined, 'Music practice', '6:30 PM'),
        ],
      ),
    );
  }

  Widget _buildReminderItem(IconData iconData, String title, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            iconData,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsPage(UserPreferencesService userPrefs, Map<String, Color> themeColors) {
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
    return GestureDetector(
      onTap: () => _executeQuickAction(index),
      child: MochiCard(
        backgroundColor: _getActionCardColor(command).withOpacity(0.15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getActionCardColor(command).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getActionCardIcon(command),
                  size: 32,
                  color: _getActionCardColor(command),
                ),
                const SizedBox(height: 8),
                Text(
                  _cleanActionText(command),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getActionCardColor(command).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate()
        .scale(delay: Duration(milliseconds: index * 100))
        .fadeIn(),
    );
  }

  Color _getActionCardColor(String command) {
    String cleanCommand = command.toLowerCase();
    if (cleanCommand.contains('reminder')) {
      return Colors.red.shade600; // Health/reminder priority
    } else if (cleanCommand.contains('chat')) {
      return Colors.green.shade600; // Personal interaction
    } else if (cleanCommand.contains('music')) {
      return Colors.purple.shade600; // Entertainment
    } else if (cleanCommand.contains('weather')) {
      return Colors.blue.shade600; // Information/work-related
    } else if (cleanCommand.contains('battery')) {
      return Colors.orange.shade600; // Status/shopping category color
    } else if (cleanCommand.contains('settings')) {
      return Colors.grey.shade600; // Default/utility
    }
    return Colors.grey.shade600;
  }

  IconData _getActionCardIcon(String command) {
    String cleanCommand = command.toLowerCase();
    if (cleanCommand.contains('reminder')) {
      return Icons.notification_add;
    } else if (cleanCommand.contains('chat')) {
      return Icons.chat_bubble_outline;
    } else if (cleanCommand.contains('music')) {
      return Icons.music_note;
    } else if (cleanCommand.contains('weather')) {
      return Icons.wb_sunny;
    } else if (cleanCommand.contains('battery')) {
      return Icons.battery_std;
    } else if (cleanCommand.contains('settings')) {
      return Icons.settings;
    }
    return Icons.apps;
  }

  String _cleanActionText(String command) {
    // Remove emojis and clean up text
    return command.replaceAll(RegExp(r'[^\w\s]'), '').trim();
  }

  Widget _buildStatusPage(Map<String, Color> themeColors) {
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

  Widget _buildVoiceInterface(UserPreferencesService userPrefs, Map<String, Color> themeColors) {
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
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? Colors.red : MochiTheme.pastelColors['purple']!)
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
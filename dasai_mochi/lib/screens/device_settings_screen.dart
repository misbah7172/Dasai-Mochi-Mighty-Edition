import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/ble_service.dart';
import '../utils/theme.dart';

class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({super.key});

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _connectionAnimationController;
  
  final TextEditingController _nicknameController = TextEditingController();
  bool _autoConnect = true;
  bool _lowPowerMode = false;
  bool _notificationsEnabled = true;
  bool _voiceEnabled = true;
  String _selectedTheme = 'Cute Pink';
  double _brightness = 80;
  double _volume = 70;
  
  @override
  void initState() {
    super.initState();
    _connectionAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _connectionAnimationController.repeat();
    _loadSettings();
  }

  @override
  void dispose() {
    _connectionAnimationController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    // Load saved settings
    _nicknameController.text = 'My Mochi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: _buildAppBar(),
      body: Consumer<BLEService>(
        builder: (context, bleService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildConnectionCard(bleService),
                const SizedBox(height: 20),
                _buildDeviceInfo(bleService),
                const SizedBox(height: 20),
                _buildPersonalizationSection(),
                const SizedBox(height: 20),
                _buildBehaviorSettings(),
                const SizedBox(height: 20),
                _buildAdvancedSettings(),
                const SizedBox(height: 20),
                _buildDangerZone(),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Color(0xFF2D3748),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        '⚙️ Device Settings',
        style: TextStyle(
          color: Color(0xFF2D3748),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.save,
            color: MochiTheme.pastelColors['babyBlue']!,
          ),
          onPressed: _saveSettings,
        ),
      ],
    );
  }

  Widget _buildConnectionCard(BLEService bleService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bleService.isConnected 
                ? MochiTheme.pastelColors['mintGreen']!.withOpacity(0.8)
                : MochiTheme.pastelColors['softPink']!.withOpacity(0.8),
            bleService.isConnected 
                ? MochiTheme.pastelColors['mintGreen']!.withOpacity(0.6)
                : MochiTheme.pastelColors['softPink']!.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (bleService.isConnected 
                ? MochiTheme.pastelColors['mintGreen']!
                : MochiTheme.pastelColors['softPink']!).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  bleService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  size: 30,
                  color: bleService.isConnected 
                      ? MochiTheme.pastelColors['mintGreen']!
                      : MochiTheme.pastelColors['softPink']!,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(duration: 1.seconds),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bleService.isConnected ? 'Mochi Connected' : 'Not Connected',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      bleService.isConnected 
                          ? 'Device is ready for configuration'
                          : 'Connect to manage device settings',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!bleService.isConnected) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _connectToDevice(bleService),
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Connect to Mochi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: MochiTheme.pastelColors['softPink']!,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceInfo(BLEService bleService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Device Name', bleService.isConnected ? 'Mochi v2.1' : 'Not Available'),
          const SizedBox(height: 15),
          _buildInfoRow('Firmware Version', bleService.isConnected ? '2.1.3' : 'Unknown'),
          const SizedBox(height: 15),
          _buildInfoRow('Hardware Version', bleService.isConnected ? 'ESP32-S3' : 'Unknown'),
          const SizedBox(height: 15),
          _buildInfoRow('Serial Number', bleService.isConnected ? 'MC24-001-XYZ' : 'Unknown'),
          const SizedBox(height: 15),
          _buildInfoRow('Connection Status', bleService.isConnected ? 'Connected' : 'Disconnected'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF718096),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalizationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personalization',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          _buildNicknameField(),
          const SizedBox(height: 20),
          _buildThemeSelector(),
          const SizedBox(height: 20),
          _buildBrightnessSlider(),
          const SizedBox(height: 20),
          _buildVolumeSlider(),
        ],
      ),
    );
  }

  Widget _buildNicknameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mochi Nickname',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nicknameController,
          decoration: InputDecoration(
            hintText: 'Enter a cute nickname for Mochi',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: MochiTheme.pastelColors['babyBlue']!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: MochiTheme.pastelColors['babyBlue']!, width: 2),
            ),
            prefixIcon: Icon(
              Icons.pets,
              color: MochiTheme.pastelColors['babyBlue']!,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector() {
    final themes = ['Cute Pink', 'Ocean Blue', 'Forest Green', 'Sunset Orange', 'Lavender Purple'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mochi Theme',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: MochiTheme.pastelColors['babyBlue']!),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTheme,
              isExpanded: true,
              items: themes.map((theme) {
                return DropdownMenuItem<String>(
                  value: theme,
                  child: Text(theme),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrightnessSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Display Brightness',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.brightness_low, color: MochiTheme.pastelColors['babyBlue']!),
            Expanded(
              child: Slider(
                value: _brightness,
                min: 10,
                max: 100,
                divisions: 9,
                activeColor: MochiTheme.pastelColors['babyBlue']!,
                onChanged: (value) {
                  setState(() {
                    _brightness = value;
                  });
                },
              ),
            ),
            Icon(Icons.brightness_high, color: MochiTheme.pastelColors['babyBlue']!),
          ],
        ),
        Text(
          '${_brightness.toInt()}%',
          style: TextStyle(
            fontSize: 12,
            color: MochiTheme.pastelColors['babyBlue']!,
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sound Volume',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.volume_down, color: MochiTheme.pastelColors['babyBlue']!),
            Expanded(
              child: Slider(
                value: _volume,
                min: 0,
                max: 100,
                divisions: 10,
                activeColor: MochiTheme.pastelColors['babyBlue']!,
                onChanged: (value) {
                  setState(() {
                    _volume = value;
                  });
                },
              ),
            ),
            Icon(Icons.volume_up, color: MochiTheme.pastelColors['babyBlue']!),
          ],
        ),
        Text(
          '${_volume.toInt()}%',
          style: TextStyle(
            fontSize: 12,
            color: MochiTheme.pastelColors['babyBlue']!,
          ),
        ),
      ],
    );
  }

  Widget _buildBehaviorSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Behavior Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto Connect'),
            subtitle: const Text('Automatically connect when in range'),
            value: _autoConnect,
            onChanged: (value) {
              setState(() {
                _autoConnect = value;
              });
            },
            activeColor: MochiTheme.pastelColors['babyBlue'],
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Low Power Mode'),
            subtitle: const Text('Reduce power consumption'),
            value: _lowPowerMode,
            onChanged: (value) {
              setState(() {
                _lowPowerMode = value;
              });
            },
            activeColor: MochiTheme.pastelColors['babyBlue'],
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Notifications'),
            subtitle: const Text('Allow Mochi to send notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            activeColor: MochiTheme.pastelColors['babyBlue'],
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Voice Responses'),
            subtitle: const Text('Enable voice feedback from Mochi'),
            value: _voiceEnabled,
            onChanged: (value) {
              setState(() {
                _voiceEnabled = value;
              });
            },
            activeColor: MochiTheme.pastelColors['babyBlue'],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Advanced Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          _buildAdvancedOption(
            'Update Firmware',
            'Check for firmware updates',
            Icons.system_update,
            () => _updateFirmware(),
          ),
          const SizedBox(height: 15),
          _buildAdvancedOption(
            'Calibrate Sensors',
            'Recalibrate device sensors',
            Icons.settings_applications,
            () => _calibrateSensors(),
          ),
          const SizedBox(height: 15),
          _buildAdvancedOption(
            'Export Logs',
            'Export device logs for debugging',
            Icons.download,
            () => _exportLogs(),
          ),
          const SizedBox(height: 15),
          _buildAdvancedOption(
            'Developer Mode',
            'Enable advanced debugging features',
            Icons.developer_mode,
            () => _toggleDeveloperMode(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOption(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(
              icon,
              color: MochiTheme.pastelColors['babyBlue']!,
              size: 24,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: MochiTheme.pastelColors['babyBlue']!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MochiTheme.pastelColors['softPink']!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: MochiTheme.pastelColors['softPink']!.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: MochiTheme.pastelColors['softPink']!,
              ),
              const SizedBox(width: 10),
              const Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDangerOption(
            'Reset to Factory Settings',
            'This will erase all personalization and settings',
            () => _resetToFactory(),
          ),
          const SizedBox(height: 15),
          _buildDangerOption(
            'Forget This Device',
            'Remove Mochi from connected devices',
            () => _forgetDevice(),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerOption(String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: MochiTheme.pastelColors['softPink']!.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: MochiTheme.pastelColors['softPink']!,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF718096),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _connectToDevice(BLEService bleService) {
    bleService.startScan();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Searching for Mochi device... 🔍'),
        backgroundColor: MochiTheme.pastelColors['babyBlue'],
      ),
    );
  }

  void _saveSettings() {
    HapticFeedback.lightImpact();
    // Save settings to local storage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settings saved successfully! ✅'),
        backgroundColor: MochiTheme.pastelColors['mintGreen'],
      ),
    );
  }

  void _updateFirmware() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Firmware'),
        content: const Text('Checking for firmware updates...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _calibrateSensors() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calibrate Sensors'),
        content: const Text('This will recalibrate all device sensors. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Sensor calibration started... 🎯'),
                  backgroundColor: MochiTheme.pastelColors['babyBlue'],
                ),
              );
            },
            child: const Text('Calibrate'),
          ),
        ],
      ),
    );
  }

  void _exportLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exporting device logs... 📁'),
        backgroundColor: MochiTheme.pastelColors['babyBlue'],
      ),
    );
  }

  void _toggleDeveloperMode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer Mode'),
        content: const Text('Enable developer mode for advanced debugging features?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Developer mode enabled! 👨‍💻'),
                  backgroundColor: MochiTheme.pastelColors['lemonYellow'],
                ),
              );
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _resetToFactory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Factory Settings'),
        content: const Text('This will erase all personalization and settings. This action cannot be undone. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Factory reset initiated... ⚠️'),
                  backgroundColor: MochiTheme.pastelColors['softPink'],
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: MochiTheme.pastelColors['softPink'],
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _forgetDevice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forget Device'),
        content: const Text('Remove Mochi from connected devices? You will need to pair again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Device forgotten. Please pair again to reconnect.'),
                  backgroundColor: MochiTheme.pastelColors['softPink'],
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: MochiTheme.pastelColors['softPink'],
            ),
            child: const Text('Forget'),
          ),
        ],
      ),
    );
  }
}
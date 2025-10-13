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
  final TextEditingController _wifiSsidController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();
  
  bool _autoConnect = true;
  bool _lowPowerMode = false;
  bool _notificationsEnabled = true;
  bool _voiceEnabled = true;
  bool _isWifiConnected = false;
  bool _isConfiguringWifi = false;
  bool _showWifiPassword = false;
  
  String _selectedTheme = 'Cute Pink';
  String _wifiStatus = 'Disconnected';
  List<String> _availableNetworks = [];
  
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
    _wifiSsidController.dispose();
    _wifiPasswordController.dispose();
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
                _buildWifiConfiguration(bleService),
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
            color: MochiTheme.pastelColors['blue']!,
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
                : MochiTheme.pastelColors['purple']!.withOpacity(0.8),
            bleService.isConnected 
                ? MochiTheme.pastelColors['mintGreen']!.withOpacity(0.6)
                : MochiTheme.pastelColors['purple']!.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (bleService.isConnected 
                ? MochiTheme.pastelColors['mintGreen']!
                : MochiTheme.pastelColors['purple']!).withOpacity(0.3),
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
                      : MochiTheme.pastelColors['purple']!,
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
                foregroundColor: MochiTheme.pastelColors['purple']!,
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
              borderSide: BorderSide(color: MochiTheme.pastelColors['blue']!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: MochiTheme.pastelColors['blue']!, width: 2),
            ),
            prefixIcon: Icon(
              Icons.pets,
              color: MochiTheme.pastelColors['blue']!,
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
            border: Border.all(color: MochiTheme.pastelColors['blue']!),
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
            Icon(Icons.brightness_low, color: MochiTheme.pastelColors['blue']!),
            Expanded(
              child: Slider(
                value: _brightness,
                min: 10,
                max: 100,
                divisions: 9,
                activeColor: MochiTheme.pastelColors['blue']!,
                onChanged: (value) async {
                  setState(() {
                    _brightness = value;
                  });
                  // Send to device if connected
                  final bleService = Provider.of<BLEService>(context, listen: false);
                  if (bleService.isConnected) {
                    try {
                      await bleService.setBrightness(value.toInt());
                    } catch (e) {
                      // Silently fail - will be saved on next save
                    }
                  }
                },
              ),
            ),
            Icon(Icons.brightness_high, color: MochiTheme.pastelColors['blue']!),
          ],
        ),
        Text(
          '${_brightness.toInt()}%',
          style: TextStyle(
            fontSize: 12,
            color: MochiTheme.pastelColors['blue']!,
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
            Icon(Icons.volume_down, color: MochiTheme.pastelColors['blue']!),
            Expanded(
              child: Slider(
                value: _volume,
                min: 0,
                max: 100,
                divisions: 10,
                activeColor: MochiTheme.pastelColors['blue']!,
                onChanged: (value) async {
                  setState(() {
                    _volume = value;
                  });
                  // Send to device if connected
                  final bleService = Provider.of<BLEService>(context, listen: false);
                  if (bleService.isConnected) {
                    try {
                      await bleService.setVolume(value.toInt());
                    } catch (e) {
                      // Silently fail - will be saved on next save
                    }
                  }
                },
              ),
            ),
            Icon(Icons.volume_up, color: MochiTheme.pastelColors['blue']!),
          ],
        ),
        Text(
          '${_volume.toInt()}%',
          style: TextStyle(
            fontSize: 12,
            color: MochiTheme.pastelColors['blue']!,
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
            onChanged: (value) async {
              setState(() {
                _autoConnect = value;
              });
              // Send to device if connected
              final bleService = Provider.of<BLEService>(context, listen: false);
              if (bleService.isConnected) {
                try {
                  await bleService.setAutoConnect(value);
                } catch (e) {
                  // Silently fail - will be saved on next save
                }
              }
            },
            activeColor: MochiTheme.pastelColors['blue'],
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Low Power Mode'),
            subtitle: const Text('Reduce power consumption'),
            value: _lowPowerMode,
            onChanged: (value) async {
              setState(() {
                _lowPowerMode = value;
              });
              // Send to device if connected
              final bleService = Provider.of<BLEService>(context, listen: false);
              if (bleService.isConnected) {
                try {
                  await bleService.setLowPowerMode(value);
                } catch (e) {
                  // Silently fail - will be saved on next save
                }
              }
            },
            activeColor: MochiTheme.pastelColors['blue'],
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
            activeColor: MochiTheme.pastelColors['blue'],
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
            activeColor: MochiTheme.pastelColors['blue'],
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
              color: MochiTheme.pastelColors['blue']!,
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
              color: MochiTheme.pastelColors['blue']!,
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
        color: MochiTheme.pastelColors['purple']!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: MochiTheme.pastelColors['purple']!.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: MochiTheme.pastelColors['purple']!,
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
            color: MochiTheme.pastelColors['purple']!.withOpacity(0.3),
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
                color: MochiTheme.pastelColors['purple']!,
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

  Future<void> _connectToDevice(BLEService bleService) async {
    try {
      await bleService.startScan();
      _showInfoSnackBar('Scanning for Mochi device...');
    } catch (e) {
      _showErrorSnackBar('Failed to start scan: $e');
    }
  }

  Future<void> _saveSettings() async {
    final bleService = Provider.of<BLEService>(context, listen: false);
    
    if (!bleService.isConnected) {
      _showErrorSnackBar('Connect to Mochi to save settings');
      return;
    }

    try {
      // Save all settings to device
      await bleService.setBrightness(_brightness.toInt());
      await bleService.setVolume(_volume.toInt());
      await bleService.setAutoConnect(_autoConnect);
      await bleService.setLowPowerMode(_lowPowerMode);
      
      _showSuccessSnackBar('Settings saved to Mochi');
    } catch (e) {
      _showErrorSnackBar('Failed to save settings: $e');
    }
  }

  Future<void> _updateFirmware() async {
    final bleService = Provider.of<BLEService>(context, listen: false);
    
    if (!bleService.isConnected) {
      _showErrorSnackBar('Connect to Mochi to update firmware');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Firmware'),
        content: const Text('This will update Mochi\'s firmware. Make sure Mochi is charged and stay connected during the update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await bleService.updateFirmware();
                _showSuccessSnackBar('Firmware update started');
              } catch (e) {
                _showErrorSnackBar('Firmware update failed: $e');
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _calibrateSensors() async {
    final bleService = Provider.of<BLEService>(context, listen: false);
    
    if (!bleService.isConnected) {
      _showErrorSnackBar('Connect to Mochi to calibrate sensors');
      return;
    }

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
            onPressed: () async {
              Navigator.pop(context);
              try {
                await bleService.calibrateSensors();
                _showSuccessSnackBar('Sensor calibration started');
              } catch (e) {
                _showErrorSnackBar('Sensor calibration failed: $e');
              }
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
        backgroundColor: MochiTheme.pastelColors['blue'],
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

  Future<void> _resetToFactory() async {
    final bleService = Provider.of<BLEService>(context, listen: false);
    
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
            onPressed: () async {
              Navigator.pop(context);
              
              if (bleService.isConnected) {
                try {
                  await bleService.factoryReset();
                  _showSuccessSnackBar('Factory reset command sent to Mochi');
                } catch (e) {
                  _showErrorSnackBar('Factory reset failed: $e');
                }
              } else {
                _showErrorSnackBar('Connect to Mochi to perform factory reset');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[600],
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
                  backgroundColor: MochiTheme.pastelColors['purple'],
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: MochiTheme.pastelColors['purple'],
            ),
            child: const Text('Forget'),
          ),
        ],
      ),
    );
  }

  /// WiFi Configuration Section
  Widget _buildWifiConfiguration(BLEService bleService) {
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
          Row(
            children: [
              Icon(
                _isWifiConnected ? Icons.wifi : Icons.wifi_off,
                color: _isWifiConnected ? Colors.green : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'WiFi Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              if (bleService.isConnected)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _refreshWifiStatus(bleService),
                  tooltip: 'Refresh WiFi Status',
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (!bleService.isConnected) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[600]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Connect to Mochi via Bluetooth first to configure WiFi',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // WiFi Status Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isWifiConnected ? Colors.green[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isWifiConnected ? Colors.green[200]! : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isWifiConnected ? Icons.check_circle : Icons.error_outline,
                    color: _isWifiConnected ? Colors.green : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: $_wifiStatus',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _isWifiConnected ? Colors.green[800] : Colors.grey[700],
                          ),
                        ),
                        if (_isWifiConnected && _wifiSsidController.text.isNotEmpty)
                          Text(
                            'Network: ${_wifiSsidController.text}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // WiFi Configuration Form
            const Text(
              'Configure New Network',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            
            // SSID Input
            TextField(
              controller: _wifiSsidController,
              decoration: InputDecoration(
                labelText: 'WiFi Network Name (SSID)',
                hintText: 'Enter network name',
                prefixIcon: const Icon(Icons.wifi),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () => _scanWifiNetworks(bleService),
                  tooltip: 'Scan Networks',
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Password Input
            TextField(
              controller: _wifiPasswordController,
              obscureText: !_showWifiPassword,
              decoration: InputDecoration(
                labelText: 'WiFi Password',
                hintText: 'Enter password',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showWifiPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showWifiPassword = !_showWifiPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConfiguringWifi ? null : () => _configureWifi(bleService),
                    icon: _isConfiguringWifi 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi),
                    label: Text(_isConfiguringWifi ? 'Configuring...' : 'Connect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_isWifiConnected)
                  ElevatedButton.icon(
                    onPressed: () => _disconnectWifi(bleService),
                    icon: const Icon(Icons.wifi_off),
                    label: const Text('Disconnect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            
            if (_availableNetworks.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Available Networks',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _availableNetworks.length,
                  itemBuilder: (context, index) {
                    final network = _availableNetworks[index];
                    return ListTile(
                      leading: const Icon(Icons.wifi, size: 20),
                      title: Text(
                        network,
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        _wifiSsidController.text = network;
                      },
                      dense: true,
                    );
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// WiFi Methods
  Future<void> _refreshWifiStatus(BLEService bleService) async {
    if (!bleService.isConnected) return;
    
    try {
      final status = await bleService.getWifiStatus();
      if (status != null) {
        setState(() {
          _isWifiConnected = status['connected'] ?? false;
          _wifiStatus = status['status'] ?? 'Unknown';
          if (status['ssid'] != null) {
            _wifiSsidController.text = status['ssid'];
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to get WiFi status: $e');
    }
  }

  Future<void> _scanWifiNetworks(BLEService bleService) async {
    if (!bleService.isConnected) return;
    
    try {
      setState(() {
        _isConfiguringWifi = true;
      });
      
      final networks = await bleService.scanWifiNetworks();
      setState(() {
        _availableNetworks = networks;
        _isConfiguringWifi = false;
      });
      
      if (networks.isEmpty) {
        _showInfoSnackBar('No networks found. Make sure WiFi is enabled.');
      }
    } catch (e) {
      setState(() {
        _isConfiguringWifi = false;
      });
      _showErrorSnackBar('Failed to scan networks: $e');
    }
  }

  Future<void> _configureWifi(BLEService bleService) async {
    if (!bleService.isConnected) {
      _showErrorSnackBar('Please connect to Mochi first');
      return;
    }
    
    final ssid = _wifiSsidController.text.trim();
    final password = _wifiPasswordController.text.trim();
    
    if (ssid.isEmpty) {
      _showErrorSnackBar('Please enter WiFi network name');
      return;
    }
    
    if (password.isEmpty) {
      _showErrorSnackBar('Please enter WiFi password');
      return;
    }
    
    try {
      setState(() {
        _isConfiguringWifi = true;
      });
      
      final success = await bleService.configureWifi(ssid, password);
      
      setState(() {
        _isConfiguringWifi = false;
      });
      
      if (success) {
        _showSuccessSnackBar('WiFi configuration sent to Mochi');
        // Wait a moment then refresh status
        await Future.delayed(const Duration(seconds: 3));
        await _refreshWifiStatus(bleService);
      } else {
        _showErrorSnackBar('Failed to configure WiFi');
      }
    } catch (e) {
      setState(() {
        _isConfiguringWifi = false;
      });
      _showErrorSnackBar('WiFi configuration failed: $e');
    }
  }

  Future<void> _disconnectWifi(BLEService bleService) async {
    if (!bleService.isConnected) return;
    
    try {
      final success = await bleService.disconnectWifi();
      if (success) {
        _showSuccessSnackBar('WiFi disconnected');
        await _refreshWifiStatus(bleService);
      } else {
        _showErrorSnackBar('Failed to disconnect WiFi');
      }
    } catch (e) {
      _showErrorSnackBar('WiFi disconnect failed: $e');
    }
  }



  /// Helper Methods for SnackBars
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/ble_service.dart';
import '../utils/theme.dart';

class BatteryStatusScreen extends StatefulWidget {
  const BatteryStatusScreen({super.key});

  @override
  State<BatteryStatusScreen> createState() => _BatteryStatusScreenState();
}

class _BatteryStatusScreenState extends State<BatteryStatusScreen>
    with TickerProviderStateMixin {
  late AnimationController _batteryAnimationController;
  late AnimationController _pulseController;
  
  // Sample battery data - in real app this would come from Mochi device
  int _batteryLevel = 75;
  bool _isCharging = false;
  String _batteryHealth = 'Good';
  String _estimatedTime = '5h 30m';
  double _batteryTemperature = 32.5;
  int _chargesCycles = 127;
  
  @override
  void initState() {
    super.initState();
    _batteryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    
    if (_isCharging) {
      _pulseController.repeat(reverse: true);
    }
    
    _batteryAnimationController.forward();
  }

  @override
  void dispose() {
    _batteryAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
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
                _buildConnectionStatus(bleService.isConnected),
                const SizedBox(height: 20),
                if (bleService.isConnected) ...[
                  _buildBatteryCard(),
                  const SizedBox(height: 20),
                  _buildBatteryDetails(),
                  const SizedBox(height: 20),
                  _buildPowerManagement(),
                  const SizedBox(height: 20),
                  _buildBatteryHistory(),
                ] else
                  _buildNotConnectedMessage(),
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
        '🔋 Battery Status',
        style: TextStyle(
          color: Color(0xFF2D3748),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: MochiTheme.pastelColors['babyBlue']!,
          ),
          onPressed: _refreshBatteryData,
        ),
      ],
    );
  }

  Widget _buildConnectionStatus(bool isConnected) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isConnected 
            ? MochiTheme.pastelColors['mintGreen']!.withOpacity(0.3)
            : MochiTheme.pastelColors['softPink']!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isConnected 
              ? MochiTheme.pastelColors['mintGreen']!
              : MochiTheme.pastelColors['softPink']!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isConnected 
                  ? MochiTheme.pastelColors['mintGreen']!
                  : MochiTheme.pastelColors['softPink']!,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(duration: 1.seconds),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Mochi Connected' : 'Mochi Disconnected',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  isConnected 
                      ? 'Battery data is available'
                      : 'Connect to Mochi to view battery status',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryCard() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getBatteryColor().withOpacity(0.8),
            _getBatteryColor().withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: _getBatteryColor().withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBatteryIcon(),
          const SizedBox(height: 20),
          Text(
            '$_batteryLevel%',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(delay: 200.ms),
          Text(
            _isCharging ? 'Charging' : _getBatteryStatusText(),
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!_isCharging) ...[
            const SizedBox(height: 10),
            Text(
              'Estimated: $_estimatedTime remaining',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBatteryIcon() {
    return Container(
      width: 100,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Battery body
          Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: _batteryLevel,
                  child: AnimatedBuilder(
                    animation: _batteryAnimationController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            0.3 + (_batteryAnimationController.value * 0.7)
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 100 - _batteryLevel,
                  child: Container(),
                ),
              ],
            ),
          ),
          // Battery tip
          Positioned(
            right: -8,
            top: 18,
            child: Container(
              width: 6,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Charging indicator
          if (_isCharging)
            Center(
              child: Icon(
                Icons.bolt,
                color: Colors.white,
                size: 24,
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(duration: 500.ms, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
            ),
        ],
      ),
    );
  }

  Widget _buildBatteryDetails() {
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
            'Battery Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Health', _batteryHealth, _getHealthIcon()),
          const SizedBox(height: 15),
          _buildDetailRow('Temperature', '${_batteryTemperature.toStringAsFixed(1)}°C', Icons.thermostat),
          const SizedBox(height: 15),
          _buildDetailRow('Charge Cycles', '$_chargesCycles', Icons.refresh),
          const SizedBox(height: 15),
          _buildDetailRow('Charging Status', _isCharging ? 'Charging' : 'Not Charging', 
              _isCharging ? Icons.battery_charging_full : Icons.battery_std),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: MochiTheme.pastelColors['babyBlue']!,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
            ),
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

  Widget _buildPowerManagement() {
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
            'Power Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Power Saving Mode'),
            subtitle: const Text('Reduce performance to extend battery life'),
            value: false,
            onChanged: (value) => _togglePowerSaving(value),
            activeColor: MochiTheme.pastelColors['babyBlue'],
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Low Battery Alerts'),
            subtitle: const Text('Get notified when battery is low'),
            value: true,
            onChanged: (value) => _toggleLowBatteryAlerts(value),
            activeColor: MochiTheme.pastelColors['babyBlue'],
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Optimize Charging'),
            subtitle: const Text('Protect battery health during charging'),
            value: true,
            onChanged: (value) => _toggleOptimizeCharging(value),
            activeColor: MochiTheme.pastelColors['babyBlue'],
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryHistory() {
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
            'Battery Usage History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          _buildUsageChart(),
          const SizedBox(height: 20),
          const Text(
            'Average daily usage: 8h 15m',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageChart() {
    final List<double> usageData = [85, 72, 90, 65, 78, 82, 75]; // Last 7 days
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Container(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 20,
                height: usageData[index],
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      MochiTheme.pastelColors['babyBlue']!,
                      MochiTheme.pastelColors['lavender']!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              )
                  .animate(delay: Duration(milliseconds: index * 100))
                  .scaleY(duration: 500.ms, begin: 0, end: 1),
              const SizedBox(height: 8),
              Text(
                days[index],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildNotConnectedMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: MochiTheme.pastelColors['softPink']!.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.battery_unknown,
              size: 80,
              color: MochiTheme.pastelColors['softPink'],
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(duration: 2.seconds),
          const SizedBox(height: 30),
          const Text(
            'Mochi Not Connected',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Connect to your Mochi device to view battery status and manage power settings.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _connectToMochi,
            icon: const Icon(Icons.bluetooth),
            label: const Text('Connect to Mochi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MochiTheme.pastelColors['babyBlue'],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBatteryColor() {
    if (_batteryLevel > 60) {
      return MochiTheme.pastelColors['mintGreen']!;
    } else if (_batteryLevel > 30) {
      return MochiTheme.pastelColors['lemonYellow']!;
    } else {
      return MochiTheme.pastelColors['softPink']!;
    }
  }

  IconData _getHealthIcon() {
    switch (_batteryHealth) {
      case 'Excellent':
        return Icons.battery_full;
      case 'Good':
        return Icons.battery_std;
      case 'Fair':
        return Icons.battery_alert;
      case 'Poor':
        return Icons.battery_unknown;
      default:
        return Icons.battery_std;
    }
  }

  String _getBatteryStatusText() {
    if (_batteryLevel > 80) {
      return 'Fully Charged';
    } else if (_batteryLevel > 60) {
      return 'Good Level';
    } else if (_batteryLevel > 30) {
      return 'Medium Level';
    } else if (_batteryLevel > 15) {
      return 'Low Battery';
    } else {
      return 'Critical Level';
    }
  }

  void _refreshBatteryData() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Battery data refreshed! 🔋'),
        backgroundColor: MochiTheme.pastelColors['babyBlue'],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _connectToMochi() {
    final bleService = Provider.of<BLEService>(context, listen: false);
    bleService.startScan();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Searching for Mochi device... 🔍'),
        backgroundColor: MochiTheme.pastelColors['babyBlue'],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _togglePowerSaving(bool value) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Power saving mode ${value ? 'enabled' : 'disabled'}'),
        backgroundColor: MochiTheme.pastelColors['babyBlue'],
      ),
    );
  }

  void _toggleLowBatteryAlerts(bool value) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Low battery alerts ${value ? 'enabled' : 'disabled'}'),
        backgroundColor: MochiTheme.pastelColors['babyBlue'],
      ),
    );
  }

  void _toggleOptimizeCharging(bool value) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Optimized charging ${value ? 'enabled' : 'disabled'}'),
        backgroundColor: MochiTheme.pastelColors['babyBlue'],
      ),
    );
  }
}
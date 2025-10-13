import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/mochi_device.dart';
import '../models/esp32_protocol.dart';

class BLEService extends ChangeNotifier {
  static const String mochiServiceUUID = "12345678-1234-1234-1234-123456789abc";
  static const String mochiCharacteristicUUID = "87654321-4321-4321-4321-cba987654321";
  
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _characteristic;
  MochiDevice? _mochiDevice;
  bool _isScanning = false;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _characteristicSubscription;
  
  // Getters
  MochiDevice? get mochiDevice => _mochiDevice;
  bool get isConnected => _mochiDevice?.isConnected ?? false;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  
  // Stream controllers for real-time updates
  final _deviceDataController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<String>.broadcast();
  
  Stream<Map<String, dynamic>> get deviceDataStream => _deviceDataController.stream;
  Stream<String> get connectionStatusStream => _connectionStatusController.stream;

  BLEService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Check if Bluetooth is available
      if (await FlutterBluePlus.isAvailable == false) {
        debugPrint("BLE: Bluetooth not available on this device");
        return;
      }

      // Listen to Bluetooth state changes
      FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
        debugPrint("BLE: Adapter state changed: $state");
        if (state == BluetoothAdapterState.on) {
          _startAutoScan();
        } else {
          _stopScan();
          _disconnect();
        }
      });

      // Auto-start scanning if Bluetooth is already on
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) {
        _startAutoScan();
      }
    } catch (e) {
      debugPrint("BLE: Initialization error: $e");
    }
  }

  /// Start scanning for Mochi devices
  Future<void> startScan() async {
    if (_isScanning) return;
    
    try {
      _isScanning = true;
      _updateConnectionStatus('scanning');
      notifyListeners();

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        withServices: [Guid(mochiServiceUUID)],
      );

      // Listen for scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (_isMochiDevice(result.device)) {
            debugPrint("BLE: Found Mochi device: ${result.device.name}");
            connectToDevice(result.device);
            break;
          }
        }
      });

      // Auto-stop scanning after timeout
      Timer(const Duration(seconds: 10), () {
        if (_isScanning) {
          _stopScan();
        }
      });
    } catch (e) {
      debugPrint("BLE: Scan error: $e");
      _isScanning = false;
      _updateConnectionStatus('error');
      notifyListeners();
    }
  }

  /// Stop scanning
  void _stopScan() {
    if (!_isScanning) return;
    
    try {
      FlutterBluePlus.stopScan();
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      debugPrint("BLE: Stop scan error: $e");
    }
  }

  /// Auto-scan for devices periodically
  void _startAutoScan() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!isConnected && !_isScanning && !_isConnecting) {
        startScan();
      }
    });
  }

  /// Check if a device is a Mochi device
  bool _isMochiDevice(BluetoothDevice device) {
    final name = device.name.toLowerCase();
    return name.contains('mochi') || 
           name.contains('dasai') ||
           name.contains('esp32');
  }

  /// Connect to a specific device
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_isConnecting || isConnected) return;
    
    try {
      _isConnecting = true;
      _updateConnectionStatus('connecting');
      notifyListeners();

      // Stop scanning
      _stopScan();

      // Connect to device
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;

      // Create MochiDevice object
      _mochiDevice = MochiDevice(
        id: device.id.id,
        name: device.name.isNotEmpty ? device.name : 'Mochi Device',
        macAddress: device.id.id,
        isConnected: true,
        connectionStatus: 'connected',
        lastConnected: DateTime.now(),
      );

      // Listen to connection state changes
      _connectionSubscription = device.connectionState.listen((state) {
        debugPrint("BLE: Connection state: $state");
        if (state == BluetoothConnectionState.disconnected) {
          _onDeviceDisconnected();
        }
      });

      // Discover services and characteristics
      await _discoverServices();
      
      _isConnecting = false;
      _updateConnectionStatus('connected');
      _startHeartbeat();
      notifyListeners();
      
      debugPrint("BLE: Successfully connected to ${device.name}");
    } catch (e) {
      debugPrint("BLE: Connection error: $e");
      _isConnecting = false;
      _updateConnectionStatus('error');
      _onDeviceDisconnected();
    }
  }

  /// Discover services and characteristics
  Future<void> _discoverServices() async {
    if (_connectedDevice == null) return;

    try {
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == mochiServiceUUID.toLowerCase()) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == mochiCharacteristicUUID.toLowerCase()) {
              _characteristic = characteristic;
              
              // Enable notifications
              if (characteristic.properties.notify) {
                await characteristic.setNotifyValue(true);
                _characteristicSubscription = characteristic.value.listen(_onDataReceived);
              }
              
              debugPrint("BLE: Found Mochi characteristic");
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("BLE: Service discovery error: $e");
    }
  }

  /// Handle incoming data from ESP32
  void _onDataReceived(List<int> data) {
    try {
      String jsonString = utf8.decode(data);
      Map<String, dynamic> jsonData = json.decode(jsonString);
      
      debugPrint("BLE: Received data: $jsonString");
      
      // Update battery level if available
      if (jsonData.containsKey('battery')) {
        _mochiDevice = _mochiDevice?.copyWith(
          batteryLevel: jsonData['battery'],
        );
      }
      
      // Update last received data
      _mochiDevice = _mochiDevice?.copyWith(
        lastReceivedData: jsonData,
      );
      
      // Emit data to stream
      _deviceDataController.add(jsonData);
      notifyListeners();
    } catch (e) {
      debugPrint("BLE: Data parsing error: $e");
    }
  }

  /// Send command to ESP32
  Future<bool> sendCommand(ESP32Command command) async {
    if (_characteristic == null || !isConnected) {
      debugPrint("BLE: Cannot send command - not connected");
      return false;
    }

    try {
      String jsonString = json.encode(command.toJson());
      List<int> data = utf8.encode(jsonString);
      
      await _characteristic!.write(data, withoutResponse: false);
      debugPrint("BLE: Sent command: $jsonString");
      return true;
    } catch (e) {
      debugPrint("BLE: Send command error: $e");
      return false;
    }
  }

  /// Send heartbeat to maintain connection
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isConnected) {
        sendCommand(ESP32Commands.heartbeatCommand());
      } else {
        timer.cancel();
      }
    });
  }

  /// Handle device disconnection
  void _onDeviceDisconnected() {
    debugPrint("BLE: Device disconnected");
    
    _mochiDevice = _mochiDevice?.copyWith(
      isConnected: false,
      connectionStatus: 'disconnected',
    );
    
    _connectedDevice = null;
    _characteristic = null;
    _connectionSubscription?.cancel();
    _characteristicSubscription?.cancel();
    _heartbeatTimer?.cancel();
    
    _updateConnectionStatus('disconnected');
    notifyListeners();
    
    // Auto-reconnect after delay
    Timer(const Duration(seconds: 5), () {
      if (!isConnected) {
        _startAutoScan();
      }
    });
  }

  /// Manually disconnect
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    await _disconnect();
  }

  Future<void> _disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } catch (e) {
      debugPrint("BLE: Disconnect error: $e");
    }
    _onDeviceDisconnected();
  }

  /// Update connection status and emit to stream
  void _updateConnectionStatus(String status) {
    _connectionStatusController.add(status);
  }

  /// Quick methods for common commands
  Future<bool> showTimeOnMochi() async {
    return await sendCommand(ESP32Commands.showTimeCommand());
  }

  Future<bool> showReminderOnMochi(String reminderText) async {
    return await sendCommand(ESP32Commands.showReminderCommand(reminderText));
  }

  Future<bool> updateMochiFace(String expression) async {
    return await sendCommand(ESP32Commands.updateFaceCommand(expression));
  }

  Future<bool> setMochiMood(String mood) async {
    return await sendCommand(ESP32Commands.showMoodCommand(mood));
  }

  Future<bool> displayTextOnMochi(String text) async {
    return await sendCommand(ESP32Commands.displayTextCommand(text));
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _connectionSubscription?.cancel();
    _characteristicSubscription?.cancel();
    _deviceDataController.close();
    _connectionStatusController.close();
    _disconnect();
    super.dispose();
  }
}
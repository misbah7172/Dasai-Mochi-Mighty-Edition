class MochiDevice {
  final String id;
  final String name;
  final String macAddress;
  bool isConnected;
  int batteryLevel;
  DateTime? lastConnected;
  String connectionStatus; // connected, disconnected, connecting, error
  Map<String, dynamic>? lastReceivedData;

  MochiDevice({
    required this.id,
    required this.name,
    required this.macAddress,
    this.isConnected = false,
    this.batteryLevel = 0,
    this.lastConnected,
    this.connectionStatus = 'disconnected',
    this.lastReceivedData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'macAddress': macAddress,
      'isConnected': isConnected,
      'batteryLevel': batteryLevel,
      'lastConnected': lastConnected?.toIso8601String(),
      'connectionStatus': connectionStatus,
      'lastReceivedData': lastReceivedData,
    };
  }

  factory MochiDevice.fromJson(Map<String, dynamic> json) {
    return MochiDevice(
      id: json['id'],
      name: json['name'],
      macAddress: json['macAddress'],
      isConnected: json['isConnected'] ?? false,
      batteryLevel: json['batteryLevel'] ?? 0,
      lastConnected: json['lastConnected'] != null 
          ? DateTime.parse(json['lastConnected']) 
          : null,
      connectionStatus: json['connectionStatus'] ?? 'disconnected',
      lastReceivedData: json['lastReceivedData'],
    );
  }

  MochiDevice copyWith({
    String? id,
    String? name,
    String? macAddress,
    bool? isConnected,
    int? batteryLevel,
    DateTime? lastConnected,
    String? connectionStatus,
    Map<String, dynamic>? lastReceivedData,
  }) {
    return MochiDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      macAddress: macAddress ?? this.macAddress,
      isConnected: isConnected ?? this.isConnected,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastConnected: lastConnected ?? this.lastConnected,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      lastReceivedData: lastReceivedData ?? this.lastReceivedData,
    );
  }
}
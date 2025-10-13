/// ESP32 Communication Protocol for Mochi Device
class ESP32Command {
  final String cmd;
  final String? data;
  final DateTime timestamp;

  ESP32Command({
    required this.cmd,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'cmd': cmd,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ESP32Command.fromJson(Map<String, dynamic> json) {
    return ESP32Command(
      cmd: json['cmd'],
      data: json['data'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }
}

class ESP32Response {
  final String status;
  final String action;
  final String? value;
  final String? error;
  final DateTime timestamp;

  ESP32Response({
    required this.status,
    required this.action,
    this.value,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'action': action,
      'value': value,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ESP32Response.fromJson(Map<String, dynamic> json) {
    return ESP32Response(
      status: json['status'] ?? 'error',
      action: json['action'] ?? 'unknown',
      value: json['value'],
      error: json['error'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  bool get isSuccess => status.toLowerCase() == 'ok';
  bool get isError => status.toLowerCase() == 'error';
}

/// Pre-defined ESP32 Commands
class ESP32Commands {
  static const String showTime = 'show_time';
  static const String showReminder = 'show_reminder';
  static const String showMood = 'show_mood';
  static const String updateFace = 'update_face';
  static const String getBattery = 'get_battery';
  static const String setAlarm = 'set_alarm';
  static const String playSound = 'play_sound';
  static const String displayText = 'display_text';
  static const String heartbeat = 'heartbeat';
  static const String getStatus = 'get_status';
  static const String syncUserData = 'sync_user_data';
  static const String updatePersonality = 'update_personality';
  
  /// Create a command to show time on Mochi
  static ESP32Command showTimeCommand() {
    return ESP32Command(cmd: showTime);
  }
  
  /// Create a command to show reminder
  static ESP32Command showReminderCommand(String reminderText) {
    return ESP32Command(cmd: showReminder, data: reminderText);
  }
  
  /// Create a command to update Mochi's face expression
  static ESP32Command updateFaceCommand(String expression) {
    return ESP32Command(cmd: updateFace, data: expression);
  }
  
  /// Create a command to set mood
  static ESP32Command showMoodCommand(String mood) {
    return ESP32Command(cmd: showMood, data: mood);
  }
  
  /// Create a command to display custom text
  static ESP32Command displayTextCommand(String text) {
    return ESP32Command(cmd: displayText, data: text);
  }
  
  /// Create a heartbeat command for connection testing
  static ESP32Command heartbeatCommand() {
    return ESP32Command(cmd: heartbeat);
  }
  
  /// Create a command to get device status
  static ESP32Command getStatusCommand() {
    return ESP32Command(cmd: getStatus);
  }
  
  /// Create a command to sync user data with ESP32
  static ESP32Command syncUserDataCommand(String userData) {
    return ESP32Command(cmd: syncUserData, data: userData);
  }
  
  /// Create a command to update Mochi's personality
  static ESP32Command updatePersonalityCommand(String personality) {
    return ESP32Command(cmd: updatePersonality, data: personality);
  }
}
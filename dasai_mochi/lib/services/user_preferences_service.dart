import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/esp32_protocol.dart';
import '../services/local_storage_service.dart';
import '../services/ble_service.dart';
import '../utils/theme.dart';
import 'dart:convert';

class UserPreferencesService extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  final BLEService _bleService;
  late SharedPreferences _prefs;
  
  // User data and preferences
  User? _currentUser;
  String _currentTheme = 'default';
  bool _animationsEnabled = true;
  bool _soundEffectsEnabled = true;
  bool _notificationsEnabled = true;
  bool _voiceCommandsEnabled = true;
  bool _locationEnabled = false;
  String _favoriteColor = 'pink';
  List<String> _interests = [];
  String _mochiPersonality = 'friendly'; // Based on user preferences
  
  UserPreferencesService(this._localStorageService, this._bleService) {
    _initialize();
  }
  
  // Getters
  User? get currentUser => _currentUser;
  String get currentTheme => _currentTheme;
  bool get animationsEnabled => _animationsEnabled;
  bool get soundEffectsEnabled => _soundEffectsEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get voiceCommandsEnabled => _voiceCommandsEnabled;
  bool get locationEnabled => _locationEnabled;
  String get favoriteColor => _favoriteColor;
  List<String> get interests => _interests;
  String get mochiPersonality => _mochiPersonality;
  
  // Personalized getters
  String get personalizedGreeting => _getPersonalizedGreeting();
  String get userName => _currentUser?.nickname ?? 'Friend';
  String get userFullName => _currentUser?.fullName ?? 'New User';
  int get userAge => _getUserAge();
  String get preferredVoice => _currentUser?.selectedVoice ?? 'default';
  
  Future<void> _initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadUserData();
      await _loadPreferences();
      _determinePersonality();
      notifyListeners();
    } catch (e) {
      debugPrint("UserPreferences: Initialization error: $e");
    }
  }
  
  /// Load user data from local storage
  Future<void> _loadUserData() async {
    try {
      _currentUser = _localStorageService.currentUser;
      if (_currentUser != null) {
        _currentTheme = _currentUser!.selectedTheme;
        _animationsEnabled = _currentUser!.animationsEnabled;
        _soundEffectsEnabled = _currentUser!.soundEffectsEnabled;
      }
    } catch (e) {
      debugPrint("UserPreferences: Load user data error: $e");
    }
  }
  
  /// Load additional preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      _favoriteColor = _prefs.getString('favorite_color') ?? 'pink';
      _notificationsEnabled = _prefs.getBool('notifications_enabled') ?? true;
      _voiceCommandsEnabled = _prefs.getBool('voice_commands_enabled') ?? true;
      _locationEnabled = _prefs.getBool('location_enabled') ?? false;
      
      final interestsJson = _prefs.getString('interests');
      if (interestsJson != null) {
        _interests = List<String>.from(json.decode(interestsJson));
      }
    } catch (e) {
      debugPrint("UserPreferences: Load preferences error: $e");
    }
  }
  
  /// Determine Mochi personality based on user data
  void _determinePersonality() {
    if (_currentUser == null) {
      _mochiPersonality = 'friendly';
      return;
    }
    
    final age = userAge;
    final hasActiveInterests = _interests.isNotEmpty;
    
    if (age < 13) {
      _mochiPersonality = 'playful'; // Kid-friendly
    } else if (age < 20) {
      _mochiPersonality = 'energetic'; // Teen-friendly
    } else if (age < 60) {
      _mochiPersonality = hasActiveInterests ? 'enthusiastic' : 'supportive';
    } else {
      _mochiPersonality = 'gentle'; // Senior-friendly
    }
  }
  
  /// Get personalized greeting based on time and user data
  String _getPersonalizedGreeting() {
    final hour = DateTime.now().hour;
    final name = userName;
    
    if (hour < 6) {
      return "Good night, $name! 🌙";
    } else if (hour < 12) {
      return "Good morning, $name! ☀️";
    } else if (hour < 17) {
      return "Good afternoon, $name! 🌤️";
    } else if (hour < 22) {
      return "Good evening, $name! 🌅";
    } else {
      return "Hey there, $name! ⭐";
    }
  }
  
  /// Calculate user age from date of birth
  int _getUserAge() {
    if (_currentUser?.dateOfBirth == null) return 25; // Default
    
    final now = DateTime.now();
    final birthDate = _currentUser!.dateOfBirth;
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }
  
  /// Save user preferences and sync with devices
  Future<void> saveUserData({
    String? fullName,
    String? nickname,
    DateTime? dateOfBirth,
    String? favoriteColor,
    List<String>? interests,
    String? selectedTheme,
    String? selectedVoice,
    bool? animationsEnabled,
    bool? soundEffectsEnabled,
    bool? notificationsEnabled,
    bool? voiceCommandsEnabled,
    bool? locationEnabled,
  }) async {
    try {
      // Update user object if provided
      if (_currentUser != null && 
          (fullName != null || nickname != null || dateOfBirth != null || 
           selectedTheme != null || selectedVoice != null || 
           animationsEnabled != null || soundEffectsEnabled != null)) {
        
        final updatedUser = User(
          fullName: fullName ?? _currentUser!.fullName,
          nickname: nickname ?? _currentUser!.nickname,
          dateOfBirth: dateOfBirth ?? _currentUser!.dateOfBirth,
          profileImage: _currentUser!.profileImage,
          preferredLanguage: _currentUser!.preferredLanguage,
          soundEffectsEnabled: soundEffectsEnabled ?? _currentUser!.soundEffectsEnabled,
          animationsEnabled: animationsEnabled ?? _currentUser!.animationsEnabled,
          selectedTheme: selectedTheme ?? _currentUser!.selectedTheme,
          selectedVoice: selectedVoice ?? _currentUser!.selectedVoice,
          festivalModeEnabled: _currentUser!.festivalModeEnabled,
          petModeEnabled: _currentUser!.petModeEnabled,
        );
        
        await _localStorageService.saveUser(updatedUser);
        _currentUser = updatedUser;
      }
      
      // Update local preferences
      if (favoriteColor != null) {
        _favoriteColor = favoriteColor;
        await _prefs.setString('favorite_color', favoriteColor);
      }
      
      if (interests != null) {
        _interests = interests;
        await _prefs.setString('interests', json.encode(interests));
      }
      
      if (notificationsEnabled != null) {
        _notificationsEnabled = notificationsEnabled;
        await _prefs.setBool('notifications_enabled', notificationsEnabled);
      }
      
      if (voiceCommandsEnabled != null) {
        _voiceCommandsEnabled = voiceCommandsEnabled;
        await _prefs.setBool('voice_commands_enabled', voiceCommandsEnabled);
      }
      
      if (locationEnabled != null) {
        _locationEnabled = locationEnabled;
        await _prefs.setBool('location_enabled', locationEnabled);
      }
      
      // Update class properties
      _currentTheme = selectedTheme ?? _currentTheme;
      _animationsEnabled = animationsEnabled ?? _animationsEnabled;
      _soundEffectsEnabled = soundEffectsEnabled ?? _soundEffectsEnabled;
      
      _determinePersonality();
      
      // Sync with ESP32
      await _syncWithESP32();
      
      notifyListeners();
      
    } catch (e) {
      debugPrint("UserPreferences: Save user data error: $e");
    }
  }
  
  /// Sync user preferences with ESP32 device
  Future<void> _syncWithESP32() async {
    if (!_bleService.isConnected) return;
    
    try {
      final userData = {
        'type': 'user_preferences',
        'user_name': userName,
        'age': userAge,
        'personality': _mochiPersonality,
        'favorite_color': _favoriteColor,
        'theme': _currentTheme,
        'voice': preferredVoice,
        'animations': _animationsEnabled,
        'sound_effects': _soundEffectsEnabled,
        'notifications': _notificationsEnabled,
        'voice_commands': _voiceCommandsEnabled,
        'interests': _interests,
        'greeting': personalizedGreeting,
      };
      
      final command = ESP32Commands.syncUserDataCommand(json.encode(userData));
      await _bleService.sendCommand(command);
      debugPrint("UserPreferences: User data synced with ESP32");
      
    } catch (e) {
      debugPrint("UserPreferences: ESP32 sync error: $e");
    }
  }
  
  /// Get theme colors based on user preference
  Map<String, Color> getThemeColors() {
    final baseTheme = MochiTheme.getThemeColors(_currentTheme);
    
    // Customize based on favorite color
    Color accentColor;
    switch (_favoriteColor.toLowerCase()) {
      case 'pink':
        accentColor = Colors.pink.shade400;
        break;
      case 'purple':
        accentColor = Colors.purple.shade400;
        break;
      case 'blue':
        accentColor = Colors.blue.shade400;
        break;
      case 'green':
        accentColor = Colors.green.shade400;
        break;
      case 'yellow':
        accentColor = Colors.amber.shade400;
        break;
      case 'orange':
        accentColor = Colors.orange.shade400;
        break;
      default:
        accentColor = baseTheme['accent']!;
    }
    
    return {
      ...baseTheme,
      'accent': accentColor,
      'userColor': accentColor,
    };
  }
  
  /// Get personalized Mochi expressions based on personality
  List<String> getMochiExpressions() {
    switch (_mochiPersonality) {
      case 'playful':
        return ['😄', '🤪', '😆', '😊', '🎉'];
      case 'energetic':
        return ['😎', '🤘', '💪', '🔥', '⚡'];
      case 'enthusiastic':
        return ['😍', '🤩', '🌟', '💫', '✨'];
      case 'supportive':
        return ['😊', '🤗', '💕', '🌸', '☺️'];
      case 'gentle':
        return ['😌', '😇', '🙂', '💖', '🌺'];
      default:
        return ['😊', '😄', '🤗', '💕', '🌟'];
    }
  }
  
  /// Get age-appropriate content recommendations
  List<String> getContentRecommendations() {
    final age = userAge;
    List<String> recommendations = [];
    
    if (age < 13) {
      recommendations.addAll(['Games', 'Learning', 'Stories', 'Music']);
    } else if (age < 20) {
      recommendations.addAll(['Music', 'Gaming', 'Social', 'Learning']);
    } else if (age < 60) {
      recommendations.addAll(['Productivity', 'Health', 'Entertainment', 'Communication']);
    } else {
      recommendations.addAll(['Health', 'Family', 'Relaxation', 'Memory']);
    }
    
    // Add user interests
    recommendations.addAll(_interests);
    
    return recommendations.toSet().toList(); // Remove duplicates
  }
  
  /// Reset all preferences
  Future<void> resetPreferences() async {
    try {
      await _prefs.clear();
      _currentTheme = 'default';
      _animationsEnabled = true;
      _soundEffectsEnabled = true;
      _notificationsEnabled = true;
      _voiceCommandsEnabled = true;
      _locationEnabled = false;
      _favoriteColor = 'pink';
      _interests.clear();
      _mochiPersonality = 'friendly';
      
      await _syncWithESP32();
      notifyListeners();
    } catch (e) {
      debugPrint("UserPreferences: Reset error: $e");
    }
  }
  
  /// Force sync with ESP32
  Future<void> forceSyncWithESP32() async {
    await _syncWithESP32();
  }
}